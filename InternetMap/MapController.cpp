//
//  MapController.m
//  InternetMap
//
//  Created by Alexander on 07.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#include "MapController.hpp"
#include "MapDisplay.hpp"
#include "MapData.hpp"
#include "DefaultVisualization.hpp"
#include "Nodes.hpp"
#include "Camera.hpp"
#include "Node.hpp"
#include "Lines.hpp"
#include "Connection.hpp"
#include "IndexBox.hpp"
#include "MapUtilities.hpp"

#include <algorithm>
#include <string>

// TODO: clean this up
std::string loadTextResource(std::string base, std::string extension);

MapController::MapController() :
    targetNode(INT_MAX),
    hoveredNodeIndex(INT_MAX){
        
    data = shared_ptr<MapData>(new MapData());
    display = shared_ptr<MapDisplay>(new MapDisplay());
    data->visualization = VisualizationPointer(new DefaultVisualization());
        
    data->loadFromString(loadTextResource("data", "txt"));
    data->loadFromAttrString(loadTextResource("as2attr", "txt"));
    data->loadASInfo(loadTextResource("asinfo", "json"));
}

#pragma mark - Event Handling

void MapController::handleTouchDownAtPoint(Vector2 point) {
    if (!display->camera->isMovingToTarget()) {
        display->camera->stopMomentumPan();
        display->camera->stopMomentumZoom();
        display->camera->stopMomentumRotation();
        
        int i = indexForNodeAtPoint(point);
        if(i != INT_MAX) {
            hoveredNodeIndex = i;
            display->nodes->beginUpdate();
            display->nodes->updateNode(i, ColorFromRGB(SELECTED_NODE_COLOR_HEX));
            display->nodes->endUpdate();
        }
        
    }
}


#pragma mark - Selected Node handling

void MapController::selectHoveredNode() {
    if (hoveredNodeIndex != INT_MAX) {
        lastSearchIP = std::string();
        updateTargetForIndex(hoveredNodeIndex);
        hoveredNodeIndex = INT_MAX;
    }
}

void MapController::unhoverNode(){
    if (hoveredNodeIndex != INT_MAX && hoveredNodeIndex != targetNode) {
        NodePointer node = data->nodeAtIndex(hoveredNodeIndex);
        std::vector<NodePointer> nodes;
        nodes.push_back(node);
        data->visualization->updateDisplayForNodes(display, nodes);
        hoveredNodeIndex = INT_MAX;
    }

}


void MapController::updateTargetForIndex(int index) {
    Target target;
    // update current node to default state
    if (targetNode != INT_MAX) {
        NodePointer node = data->nodeAtIndex(targetNode);
        std::vector<NodePointer> nodes;
        nodes.push_back(node);
        data->visualization->updateDisplayForNodes(display, nodes);
    }
    
    //set new node as targeted
    if (index != INT_MAX) {
        targetNode = index;
        NodePointer node = data->nodeAtIndex(targetNode);
        Point3 origTarget = data->visualization->nodePosition(node);

        target.vector = Vector3(origTarget.getX(), origTarget.getY(), origTarget.getZ());
        target.zoom = data->visualization->nodeZoom(node);
        target.maxZoom = target.zoom + 0.1;
        
        display->nodes->beginUpdate();
        display->nodes->updateNode(node->index, ColorFromRGB(SELECTED_NODE_COLOR_HEX));
        display->nodes->endUpdate();
        
        std::vector<NodePointer> nodes;
        nodes.push_back(node);
        data->visualization->resetDisplayForSelectedNodes(display, nodes);
        highlightConnections(node);
    }
    
    //change camera anchor point and zoom
    display->camera->setTarget(target);
}

#pragma mark - Connection Highlighting


