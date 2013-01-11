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

class MapData {
    IndexBox indexBoxForPoint(const Point3& point);
    void createNodeBoxes();
public:
    
    
    std::vector<Node> nodes;
    std::map<std::string, Node> nodesByAsn;
    std::vector<IndexBox> boxesForNodes;
    std::vector<Connection> connections;
    
    void loadFromString(std::string json);
    void loadFromAttrString(std::string json);
    void loadASInfo(std::string json);
    void updateDisplay(MapDisplay* display);
    
    Node nodeAtIndex(unsigned int index);
    
};

#endif