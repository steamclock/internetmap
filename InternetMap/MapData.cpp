//
//  MapData
//  InternetMap
//

#include "MapData.hpp"
#include "Node.hpp"
#include "DisplayLines.hpp"
#include "Connection.hpp"
#include "IndexBox.hpp"
#include "MapDisplay.hpp"
#include <sstream>
#include <stdlib.h>

// TODO: figure out how to do this right
#ifdef ANDROID
#include "ExternalCode/jsoncpp/json.h"
#else
#include "json.h"
#endif

NodePointer MapData::nodeAtIndex(unsigned int index) {
    return nodes[index];
}

void split( std::vector<std::string> & theStringVector,  /* Altered/returned value */
      const  std::string  & theString,
      const  std::string  & theDelimiter)
{
    size_t  start = 0, end = 0;
    
    while ( end != std::string::npos)
    {
        end = theString.find( theDelimiter, start);
        
        // If at end, use length=maxLength.  Else use length=end-start.
        theStringVector.push_back( theString.substr( start,
                                                    (end == std::string::npos) ? std::string::npos : end - start));
        
        // If at end, use start=maxSize.  Else use start=end+delimiter.
        start = (   ( end > (std::string::npos - theDelimiter.size()) )
                 ?  std::string::npos  :  end + theDelimiter.size());
    }
}

void MapData::loadFromString(std::string json) {
    
//    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    std::vector<std::string> lines;
    split(lines, json, "\n");
    std::vector<std::string> header;
    split(header, lines[0], "  ");
    int numNodes;
    std::stringstream(header[0]) >> numNodes;
    int numConnections;
    std::stringstream(header[1]) >> numConnections;
    
    for (int i = 0; i < numNodes; i++) {
        std::vector<std::string> nodeDesc;
        split(nodeDesc, lines[i+1], " ");
        
        NodePointer node(new Node());
        node->asn = nodeDesc[0];
        node->index = i;
        node->importance = ::atof(nodeDesc[1].c_str());
        node->positionX = ::atof(nodeDesc[2].c_str());
        node->positionY = ::atof(nodeDesc[3].c_str());
        node->type = AS_UNKNOWN;
        
        nodes.push_back(node);
        nodesByAsn[node->asn] = node;
    }
    

    for (int i = 0; i < numConnections; i++) {
        std::vector<std::string> connectionDesc;
        split(connectionDesc, lines[1 + numNodes + i], " ");

        ConnectionPointer connection(new Connection());
        
        connection->first = nodesByAsn[connectionDesc[0]];
        connection->second = nodesByAsn[connectionDesc[1]];
        connection->first->connections.push_back(connection);
        connection->second->connections.push_back(connection);
        connections.push_back(connection);
    }

    createNodeBoxes();
    
    LOG("Loaded %d nodes, %d connections", numNodes, numConnections);
//    NSLog(@"load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

void MapData::loadFromAttrString(std::string json){
    std::map<std::string, int> asTypeDict;
    asTypeDict["abstained"] = AS_UNKNOWN;
    asTypeDict["t1"] = AS_T1;
    asTypeDict["t2"] = AS_T2;
    asTypeDict["comp"] = AS_COMP;
    asTypeDict["edu"] = AS_EDU;
    asTypeDict["ix"] = AS_IX;
    asTypeDict["nic"] = AS_NIC;
    
    std::vector<std::string> lines;
    split(lines, json, "\n");

    for(int i = 0; i < lines.size(); i++) {
        
        std::string line = lines[i];
        std::vector<std::string> aDesc;
        split(aDesc, line, "\t");
        NodePointer node = nodesByAsn[aDesc[0]];
        
        if(node){
            
            node->type = asTypeDict[aDesc[7]];
            node->typeString = aDesc[7];
            node->textDescription = aDesc[1];
        }
    }

//    NSLog(@"attr load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);

}

void MapData::loadASInfo(std::string json){
    
    Json::Value root;
    Json::Reader reader;
    bool success = reader.parse(json, root);
    if(success) {
        std::vector<std::string> members = root.getMemberNames();
        for (int i = 0; i < members.size(); i++) {
            NodePointer node = nodesByAsn[members[i]];
            if (node) {
                Json::Value as = root[members[i]];
                node->name = as[1].asString();
                node->textDescription = as[5].asString();
                node->dateRegistered = as[3].asString();
                node->address = as[7].asString();
                node->city = as[8].asString();
                node->state = as[9].asString();
                node->postalCode = as[10].asString();
                node->country = as[11].asString();
            }
        }
    }
}

void MapData::updateDisplay(shared_ptr<MapDisplay> display){


//    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    visualization->resetDisplayForNodes(display, nodes);
    visualization->updateLineDisplay(display, connections);
//    NSLog(@"update display : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);

}


void MapData::createNodeBoxes() {
    
    for (int k = 0; k < numberOfCellsZ; k++) {
        float z = IndexBoxMinZ + boxSizeZWithoutOverlap*k;
        for (int j = 0; j < numberOfCellsY; j++) {
            float y = IndexBoxMinY + boxSizeYWithoutOverlap*j;
            for(int i = 0; i < numberOfCellsX; i++) {
                float x = IndexBoxMinX + boxSizeXWithoutOverlap*i;
                IndexBoxPointer box = IndexBoxPointer(new IndexBox());
                box->setCenter(Point3(x+boxSizeXWithoutOverlap/2, y+boxSizeYWithoutOverlap/2, z+boxSizeZWithoutOverlap/2));
                box->setMinCorner(Point3(x, y, z));
                box->setMaxCorner(Point3(x+boxSizeXWithoutOverlap, y+boxSizeYWithoutOverlap, z+boxSizeZWithoutOverlap));
                boxesForNodes.push_back(box);
            }
        }
    }
    
    for (int i = 0; i < nodes.size(); i++) {
        NodePointer ptrNode = nodes.at(i);
        Point3 pos = visualization->nodePosition(ptrNode);
        IndexBoxPointer box = indexBoxForPoint(pos);
        box->indices.insert(i);
    }
}

IndexBoxPointer MapData::indexBoxForPoint(const Point3& point) {
    
    int posX = (int)fabsf((point.getX() + fabsf(IndexBoxMinX))/boxSizeXWithoutOverlap);
    int posY = (int)fabsf((point.getY() + fabsf(IndexBoxMinY))/boxSizeYWithoutOverlap);
    int posZ = (int)fabsf((point.getZ() + fabsf(IndexBoxMinZ))/boxSizeZWithoutOverlap);
    int posInArray = posX + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*posY + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*(fabsf(IndexBoxMinY)+fabsf(IndexBoxMaxY))/boxSizeYWithoutOverlap*posZ;
    
    return boxesForNodes[posInArray];
}