void MapController::highlightConnections(NodePointer node) {
    if(node == NULL) {
        clearHighlightLines();
        return;
    }
    
    std::vector<ConnectionPointer> filteredConnections;
    
    for (int i = 0; i<data->connections.size(); i++) {
        ConnectionPointer connection = data->connections.at(i);
        if ((connection->first == node) || (connection->second == node) ) {
            filteredConnections.push_back(connection);
        }
    }
    
    
    if (filteredConnections.size() > 100) {
        // Only show important ones
        
        std::vector<ConnectionPointer> importantConnections;
        
        for (int i = 0; i<filteredConnections.size(); i++) {
            ConnectionPointer connection = filteredConnections[i];
            if((connection->first->importance > 0.01) && (connection->second->importance > 0.01)) {
                importantConnections.push_back(connection);
            }
        }
        
        filteredConnections = importantConnections;
    }
    
    if(filteredConnections.size() == 0 || filteredConnections.size() > 100) {
        clearHighlightLines();
        return;
    }
    
    shared_ptr<Lines> lines(new Lines(filteredConnections.size()));
    lines->beginUpdate();
    
    Color brightColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_BRIGHT_HEX);
    Color dimColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_DIM_HEX);

    for(int i = 0; i < filteredConnections.size(); i++) {
        ConnectionPointer connection = filteredConnections[i];
        NodePointer a = connection->first;
        NodePointer b = connection->second;
        
        // Draw lines from outside of nodes instead of center
        Point3 positionA = data->visualization->nodePosition(a);
        Point3 positionB = data->visualization->nodePosition(b);
        
        Point3 outsideA = MapUtilities().pointOnSurfaceOfNode(data->visualization->nodeSize(a), positionA, positionB);
        Point3 outsideB = MapUtilities().pointOnSurfaceOfNode(data->visualization->nodeSize(b), positionB, positionA);

        // The bright side is the current node
        if(node == a) {
            lines->updateLine(i, outsideA, brightColor, outsideB, dimColor);
        }
        else {
            lines->updateLine(i, outsideA, dimColor, outsideB, brightColor);
        }
    }
    
    lines->endUpdate();
    lines->setWidth(((filteredConnections.size() < 20) ? 2 : 1) * display->getDisplayScale());
    display->highlightLines = lines;
}

void MapController::clearHighlightLines() {
    std::set<int>::iterator iter = highlightedNodes.begin();
    std::vector<NodePointer> array;
    while (iter != highlightedNodes.end()) {
        NodePointer node = data->nodeAtIndex(*iter);
        array.push_back(node);
        iter++;
    }
    data->visualization->updateDisplayForNodes(display, array);
    display->highlightLines = shared_ptr<Lines>();
}

void MapController::highlightRoute(std::vector<NodePointer> nodeList) {
    if(nodeList.size() <= 1) {
        clearHighlightLines();
        return;
    }
    
    shared_ptr<Lines> lines(new Lines(nodeList.size() - 1));
    lines->beginUpdate();
    
    Color lineColor = ColorFromRGB(0xffa300);
    
    display->nodes->beginUpdate();
    for(int i = 0; i < nodeList.size() - 1; i++) {
        NodePointer a = nodeList[i];
        NodePointer b = nodeList[i+1];
        display->nodes->updateNode(a->index, ColorFromRGB(SELECTED_NODE_COLOR_HEX));
        display->nodes->updateNode(b->index, ColorFromRGB(SELECTED_NODE_COLOR_HEX));
        highlightedNodes.insert(a->index);
        highlightedNodes.insert(b->index);
        lines->updateLine(i, data->visualization->nodePosition(a), lineColor, data->visualization->nodePosition(b), lineColor);
    }
    
    display->nodes->endUpdate();
    
    
    lines->endUpdate();
    lines->setWidth(5.0*display->getDisplayScale());
    
    display->highlightLines = lines;
    
}

#pragma mark - Index/Position calculations

