//
//  MapController.h
//  InternetMap
//
//  Created by Alexander on 07.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//
#ifndef InternetMap_MapController_hpp
#define InternetMap_MapController_hpp

#include "Node.hpp"
#include "Types.hpp"
#include <set>
#include "MapDisplay.hpp"
#include "MapData.hpp"

class MapController {
    
public:
    MapController();
    
    std::shared_ptr<MapDisplay> display;
    std::shared_ptr<MapData> data;
    unsigned int targetNode;
    int hoveredNodeIndex;
    std::set<int> highlightedNodes;
    std::string lastSearchIP;
    
    
    void unhoverNode();
    void updateTargetForIndex(int index);
    void handleTouchDownAtPoint(Vector2 point);
    void selectHoveredNode();
    int indexForNodeAtPoint(Vector2 pointInView);
    Vector2 getCoordinatesForNodeAtIndex(int index);
    void clearHighlightLines();
    void highlightRoute(std::vector<NodePointer> nodeList);
    void highlightConnections(NodePointer node);
};

#endif

