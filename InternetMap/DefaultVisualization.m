//
//  DefaultVisualization.m
//  InternetMap
//

#import "DefaultVisualization.h"
#import "MapDisplay.h"
#import "Node.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation DefaultVisualization

-(GLKVector3)nodePosition:(Node*)node {
    return GLKVector3Make(log10f(node.importance) + 2.0f, node.positionX, node.positionY);
}

-(float)nodeSize:(Node*)node {
    float size = 2.0 + 400*powf(node.importance, .75);
//        float size = 2.0 + 100*sqrtf(obj.importance);
//        float size = 2.0 + 1000*obj.importance;
    return ([[UIScreen mainScreen] scale] == 2.00) ? 2.0*size : size;

}

-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)nodes {
    //    UIColor* nodeColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    
    //    UIColor* t1Color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    //    UIColor* t2Color = [UIColor colorWithRed:1.0 green:0.7 blue:1.0 alpha:1.0];
    //    UIColor* compColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
    //    UIColor* eduColor = [UIColor colorWithRed:1.0 green:0.7 blue:0.7 alpha:1.0];
    //    UIColor* ixColor = [UIColor colorWithRed:0.7 green:1.0 blue:0.7 alpha:1.0];
    //    UIColor* nicColor = [UIColor colorWithRed:0.7 green:0.7 blue:1.0 alpha:1.0];
    //    UIColor* unknownColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    
    UIColor* t1Color = UIColorFromRGB(0x36a3e6);
    UIColor* t2Color = UIColorFromRGB(0x2246a7);
    UIColor* unknownColor = UIColorFromRGB(0x8e44bd);
    UIColor* compColor = UIColorFromRGB(0x4490ce);
    UIColor* eduColor = UIColorFromRGB(0xecb7fd);
    UIColor* ixColor = UIColorFromRGB(0xb7fddc);
    UIColor* nicColor = UIColorFromRGB(0xb0a2d3);
    
    for(Node* node in nodes) {
        DisplayNode* point = [display displayNodeAtIndex:node.index]; // use index from node, not in array, so that partiual updates can work
        
        GLKVector3 position = [self nodePosition:node];
        point.x = position.x;
        point.y = position.y;
        point.z = position.z;

        point.size = [self nodeSize:node];
        
        switch(node.type) {
            case AS_T1:
                point.color = t1Color;
                break;
            case AS_T2:
                point.color = t2Color;
                break;
            case AS_COMP:
                point.color = compColor;
                break;
            case AS_EDU:
                point.color = eduColor;
                break;
            case AS_IX:
                point.color = ixColor;
                break;
            case AS_NIC:
                point.color = nicColor;
                break;
            default:
                point.color = unknownColor;
                break;
        }
        
        float lineImportance = MAX(node.importance - 0.01f, 0.0f) * 0.5f;
        UIColor* lineColor = [UIColor colorWithRed:lineImportance green:lineImportance blue:lineImportance alpha:1.0];
        point.lineColor = lineColor;
    };

}

@end
