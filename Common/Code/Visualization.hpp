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

class DisplayNodes;
class MapDisplay;

class Visualization {

public:
    virtual ~Visualization(){}
    virtual Point3 nodePosition(NodePointer node) = 0;
    virtual float nodeSize(NodePointer node) = 0;
    virtual float nodeZoom(NodePointer node) = 0;
    virtual Color nodeColor(NodePointer node) = 0;
    
    // Update the properties of the nodes in the MapDisplay
    // Note: can pass a subset of nodes and it will only update the specified
    // nodes and leave the others unchanged
    virtual void updateDisplayForNodes(shared_ptr<DisplayNodes> display, std::vector<NodePointer> nodes) = 0;
        
    virtual void updateDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) = 0;
    
    //same as resetDisplay:forNodes:, but for selected nodes instead of normal nodes
    virtual void resetDisplayForSelectedNodes(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodes) = 0;
    
    // Update the visualizationLines in the display
    // Note: unlike updateDisplay, this will replace all existing lines
    virtual void updateLineDisplay(shared_ptr<MapDisplay> display, std::vector<ConnectionPointer>connections) = 0;
};

typedef shared_ptr<Visualization> VisualizationPointer;

#endif