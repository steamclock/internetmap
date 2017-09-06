//
//  DefaultVisualization.h
//  InternetMap
//

#ifndef InternetMap_DefaultVisualization_hpp
#define InternetMap_DefaultVisualization_hpp

#include "Visualization.hpp"

//TODO: move these to a better place
#define SELECTED_NODE_COLOR_HEX 0x00A8EC
#define SELECTED_CONNECTION_COLOR_SELF_HEX 0x383838
#define SELECTED_CONNECTION_COLOR_OTHER_HEX 0xE0E0E0
#define ROUTE_COLOR 0xffa300

//#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

class DefaultVisualization : public Visualization {
public:

    virtual std::string name(void) { return "Network View"; }

    virtual void activate(std::vector<NodePointer> nodes);

    virtual Point3 nodePosition(NodePointer node);
    virtual float nodeSize(NodePointer node);
    virtual float nodeZoom(NodePointer node);
    virtual Color nodeColor(NodePointer node);
    virtual void updateDisplayForNodes(shared_ptr<DisplayNodes> display, std::vector<NodePointer> nodes);
    virtual void updateDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes);
    virtual void resetDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes);
    virtual void updateLineDisplay(shared_ptr<MapDisplay> display);
    virtual void updateHighlightRouteLines(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodeList);
    virtual void updateConnectionLines(shared_ptr<MapDisplay> display, NodePointer node, std::vector<ConnectionPointer> connections);
    
    static void setPortrait(bool);
};

#endif

