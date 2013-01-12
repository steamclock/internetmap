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
    IndexBox indexBoxForPoint(const Point3& point);
    void createNodeBoxes();
public:
    VisualizationPointer visualization;
    
    std::vector<NodePointer> nodes;
    std::map<std::string, NodePointer> nodesByAsn;
    std::vector<IndexBox> boxesForNodes;
    std::vector<ConnectionPointer> connections;
    
    void loadFromString(std::string json);
    void loadFromAttrString(std::string json);
    void loadASInfo(std::string json);
    void updateDisplay(std::shared_ptr<MapDisplay> display);
    
    NodePointer nodeAtIndex(unsigned int index);
    
};

#endif