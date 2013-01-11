//
//  DefaultVisualization.h
//  InternetMap
//

#ifndef InternetMap_DefaultVisualization_hpp
#define InternetMap_DefaultVisualization_hpp

#include "Visualization.hpp"

//#define SELECTED_NODE_COLOR UIColorFromRGB(0xffa300)
//#define SELECTED_CONNECTION_COLOR_BRIGHT UIColorFromRGB(0xE0E0E0)
//#define SELECTED_CONNECTION_COLOR_DIM UIColorFromRGB(0x383838)

//#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

class DefaultVisualization : Visualization {
    virtual Point3 nodePosition(Node node);
    virtual float nodeSize(Node node);
    virtual void updateDisplayForNodes(MapDisplay display, std::vector<Node> nodes);
    virtual void resetDisplayForNodes(MapDisplay display, std::vector<Node> nodes);
    virtual void resetDisplayForSelectedNodes(MapDisplay display, std::vector<Node> nodes);
    virtual void updateLineDisplay(MapDisplay display, std::vector<Connection>connections);
    
    Point3 pointOnSurfaceOfNode(float nodeSize, const Point3& centeredAt, const Point3& connectedToPoint);
};

#endif

