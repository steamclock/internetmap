//
//  MapData
//  InternetMap
//

#ifndef InternetMap_MapData_hpp
#define InternetMap_MapData_hpp

#include <memory>
#include <vector>
#include <map>
#include "Node.hpp"
#include "Connection.hpp"
#include "Types.hpp"
#include "IndexBox.hpp"
#include "MapDisplay.hpp"
#include "Visualization.hpp"

class MapData {
    IndexBoxPointer indexBoxForPoint(const Point3& point);
    void createNodeBoxes();
public:
    VisualizationPointer visualization;
    
    std::vector<NodePointer> nodes;
    std::map<std::string, NodePointer> nodesByAsn;
    std::vector<IndexBoxPointer> boxesForNodes;
    std::vector<ConnectionPointer> connections;
    
    void loadFromString(const std::string& json);
    void loadFromAttrString(const std::string& json);
    void loadASInfo(const std::string& json);
    void updateDisplay(shared_ptr<MapDisplay> display);
    
    NodePointer nodeAtIndex(unsigned int index);
    
};

#endif