//
//  DefaultVisualization.m
//  InternetMap
//

#import "DefaultVisualization.h"
#import "MapDisplay.h"
#import "Node.h"
#import "Lines.h"
#import "Connection.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation DefaultVisualization

-(GLKVector3)nodePosition:(Node*)node {
    return GLKVector3Make(log10f(node.importance) + 2.0f, node.positionX, node.positionY);
}

-(float)nodeSize:(Node*)node {
    return 0.005 + 0.70*powf(node.importance, .75);

}

-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)nodes {

    
//    UIColor* t1Color = UIColorFromRGB(0x36a3e6);
//    UIColor* t2Color = UIColorFromRGB(0x2246a7);
//    UIColor* unknownColor = UIColorFromRGB(0x8e44bd);
//    UIColor* compColor = UIColorFromRGB(0x4490ce);
//    UIColor* eduColor = UIColorFromRGB(0xecb7fd);
//    UIColor* ixColor = UIColorFromRGB(0xb7fddc);
//    UIColor* nicColor = UIColorFromRGB(0xb0a2d3);
    
    UIColor* t1Color = UIColorFromRGB(0x548dff); // Changed to blue in style guide
    UIColor* t2Color = UIColorFromRGB(0x375ca6); // Slightly darker blue than in style guide
    UIColor* unknownColor = UIColorFromRGB(0x7ce346); // slightly brighter green than style guide
    UIColor* compColor = UIColorFromRGB(0x4490ce); //some other blue
    UIColor* eduColor = UIColorFromRGB(0x7200ff); //purpley
    UIColor* ixColor = UIColorFromRGB(0x75787b); //slate 
    UIColor* nicColor = UIColorFromRGB(0xffffff); //white, obvs



    
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
    };

}

-(void)updateLineDisplay:(MapDisplay*)display forConnections:(NSArray*)connections {
    NSMutableArray* filteredConnections = [NSMutableArray new];
    
    // We are only drawing lines to nodes with > 0.01 importance, filter those out
    for(Connection* connection in connections) {
        if((connection.first.importance > 0.01) && (connection.second.importance > 0.01)) {
            [filteredConnections addObject:connection];
        }
    }
    
    Lines* lines = [[Lines alloc] initWithLineCount:filteredConnections.count];
    
    [lines beginUpdate];
    
    int currentIndex = 0;
    for(Connection* connection in filteredConnections) {
        Node* a = connection.first;
        Node* b = connection.second;
        
        float lineImportanceA = MAX(a.importance - 0.01f, 0.0f) * 0.5f;
        UIColor* lineColorA = [UIColor colorWithRed:lineImportanceA green:lineImportanceA blue:lineImportanceA alpha:1.0];
        
        float lineImportanceB = MAX(b.importance - 0.01f, 0.0f) * 0.5f;
        UIColor* lineColorB = [UIColor colorWithRed:lineImportanceB green:lineImportanceB blue:lineImportanceB alpha:1.0];
        
        [lines updateLine:currentIndex withStart:[self nodePosition:a] startColor:lineColorA end:[self nodePosition:b] endColor:lineColorB];
        currentIndex++;
    }
    [lines endUpdate];
    
    display.visualizationLines = lines;
}

@end
