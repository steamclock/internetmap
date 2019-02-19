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

static bool sPortrait = false;
float DefaultVisualization::sNodeScale = 1.0f;
Color DefaultVisualization::sSelectedColor = ColorFromRGB(SELECTED_NODE_COLOR_HEX);

void DefaultVisualization::setPortrait(bool b) {
    sPortrait = b;
}

void DefaultVisualization::setNodeScale(float s) {
    sNodeScale = s;
}

void DefaultVisualization::setSelectedNodeColour(Color c) {
    sSelectedColor = c;
}

Color DefaultVisualization::getSelectedNodeColour() {
    return sSelectedColor;
}


void DefaultVisualization::activate(std::vector<NodePointer> nodes) {
    for(unsigned int i = 0; i < nodes.size(); i++) {
        nodes[i]->visualizationActive = true;
    }
}

Point3 DefaultVisualization::nodePosition(NodePointer node) {
    // We want the long axis of the network view aligned to the long axis of the screen, so we generate the node positions differently
    // depending on whether we are in portrait mode or not
    return sPortrait ? Point3(node->positionX, log10f(node->importance)+2.0f, node->positionY) :
                       Point3(log10f(node->importance)+2.0f, node->positionX, node->positionY);
}

float DefaultVisualization::nodeSize(NodePointer node) {
    return sNodeScale * (0.005 + 0.7*powf(node->importance, .75));
}

float DefaultVisualization::nodeZoom(NodePointer node) {
    float zoom = log10f(node->importance);
    zoom = -1.1 - zoom/5.0;
    //printf("zoom of %f is %f\n", node->importance, log);
    return zoom;
}

Color DefaultVisualization::nodeColor(NodePointer node) {
    switch(node->type) {
        
        case AS_T1:
            return ColorFromRGB(0x0061c0);
        case AS_T2:
            return ColorFromRGB(0x3787d5);
        case AS_COMP:
            return ColorFromRGB(0xd66696);
        case AS_EDU:
            return ColorFromRGB(0xe67700);
        case AS_IX:
            return ColorFromRGB(0xffffff);
        case AS_NIC:
            return ColorFromRGB(0x999999);
        default:
            return ColorFromRGB(0x47cdff);
    }
}


void DefaultVisualization::updateDisplayForNodes(shared_ptr<DisplayNodes> display, std::vector<NodePointer> nodes) {
    
    display->beginUpdate();
    
    for(unsigned int i = 0; i < nodes.size(); i++) {
        NodePointer node = nodes[i];
        
        Color color;
        Point3 position;
        float size;

        if(node->isActive()) {
            position = nodePosition(node);
            size = nodeSize(node);
            color = nodeColor(node);
        }
        else {
            color = ColorFromRGB(0x000000);
            position = nodePosition(node);
            size = 0.0f;
        }
        
        display->updateNode(node->index, position, size, color); // use index from node, not in array, so that partiual updates can work
        
    }
    
    display->endUpdate();
}

void DefaultVisualization::updateLineDisplay(shared_ptr<MapDisplay> display) {
    // No visualization lines for default visualization
    display->visualizationLines = shared_ptr<DisplayLines>();
    return;
}



void DefaultVisualization::updateDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) {
    display->selectedNodes->beginUpdate();
    for(unsigned int i = 0; i < nodes.size(); i++) {
        NodePointer node = nodes[i];
        float origSize = nodeSize(node) * 0.8f;
        float scaledSize = (sNodeScale == 1.0f) ? origSize : fmax(0.03f, origSize);

        display->selectedNodes->updateNode(i, nodePosition(node), scaledSize, DefaultVisualization::getSelectedNodeColour());
        
    }
    display->selectedNodes->endUpdate();
}

void DefaultVisualization::resetDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes){

    //TODO: this could be handled better, by reusing the vertex buffer and not recreating every time.
    //doesn't matter too much at this point because there can only be one node selected at the same time
    shared_ptr<DisplayNodes> theNodes(new DisplayNodes((int)nodes.size()));
    display->selectedNodes = theNodes;
    
    updateDisplayForSelectedNodes(display, nodes);
}



void DefaultVisualization::updateHighlightRouteLines(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodeList) {
    shared_ptr<DisplayLines> lines(new DisplayLines(static_cast<int>(nodeList.size() - 1)));
    lines->beginUpdate();
    Color lineColor = ColorFromRGB(0xffa300);

    for(unsigned int i = 0; i < nodeList.size() - 1; i++) {
        NodePointer a = nodeList[i];
        NodePointer b = nodeList[i+1];
        lines->updateLine(i, nodePosition(a), lineColor, nodePosition(b), lineColor);
    }

    lines->endUpdate();
    lines->setWidth(5.0);

    display->highlightLines = lines;
}

void DefaultVisualization::updateConnectionLines(shared_ptr<MapDisplay> display, NodePointer node, std::vector<ConnectionPointer> connections) {
    shared_ptr<DisplayLines> lines(new DisplayLines((int)connections.size()));
    lines->beginUpdate();

    Color otherColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_OTHER_HEX);
    Color selfColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_SELF_HEX);

    for(unsigned int i = 0; i < connections.size(); i++) {
        ConnectionPointer connection = connections[i];
        NodePointer a = connection->first;
        NodePointer b = connection->second;

        // Draw lines from outside of nodes instead of center
        Point3 positionA = nodePosition(a);
        Point3 positionB = nodePosition(b);

        Point3 outsideA = MapUtilities().pointOnSurfaceOfNode(nodeSize(a), positionA, positionB);
        Point3 outsideB = MapUtilities().pointOnSurfaceOfNode(nodeSize(b), positionB, positionA);

        // The bright side is the current node
        if(node == a) {
            lines->updateLine(i, outsideA, selfColor, outsideB, otherColor);
        }
        else {
            lines->updateLine(i, outsideA, otherColor, outsideB, selfColor);
        }
    }

    lines->endUpdate();
    lines->setWidth(((connections.size() < 20) ? 2 : 1));
    display->highlightLines = lines;
}
