//
//  DefaultVisualization.m
//  InternetMap
//

#import "DefaultVisualization.h"
#import "MapDisplay.hpp"
#import "Node.hpp"
#import "Lines.hpp"
#import "Connection.hpp"
#import "Nodes.hpp"

// Temp conversion function while note everything is converted TODO: remove

static Point3 GLKVec3ToPoint(const GLKVector3& in) {
    return Point3(in.x, in.y, in.z);
};

static Color UIColorToColor(UIColor* color) {
    float r;
    float g;
    float b;
    float a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return Color(r, g, b, a);
}


@implementation DefaultVisualization

-(GLKVector3)nodePosition:(NodePointer)node {
    return GLKVector3Make(log10f(node->importance) + 2.0f, node->positionX, node->positionY);
}

-(float)nodeSize:(NodePointer)node {
    return 0.005 + 0.70*powf(node->importance, .75);

}



-(void)updateDisplay:(MapDisplay*)display forNodes:(std::vector<NodePointer>)arrNodes {    
    //    UIColor* nodeColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    
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



    
    display->nodes->beginUpdate();
    
    for(int i = 0; i < arrNodes.size(); i++) {
        NodePointer node = arrNodes[i];
        
        UIColor* color;
        switch(node->type) {
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
        
        display->nodes->updateNode(node->index, GLKVec3ToPoint([self nodePosition:node]), [self nodeSize:node], UIColorToColor(color)); // use index from node, not in array, so that partiual updates can work
        
    }
    
    display->nodes->endUpdate();
    
}

-(void)updateDisplay:(MapDisplay*)display forSelectedNodes:(std::vector<NodePointer>)arrNodes {
    display->selectedNodes->beginUpdate();
    for(int i = 0; i < arrNodes.size(); i++) {
        NodePointer node = arrNodes[i];
        
        display->selectedNodes->updateNode(i, GLKVec3ToPoint([self nodePosition:node]), [self nodeSize:node], UIColorToColor(SELECTED_NODE_COLOR));
        
    }
    display->selectedNodes->endUpdate();
    
}

- (void)resetDisplay:(MapDisplay*)display forNodes:(std::vector<NodePointer>)arrNodes {
    if (display->nodes) {
        //TODO: get assert back
//        NSAssert(display->nodes->count == [arrNodes count], @"display->nodes has already been allocated and you just tried to recreate it with a different count");
    }else {
        std::shared_ptr<Nodes> nodes(new Nodes(arrNodes.size()));
        display->nodes = nodes;
    }

    
    [self updateDisplay:display forNodes:arrNodes];
}

- (void)resetDisplay:(MapDisplay *)display forSelectedNodes:(std::vector<NodePointer>)arrNodes {
    if (display->selectedNodes) {
        //TODO: get assert back
//        NSAssert([display->selectedNodes count] == [arrNodes count], @"display->selectedNodes has already been allocated and you just tried to recreate it with a different count");
    }else {
        std::shared_ptr<Nodes> nodes(new Nodes(arrNodes.size()));
        display->selectedNodes = nodes;
    }
    
    [self updateDisplay:display forSelectedNodes:arrNodes];
}

-(void)updateLineDisplay:(MapDisplay*)display forConnections:(std::vector<ConnectionPointer>)connections {
    
    if([HelperMethods deviceIsOld]) {
        // No lines on 3GS, iPod 3rd Gen or iPad 1
        return;
    }
    
    std::vector<ConnectionPointer> filteredConnections;
    
    // We are only drawing lines to nodes with > 0.01 importance, filter those out
    for (int i = 0; i < connections.size(); i++) {
        ConnectionPointer connection = connections[i];
        if ((connection->first->importance > 0.01) && (connection->second->importance > 0.01)) {
            filteredConnections.push_back(connection);
        }
    }
    
    int skipLines = 10;
    
    std::shared_ptr<Lines> lines(new Lines(filteredConnections.size() / skipLines));
    
    lines->beginUpdate();
    
    int currentIndex = 0;
    int count = 0;
    for(int i = 0; i < filteredConnections.size(); i++) {
        ConnectionPointer connection = filteredConnections[i];
        count++;
        
        if((count % skipLines) != 0) {
            continue;
        }
        
        NodePointer a = connection->first;
        NodePointer b = connection->second;
        
        float lineImportanceA = MAX(a->importance - 0.01f, 0.0f) * 1.5f;
        Color lineColorA = Color(lineImportanceA, lineImportanceA, lineImportanceA, 1.0);
        
        float lineImportanceB = MAX(b->importance - 0.01f, 0.0f) * 1.5f;
        Color lineColorB = Color(lineImportanceB, lineImportanceB, lineImportanceB, 1.0);
        
        lines->updateLine(currentIndex, GLKVec3ToPoint([self nodePosition:a]), lineColorA, GLKVec3ToPoint([self nodePosition:b]), lineColorB);
        currentIndex++;
    }
    
    lines->endUpdate();;
    
    display->visualizationLines = lines;
}

@end
