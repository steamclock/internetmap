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
#include "TypeVisualization.hpp"
#include "GlobeVisualization.hpp"
#include "DisplayNodes.hpp"
#include "Camera.hpp"
#include "Node.hpp"
#include "DisplayLines.hpp"
#include "Connection.hpp"
#include "IndexBox.hpp"
#include "MapUtilities.hpp"

#include <algorithm>
#include <string>

// TODO: clean this up
void loadTextResource(std::string* resource, const std::string& base, const std::string& extension);
void lostSelectedNodeCallback(void);

MapController::MapController() :
    targetNode(INT_MAX),
    hoveredNodeIndex(INT_MAX)
{
    data = shared_ptr<MapData>(new MapData());
    display = shared_ptr<MapDisplay>(new MapDisplay());

    _visualizations.push_back(VisualizationPointer(new DefaultVisualization()));
    _visualizations.push_back(VisualizationPointer(new GlobeVisualization()));
    _visualizations.push_back(VisualizationPointer(new TypeVisualization("EDU", AS_EDU)));
    _visualizations.push_back(VisualizationPointer(new TypeVisualization("T1", AS_T1)));
    
    data->visualization = _visualizations[0];
    
    setTimelinePoint("", false);
    
    clock_t start = clock();
   
    std::string attrText;
    loadTextResource(&attrText, "as2attr", "txt");

    LOG("load as2attr.txt: %.2fms", (float(clock() - start) / CLOCKS_PER_SEC) * 1000);
    start = clock();
    
    data->loadFromAttrString(attrText);

    LOG("parse as2attr.txt: %.2fms", (float(clock() - start) / CLOCKS_PER_SEC) * 1000);
    start = clock();
    
    std::string asinfoText;
    loadTextResource(&asinfoText, "asinfo", "json");

    LOG("load asinfo.json: %.2fms", (float(clock() - start) / CLOCKS_PER_SEC) * 1000);
    start = clock();
    
    data->loadASInfo(asinfoText);

    LOG("parse asinfo.json: %.2fms", (float(clock() - start) / CLOCKS_PER_SEC) * 1000);
}

void MapController::handleTouchDownAtPoint(Vector2 point) {
    if (!display->camera->isMovingToTarget()) {
        display->camera->stopMomentumPan();
        display->camera->stopMomentumZoom();
        display->camera->stopMomentumRotation();
        
        int i = indexForNodeAtPoint(point);
        hoverNode(i);
    }
}

bool MapController::selectHoveredNode() {
    if (hoveredNodeIndex != INT_MAX) {
        lastSearchIP = std::string();
        updateTargetForIndex(hoveredNodeIndex);
        hoveredNodeIndex = INT_MAX;
        return true;
    }
    
    return false;
}

void MapController::hoverNode(int i) {
    unhoverNode();
    if(i != INT_MAX) {
        hoveredNodeIndex = i;
        display->nodes->beginUpdate();
        display->nodes->updateNode(i, ColorFromRGB(SELECTED_NODE_COLOR_HEX));
        display->nodes->endUpdate();
    }
}

void MapController::unhoverNode(){
    if ((hoveredNodeIndex != INT_MAX) && (hoveredNodeIndex != (int)targetNode)) {
        NodePointer node = data->nodeAtIndex(hoveredNodeIndex);
        std::vector<NodePointer> nodes;
        nodes.push_back(node);
        data->visualization->updateDisplayForNodes(display->nodes, nodes);
        hoveredNodeIndex = INT_MAX;
    }

}

void MapController::deselectCurrentNode(){
    if (targetNode != INT_MAX) {
        NodePointer node = data->nodeAtIndex(targetNode);
        std::vector<NodePointer> nodes;
        nodes.push_back(node);
        data->visualization->updateDisplayForNodes(display->nodes, nodes);
        data->visualization->resetDisplayForSelectedNodes(display, std::vector<NodePointer>());
    }
}

