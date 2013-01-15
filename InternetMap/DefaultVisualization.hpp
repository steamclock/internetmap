//
//  DefaultVisualization.h
//  InternetMap
//

#ifndef InternetMap_DefaultVisualization_hpp
#define InternetMap_DefaultVisualization_hpp

#include "Visualization.hpp"

//TODO: move these to a better place
#define SELECTED_NODE_COLOR_HEX 0xffa300
#define SELECTED_CONNECTION_COLOR_BRIGHT_HEX 0xE0E0E0
#define SELECTED_CONNECTION_COLOR_DIM_HEX 0x383838

//#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

class DefaultVisualization : public Visualization {
    virtual Point3 nodePosition(NodePointer node);
    virtual float nodeSize(NodePointer node);
    virtual float nodeZoom(NodePointer node);
    virtual void updateDisplayForNodes(std::shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes);
    virtual void resetDisplayForNodes(std::shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes);
    virtual void updateDisplayForSelectedNodes(std::shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes);
    virtual void resetDisplayForSelectedNodes(std::shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes);
    virtual void updateLineDisplay(std::shared_ptr<MapDisplay> display, std::vector<ConnectionPointer>connections);
};

#endif

