//
//  DefaultVisualization.m
//  InternetMap
//

#include "DefaultVisualization.hpp"
#include "MapDisplay.hpp"
#include "Node.hpp"
#include "DisplayLines.hpp"
#include "Connection.hpp"
#include "DisplayNodes.hpp"
#include "MapUtilities.hpp"

bool deviceIsOld();

Point3 DefaultVisualization::nodePosition(NodePointer node) {
    return Point3(log10f(node->importance)+2.0f, node->positionX, node->positionY);
}

float DefaultVisualization::nodeSize(NodePointer node) {
    return 0.005 + 0.7*powf(node->importance, .75);
}

float DefaultVisualization::nodeZoom(NodePointer node) {
    float zoom = log10f(node->importance);
    zoom = -1.1 - zoom/5.0;
    //printf("zoom of %f is %f\n", node->importance, log);
    return zoom;
}


void DefaultVisualization::updateDisplayForNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) {
//    UIColor* t1Color = UIColorFromRGB(0x548dff); // Changed to blue in style guide
//    UIColor* t2Color = UIColorFromRGB(0x375ca6); // Slightly darker blue than in style guide
//    UIColor* unknownColor = UIColorFromRGB(0x7ce346); // slightly brighter green than style guide
//    UIColor* compColor = UIColorFromRGB(0x4490ce); //some other blue
//    UIColor* eduColor = UIColorFromRGB(0x7200ff); //purpley
//    UIColor* ixColor = UIColorFromRGB(0x75787b); //slate
//    UIColor* nicColor = UIColorFromRGB(0xffffff); //white, obvs
    
    
    Color t1Color = ColorFromRGB(0x548dff);
    Color t2Color = ColorFromRGB(0x375ca6);
    Color unknownColor = ColorFromRGB(0x7ce346);
    Color compColor = ColorFromRGB(0x4490ce);
    Color eduColor = ColorFromRGB(0x7200ff);
    Color ixColor = ColorFromRGB(0x75787b);
    Color nicColor = ColorFromRGB(0xffffff);
    Color inactiveColor = ColorFromRGB(0x000000);
    
    
    
    display->nodes->beginUpdate();
    
    for(unsigned int i = 0; i < nodes.size(); i++) {
        NodePointer node = nodes[i];
        
        Color color;
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
        
        if(!node->active) {
            color = inactiveColor;
        }
        
        display->nodes->updateNode(node->index, nodePosition(node), nodeSize(node), color); // use index from node, not in array, so that partiual updates can work
        
    }
    
    display->nodes->endUpdate();
}


void DefaultVisualization::resetDisplayForNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) {
    if (display->nodes) {
        display->nodes->setCount(nodes.size());
    }
    else {
        shared_ptr<DisplayNodes> theNodes(new DisplayNodes(nodes.size()));
        display->nodes = theNodes;
    }
    updateDisplayForNodes(display, nodes);
}


void DefaultVisualization::updateLineDisplay(shared_ptr<MapDisplay> display, std::vector<ConnectionPointer>connections) {
    // Disabling default lines entirely for now, but leaving th code in case we want to renable it (in some cases) later
    return;
    
    if (deviceIsOld()) {
        return;
    }
    
    std::vector<ConnectionPointer> filteredConnections;
    
    // We are only drawing lines to nodes with > 0.01 importance, filter those out
    for (unsigned int i = 0; i < connections.size(); i++) {
        ConnectionPointer connection = connections[i];
        if ((connection->first->importance > 0.01) && (connection->second->importance > 0.01)) {
            filteredConnections.push_back(connection);
        }
    }
    
    int skipLines = 10;
    
    shared_ptr<DisplayLines> lines(new DisplayLines(filteredConnections.size() / skipLines));
    
    lines->beginUpdate();
    
    int currentIndex = 0;
    int count = 0;
    for(unsigned int i = 0; i < filteredConnections.size(); i++) {
        ConnectionPointer connection = filteredConnections[i];
        count++;
        
        if((count % skipLines) != 0) {
            continue;
        }
        
        NodePointer a = connection->first;
        NodePointer b = connection->second;
        
        float lineImportanceA = std::max(a->importance - 0.01f, 0.0f) * 1.5f;
        Color lineColorA = Color(lineImportanceA, lineImportanceA, lineImportanceA, 1.0);
        
        float lineImportanceB = std::max(b->importance - 0.01f, 0.0f) * 1.5f;
        Color lineColorB = Color(lineImportanceB, lineImportanceB, lineImportanceB, 1.0);
        
        Point3 positionA = nodePosition(a);
        Point3 positionB = nodePosition(b);
        
        Point3 outsideA = MapUtilities().pointOnSurfaceOfNode(nodeSize(a), positionA, positionB);
        Point3 outsideB = MapUtilities().pointOnSurfaceOfNode(nodeSize(b), positionB, positionA);
        
        lines->updateLine(currentIndex, outsideA, lineColorA, outsideB, lineColorB);
        currentIndex++;
    }
    
    lines->endUpdate();;
    
    display->visualizationLines = lines;
}


void DefaultVisualization::updateDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) {
    display->selectedNodes->beginUpdate();
    for(unsigned int i = 0; i < nodes.size(); i++) {
        NodePointer node = nodes[i];
        
        display->selectedNodes->updateNode(i, nodePosition(node), nodeSize(node) * 0.8, ColorFromRGB(SELECTED_NODE_COLOR_HEX));
        
    }
    display->selectedNodes->endUpdate();
}

void DefaultVisualization::resetDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes){

    //TODO: this could be handled better, by reusing the vertex buffer and not recreating every time.
    //doesn't matter too much at this point because there can only be one node selected at the same time
    shared_ptr<DisplayNodes> theNodes(new DisplayNodes(nodes.size()));
    display->selectedNodes = theNodes;
    
    updateDisplayForSelectedNodes(display, nodes);
}
