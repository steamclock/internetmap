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
    
    shared_ptr<MapDisplay> display;
    shared_ptr<MapData> data;
    unsigned int targetNode;
    std::set<int> highlightedNodes;
    std::string lastSearchIP;
    std::string lastTimelinePoint;
    std::string defaultYear;
    
    void hoverNode(int index);
    void unhoverNode();
    void deselectCurrentNode();
    void updateTargetForIndex(int index); //target the node at the given index
    void handleTouchDownAtPoint(Vector2 point);
    bool selectHoveredNode();
    int indexForNodeAtPoint(Vector2 pointInView);
    Vector2 getCoordinatesForNodeAtIndex(int index);
    void clearHighlightLines();
    void highlightRoute(std::vector<NodePointer> nodeList);
    void highlightConnections(NodePointer node);
    void setTimelinePoint(const std::string& name, bool blend = true);
    void update(TimeInterval currentTime);
    void updateDisplay(bool blend);
    std::string getDefaultYear(const std::string& json);
    
    std::vector<std::string> visualizationNames(void);
    void setVisualization(int visualization);
    
private:
    
    int hoveredNodeIndex;
    std::vector<VisualizationPointer> _visualizations;
};

#endif