void MapController::updateTargetForIndex(int index) {
    Target target;
    
    // update current node to default state
    deselectCurrentNode();
    clearHighlightLines();
    
    //set new node as targeted
    if (index != INT_MAX) {
        targetNode = index;
        NodePointer node = data->nodeAtIndex(targetNode);
        if (!node->active) {
            targetNode = INT_MAX;
            lostSelectedNodeCallback();
            return;
        }
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

static bool importanceCompareConnections(ConnectionPointer i, ConnectionPointer j) {
    // need a bit of a complicated chain, becasue we want to make sure we are compaing the importance of the nodes that are NOT
    // the selected node (i.e. the one that is the same for both connections)
    if(i->first == j->first) {
        return i->second->importance > j->second->importance;
    }

    if(i->first == j->second) {
        return i->second->importance > j->first->importance;
    }

    if(i->second == j->first) {
        return i->first->importance > j->second->importance;
    }

    return i->first->importance > j->first->importance;
}

void MapController::highlightConnections(NodePointer node) {
    if(node == NULL) {
        clearHighlightLines();
        return;
    }
    
    std::vector<ConnectionPointer> filteredConnections;
    
    for (unsigned int i = 0; i<data->connections.size(); i++) {
        ConnectionPointer connection = data->connections.at(i);
        if ((connection->first == node) || (connection->second == node) ) {
            filteredConnections.push_back(connection);
        }
    }
    
    static const unsigned int NUM_IMPORTANT_CONNECTIONS = 50;
    static const unsigned int NUM_RENDERED_CONNECTIONS = 100;
    
    if (filteredConnections.size() > NUM_RENDERED_CONNECTIONS) {
        // show a few of the most important ones, then a random selection from the rest
        std::sort(filteredConnections.begin(), filteredConnections.end(), importanceCompareConnections);
        std::random_shuffle(filteredConnections.begin() + NUM_IMPORTANT_CONNECTIONS, filteredConnections.end());
    }
    
    shared_ptr<DisplayLines> lines(new DisplayLines(filteredConnections.size()));
    lines->beginUpdate();
    
    Color brightColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_BRIGHT_HEX);
    Color dimColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_DIM_HEX);

    for(unsigned int i = 0; i < std::min((unsigned int)(filteredConnections.size()), NUM_RENDERED_CONNECTIONS); i++) {
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
    data->visualization->updateDisplayForNodes(display->nodes, array);
    display->highlightLines = shared_ptr<DisplayLines>();
}

void MapController::highlightRoute(std::vector<NodePointer> nodeList) {
    if(nodeList.size() <= 1) {
        clearHighlightLines();
        return;
    }
    
    shared_ptr<DisplayLines> lines(new DisplayLines(nodeList.size() - 1));
    lines->beginUpdate();
    
    Color lineColor = ColorFromRGB(0xffa300);
    
    display->nodes->beginUpdate();
    for(unsigned int i = 0; i < nodeList.size() - 1; i++) {
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
    for (unsigned int j = 0; j<data->boxesForNodes.size(); j++) {
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

void MapController::setTimelinePoint(const std::string& origName, bool blend) {
    std::string name = (origName == "") ? "20130101" : origName;
    
    if(name == lastTimelinePoint) {
        return;
    }
    
    lastTimelinePoint = name;
    
    display->visualizationLines = shared_ptr<DisplayLines>();
    
    // remap a couple of non-jan 1st dates until we figure out a better way to track these
    if(name == "20000101") name = "20000102";
    if(name == "20090101") name = "20090103";
    if(name == "20110101") name = "20110102";
    if(name == "20120101") name = "20120102";
    if(name == "20130101") name = "20130102";
    
    clock_t start = clock();
    std::string dataText;
    loadTextResource(&dataText, name, "txt");
    data->loadFromString(dataText);
    LOG("reloaded for timeline point: %.2fms", (float(clock() - start) / CLOCKS_PER_SEC) * 1000);
    start = clock();
    updateDisplay(blend);
    LOG("refreshed display for timeline point: %.2fms", (float(clock() - start) / CLOCKS_PER_SEC) * 1000);
}

// mmmm, magic numbers
float BASE_SIZE = 0.8; // default scaledown factor for highlighted nodes from the visualzation, TODO: share properly
float EXPAND_PORTION = 0.2f; // portion of full size that it is expanded by
float EXPAND_TIME_SCALE = 0.5f; // pulses per second

void MapController::update(TimeInterval currentTime) {
    display->update(currentTime);
    
    float wrappedTime = (currentTime * EXPAND_TIME_SCALE) - floor(currentTime * EXPAND_TIME_SCALE);
    float expand = BASE_SIZE + ((0.5f - fabs(wrappedTime - 0.5f)) * EXPAND_PORTION * 2.0f);
    if(targetNode != INT_MAX) {
        NodePointer node = data->nodeAtIndex(targetNode);
        float baseSize = data->visualization->nodeSize(node);
        float expandedSize = baseSize * expand;
        display->nodes->beginUpdate();
        display->nodes->updateNode(node->index, data->visualization->nodePosition(node), expandedSize, ColorFromRGB(SELECTED_NODE_COLOR_HEX));
        display->nodes->endUpdate();
    }
}

void MapController::updateDisplay(bool blend) {
    display->nodes->setCount(data->nodes.size());
    display->targetNodes->setCount(data->nodes.size());
    
    if(blend) {
        data->visualization->updateDisplayForNodes(display->targetNodes, data->nodes);
        data->visualization->updateLineDisplay(display, data->connections);
        display->startBlend(1.0f);
    }
    else {
        data->visualization->updateDisplayForNodes(display->nodes, data->nodes);
        data->visualization->updateLineDisplay(display, data->connections);
    }
    
    if(targetNode != INT_MAX) {
        updateTargetForIndex(targetNode);
    }
}

std::vector<std::string> MapController::visualizationNames(void) {
    std::vector<std::string> result;
    for(int i = 0; i < _visualizations.size(); i++) {
        result.push_back(_visualizations[i]->name());
    }
    
    return result;
}


void MapController::setVisualization(int visualization) {
    if (visualization >= _visualizations.size()) {
        visualization = 0;
    }

    data->visualization = _visualizations[visualization];
    updateDisplay(true);
}
