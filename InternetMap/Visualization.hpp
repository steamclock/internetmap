//
//  Visualization.h
//  InternetMap
//

#ifndef InternetMap_Visualization_hpp
#define InternetMap_Visualization_hpp

#include "Types.hpp"
#include <vector>
#include "Node.hpp"
#include "Connection.hpp"

class MapDisplay;

class Visualization {

public:
    virtual ~Visualization(){}
    virtual Point3 nodePosition(Node node) = 0;
    virtual float nodeSize(Node node) = 0;
    
    // Update the properties of the nodes in the MapDisplay
    // Note: can pass a subset of nodes and it will only update the specified
    // nodes and leave the others unchanged
    virtual void updateDisplayForNodes(MapDisplay display, std::vector<Node> nodes) = 0;
    
    //same as updateDisplay:forNodes:, but will replace all nodes
    virtual void resetDisplayForNodes(MapDisplay display, std::vector<Node> nodes) = 0;
    
    //same as resetDisplay:forNodes:, but for selected nodes instead of normal nodes
    virtual void resetDisplayForSelectedNodes(MapDisplay display, std::vector<Node> nodes) = 0;
    
    // Update the visualizationLines in the display
    // Note: unlike updateDisplay, this will replace all existing lines
    virtual void updateLineDisplay(MapDisplay display, std::vector<Connection>connections) = 0;
};


#endif