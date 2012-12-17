//
//  DefaultVisualization.m
//  InternetMap
//

#import "DefaultVisualization.h"
#import "MapDisplay.h"
#import "Node.h"
#import "Lines.h"
#import "Connection.h"
#import "Nodes.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation DefaultVisualization

-(GLKVector3)nodePosition:(Node*)node {
    return GLKVector3Make(log10f(node.importance) + 2.0f, node.positionX, node.positionY);
}

-(float)nodeSize:(Node*)node {
    return 0.005 + 0.70*powf(node.importance, .75);

}

-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)arrNodes {    
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
    
    [display.nodes beginUpdate];
    
    for(int i = 0; i < arrNodes.count; i++) {
        Node* node = arrNodes[i];
        
        UIColor* color;
        switch(node.type) {
            case AS_T1:
                color = t1Color;
                break;
            case AS_T2:
                color = t2Color;
                break;
            case AS_COMP:
                color = compColor;
                break;
            case AS_EDU:
                color = eduColor;
                break;
            case AS_IX:
                color = ixColor;
                break;
            case AS_NIC:
                color = nicColor;
                break;
            default:
                color = unknownColor;
                break;
        }
        
        
        [display.nodes updateNode:node.index position:[self nodePosition:node] size:[self nodeSize:node] color:color]; // use index from node, not in array, so that partiual updates can work
        
    }
    
    [display.nodes endUpdate];
    
}

-(void)updateDisplay:(MapDisplay*)display forSelectedNodes:(NSArray*)arrNodes {
    [display.selectedNodes beginUpdate];
    for(int i = 0; i < arrNodes.count; i++) {
        Node* node = arrNodes[i];
        
        
        [display.selectedNodes updateNode:i position:[self nodePosition:node] size:[self nodeSize:node] color:[UIColor redColor]]; // use index from node, not in array, so that partiual updates can work
        
    }
    [display.selectedNodes endUpdate];
    
}

- (void)resetDisplay:(MapDisplay*)display forNodes:(NSArray*)arrNodes {
    display.nodes = [[Nodes alloc] initWithNodeCount:[arrNodes count]];
    
    [self updateDisplay:display forNodes:arrNodes];
}

- (void)resetDisplay:(MapDisplay *)display forSelectedNodes:(NSArray*)arrNodes {
    display.selectedNodes = [[Nodes alloc] initWithNodeCount:[arrNodes count]];
    [self updateDisplay:display forSelectedNodes:arrNodes];
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
