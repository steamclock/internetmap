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
    virtual Point3 nodePosition(NodePointer node) = 0;
    virtual float nodeSize(NodePointer node) = 0;
    
    // Update the properties of the nodes in the MapDisplay
    // Note: can pass a subset of nodes and it will only update the specified
    // nodes and leave the others unchanged
    virtual void updateDisplayForNodes(std::shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) = 0;
    
    //same as updateDisplay:forNodes:, but will replace all nodes
    virtual void resetDisplayForNodes(std::shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) = 0;
    
    //same as resetDisplay:forNodes:, but for selected nodes instead of normal nodes
    virtual void resetDisplayForSelectedNodes(std::shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) = 0;
    
    // Update the visualizationLines in the display
    // Note: unlike updateDisplay, this will replace all existing lines
    virtual void updateLineDisplay(std::shared_ptr<MapDisplay> display, std::vector<ConnectionPointer>connections) = 0;
};

typedef std::shared_ptr<Visualization> VisualizationPointer;

#endif