int MapController::indexForNodeAtPoint(Vector2 pointInView) {
    //get point in view and adjust it for viewport
    float xOld = pointInView.x;
    float xLoOld = 0;
    float xHiOld = display->camera->displayWidth();
    float xLoNew = -1;
    float xHiNew = 1;
    
    pointInView.x = (xOld-xLoOld) / (xHiOld-xLoOld) * (xHiNew-xLoNew) + xLoNew;
    
    float yOld = pointInView.y;
    float yLoOld = 0;
    float yHiOld = display->camera->displayHeight();
    float yLoNew = 1;
    float yHiNew = -1;
    
    pointInView.y = (yOld-yLoOld) / (yHiOld-yLoOld) * (yHiNew-yLoNew) + yLoNew;
    //transform point from screen- to object-space
    Vector3 cameraInObjectSpace = display->camera->cameraInObjectSpace(); //A
    Vector3 pointOnClipPlaneInObjectSpace = display->camera->applyModelViewToPoint(Vector2(pointInView.x, pointInView.y)); //B
    
    //do actual line-sphere intersection
    float xA, yA, zA;
    float xC, yC, zC;
    float r;
    float maxDelta = -1;
    int foundI = INT_MAX;
    
    xA = cameraInObjectSpace.getX();
    yA = cameraInObjectSpace.getY();
    zA = cameraInObjectSpace.getZ();
    
    Vector3 direction = pointOnClipPlaneInObjectSpace - cameraInObjectSpace; //direction = B - A
    Vector3 invertedDirection = Vector3(1.0f/direction.getX(), 1.0f/direction.getY(), 1.0f/direction.getZ());
    int sign[3];
    sign[0] = (invertedDirection.getX() < 0);
    sign[1] = (invertedDirection.getY() < 0);
    sign[2] = (invertedDirection.getZ() < 0);
    
    float a = powf((direction.getX()), 2)+powf((direction.getY()), 2)+powf((direction.getZ()), 2);
    
    IndexBoxPointer box;
    for (int j = 0; j<data->boxesForNodes.size(); j++) {
        box = data->boxesForNodes[j];
        if (box->doesLineIntersectOptimized(cameraInObjectSpace, invertedDirection, sign)) {
//            printf("intersects box %i at pos %f, %f\n", j, box->center().getX(), box->center().getY());
            std::set<int>::iterator iter = box->indices.begin();
            while (iter != box->indices.end()) {
                int i = *iter;
                NodePointer node = data->nodeAtIndex(i);
                
                Point3 nodePosition = data->visualization->nodePosition(node);
                xC = nodePosition.getX();
                yC = nodePosition.getY();
                zC = nodePosition.getZ();
                
                r = data->visualization->nodeSize(node)/2;
                r = std::max(r, 0.02f);
                
                float b = 2*((direction.getX())*(xA-xC)+(direction.getY())*(yA-yC)+(direction.getZ())*(zA-zC));
                float c = powf((xA-xC), 2)+powf((yA-yC), 2)+powf((zA-zC), 2)-powf(r, 2);
                float delta = powf(b, 2)-4*a*c;
                if (delta >= 0) {
                    
//                    printf("intersected node %i, delta: %f\n", i, delta);
                    Vector4 transformedNodePosition = display->camera->currentModelView() * Vector4(nodePosition.getX(), nodePosition.getY(), nodePosition.getZ(), 1);
                    if ((delta > maxDelta) && (transformedNodePosition.getZ() < -0.1)) {
                        maxDelta = delta;
                        foundI = i;
                    }
                }
                iter++;
            }
            
        }
    }
    
    return foundI;
}

Vector2 MapController::getCoordinatesForNodeAtIndex(int index) {
    NodePointer node = data->nodeAtIndex(index);
    Point3 nodePosition = data->visualization->nodePosition(node);
    
    Matrix4 mvp = display->camera->currentModelViewProjection();
    
    Vector4 proj = mvp * Vector4(nodePosition.getX(), nodePosition.getY(), nodePosition.getZ(), 1.0f);
    proj /= proj.getW();
    
    Vector2 coordinates(((proj.getX() / 2.0f) + 0.5f) * display->camera->displayWidth(), ((proj.getY() / 2.0f) + 0.5f) * display->camera->displayHeight());
    
    return Vector2(coordinates.x, display->camera->displayHeight() - coordinates.y);

}
