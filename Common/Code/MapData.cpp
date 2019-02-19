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
#include <fstream>
#include <assert.h>
#include <string.h>

// TODO: figure out how to do this right
#ifdef ANDROID
#include "jsoncpp/json.h"
#include <string.h>
#else
#include "json.h"
#endif

static const char *ASNS_AT_TOP[] = {"13768", "23498", "3", "15169", "714", "32934", "7847"}; //Peer1, Cogeco, MIT, google, apple, facebook, NASA
static const int NUM_ASNS_AT_TOP = 7;

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

static const int MAX_TOKEN_SIZE = 256;

const char* nextToken(const char* source, char* token, bool* lineEnd, char separator = ' ') {
    *lineEnd = false;
    
    while ((*source != separator) && (*source != '\n') && (*source != 0)) {
        *token++ = *source++;
    }
    
    *lineEnd |= *source == '\n';
    
    *token = 0;

    if(*source != 0) {
        while ((*source == separator) || (*source == '\n')) {
            source++;
            *lineEnd |= *source == '\n';
        }
    }
    
    return source;
}

void MapData::resetToDefault() {
    for(int i = 0; i < nodes.size(); i++) {
        Node* node = nodes[i].get();
        
        node->timelineActive = node->activeDefault;
        if(node->activeDefault) {
            node->positionX = node->defaultPositionX;
            node->positionY = node->defaultPositionY;
            node->importance = node->defaultImportance;
        }
    }
    
    connections = defaultConnections;
    
    visualization->activate(nodes);
    
    createNodeBoxes();
}

void MapData::loadFromString(const std::string& text) {
    // Connections an boxes are always fully regenerated
    connections.erase(connections.begin(), connections.end());
    
    // Mark all nodes as inactive (they will be reactivated if they are in the current data set)
    for(int i = 0; i < nodes.size(); i++) {
        nodes[i]->timelineActive = false;
    }
    
    const char* sourceText = text.c_str();
    char token[MAX_TOKEN_SIZE];
    bool lineEnd;
    int numNodes, numConnections;
    
    bool firstLoad = nodes.size() == 0;
    
    // Grab header data (node and connection counts)
    sourceText = nextToken(sourceText, token, &lineEnd);
    numNodes = atof(token);
    
    sourceText = nextToken(sourceText, token, &lineEnd);
    numConnections = atof(token);
    
    if (nodes.size() == 0) {
        LOG("initializing nodes vector (total %d)", numNodes);
        nodes.reserve(numNodes);
        nodes.resize(NUM_ASNS_AT_TOP);
        //LOG("nodes.size: %ld", nodes.size());
    }
    
    int missingNodes = 0;
    for (int i = 0; i < numNodes; i++) {
        // Grab asn
        sourceText = nextToken(sourceText, token, &lineEnd);
        
        // check for matching existing node
        NodePointer node = nodesByAsn[token];
        
        if(node) {
            // already thre, just mark as active
            node->timelineActive = true;
            node->neverLoaded = false;
        }
        else {
            // Not there, create
            missingNodes++;
            
            node = NodePointer(new Node());
            node->asn = token;
            node->type = AS_UNKNOWN;
            node->timelineActive = true;
            
            //is it a special node?
            bool needInsert = false;
            for (int i=0; i<NUM_ASNS_AT_TOP; i++) {
                if (strcmp(token, ASNS_AT_TOP[i]) == 0) {
                    node->index = i;
                    needInsert = true;
                    //LOG("found special at index %d", node->index);
                    break;
                }
            }
            
            if (needInsert) {
                nodes[node->index] = node;
            } else {
                //regular nodes can just be appended.
                node->index = static_cast<int>(nodes.size());
                nodes.push_back(node);
            }
            nodesByAsn[node->asn] = node;
        }
        
        // Refill data that is unique to a particualar timeline position
        sourceText = nextToken(sourceText, token, &lineEnd);
        if(node) {
            node->importance = atof(token);
        }
        sourceText = nextToken(sourceText, token, &lineEnd);
        if(node) {
            node->positionX = atof(token);
        }
        sourceText = nextToken(sourceText, token, &lineEnd);
        if(node) {
            node->positionY = atof(token);
        }
        
        if(node && firstLoad) {
            node->defaultPositionX = node->positionX;
            node->defaultPositionY = node->positionY;
            node->defaultImportance = node->importance;
            node->activeDefault = true;
        }
    }
    
    // Load connections
    for (int i = 0; i < numConnections; i++) {
        ConnectionPointer connection(new Connection());
        
        sourceText = nextToken(sourceText, token, &lineEnd);
        connection->first = nodesByAsn[token];
        sourceText = nextToken(sourceText, token, &lineEnd);
        connection->second = nodesByAsn[token];
        
        if (connection->first && connection->second) {
            connection->first->connections.push_back(connection);
            connection->second->connections.push_back(connection);
            connections.push_back(connection);
        }
    }
    
    if(firstLoad) {
        defaultConnections = connections;
    }
    
    LOG("loaded data: %d nodes (this load), %d nodes (total), %d connections", missingNodes, (int)(nodes.size()), numConnections);
    
    visualization->activate(nodes);

    createNodeBoxes();
}

void MapData::loadFromAttrString(const std::string& json){
    std::map<std::string, int> asTypeDict;
    asTypeDict["abstained"] = AS_UNKNOWN;
    asTypeDict["t1"] = AS_T1;
    asTypeDict["t2"] = AS_T2;
    asTypeDict["comp"] = AS_COMP;
    asTypeDict["edu"] = AS_EDU;
    asTypeDict["ix"] = AS_IX;
    asTypeDict["nic"] = AS_NIC;
        
    std::map<int, std::string> friendlyTypeStrings;
    friendlyTypeStrings[(int)AS_UNKNOWN] = "Unknown Network Type";
    friendlyTypeStrings[(int)AS_T1] = "Large ISP";
    friendlyTypeStrings[(int)AS_T2] = "Small ISP";
    friendlyTypeStrings[(int)AS_COMP] = "Organization Network";
    friendlyTypeStrings[(int)AS_EDU] = "University";
    friendlyTypeStrings[(int)AS_IX] = "Internet Exchange Point";
    friendlyTypeStrings[(int)AS_NIC] = "Network Information Center";
    
    std::vector<std::string> lines;
    split(lines, json, "\n");

    for(unsigned int i = 0; i < lines.size(); i++) {
        
        std::string line = lines[i];
        std::vector<std::string> aDesc;
        split(aDesc, line, "\t");
        NodePointer node = nodesByAsn[aDesc[0]];
        
        if(node){
            
            node->type = asTypeDict[aDesc[7]];
            node->typeString = friendlyTypeStrings[node->type];
            node->rawTextDescription = aDesc[1];
        }
    }

//    NSLog(@"attr load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);

}

void MapData::loadASInfo(const std::string& json){
    
    Json::Value root;
    Json::Reader reader;
    bool success = reader.parse(json, root);
    
    int missing = 0;
    if(success) {
        std::vector<std::string> members = root.getMemberNames();
        for (unsigned int i = 0; i < members.size(); i++) {
            NodePointer node = nodesByAsn[members[i]];
            
            if(!node) {
                node = NodePointer(new Node());
                node->asn = members[i];
                node->type = AS_UNKNOWN;
                node->timelineActive = false;
                
                node->neverLoaded = true;
                
                node->index = static_cast<int>(nodes.size());
                nodes.push_back(node);
                nodesByAsn[node->asn] = node;
                
                missing++;
            }
            
            if (node) {
                Json::Value as = root[members[i]];
//                node->name = as[1].asString();
//                node->rawTextDescription = as[5].asString();
//                node->dateRegistered = as[3].asString();
//                node->address = as[7].asString();
//                node->city = as[8].asString();
//                node->state = as[9].asString();
//                node->postalCode = as[10].asString();
//                node->country = as[11].asString();
//                node->hasLatLong = true;
//                node->latitude = as[12].asFloat()*2.0*3.14159/360.0;
//                node->longitude = as[13].asFloat()*2.0*3.14159/360.0;

                node->rawTextDescription = as[0].asString();
                node->hasLatLong = true;
                node->latitude = as[1].asFloat()*2.0*3.14159/360.0;
                node->longitude = as[2].asFloat()*2.0*3.14159/360.0;
            }
        }
    }
    
    LOG("%d nodes added by asinfo", missing);
}

void MapData::loadUnified(const std::string& text) {
    const char* sourceText = text.c_str();
    
    char token[MAX_TOKEN_SIZE];
    bool lineEnd;
    int numNodes, numConnections;
    
    // Grab header data (node and connection counts)
    sourceText = nextToken(sourceText, token, &lineEnd);
    numNodes = atof(token);
    
    sourceText = nextToken(sourceText, token, &lineEnd);
    numConnections = atof(token);
    
    nodes.reserve(numNodes);
    
    for (int i = 0; i < numNodes; i++) {
        NodePointer node = NodePointer(new Node());
        
        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->asn = token;

        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        if(token[0] != '?') {
            node->rawTextDescription = token;
        }

        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->type = atoi(token);

        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->timelineActive = node->activeDefault = atoi(token);

        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->hasLatLong = atoi(token);
        
        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->latitude = atof(token);

        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->longitude = atof(token);
                
        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->positionX = node->defaultPositionX = atof(token);
        
        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->positionY = node->defaultPositionY = atof(token);

        sourceText = nextToken(sourceText, token, &lineEnd, '\t');
        node->importance = node->defaultImportance = atof(token);

        assert(lineEnd);
        
        node->index = static_cast<int>(nodes.size());
        nodes.push_back(node);
        nodesByAsn[node->asn] = node;
    }

    // Load connections
    for (int i = 0; i < numConnections; i++) {
        ConnectionPointer connection(new Connection());
        
        sourceText = nextToken(sourceText, token, &lineEnd);
        connection->first = nodes[atoi(token)];
        sourceText = nextToken(sourceText, token, &lineEnd);
        connection->second = nodes[atoi(token)];
        
        if (connection->first && connection->second) {
            connection->first->connections.push_back(connection);
            connection->second->connections.push_back(connection);
            connections.push_back(connection);
        }
    }
    
    defaultConnections = connections;
    
    LOG("loaded default data: %d nodes, %d connections", (int)(nodes.size()), numConnections);
    
    visualization->activate(nodes);
    
    createNodeBoxes();
}

void MapData::createNodeBoxes() {
    boxesForNodes.erase(boxesForNodes.begin(), boxesForNodes.end());
    
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
    
    for (unsigned int i = 0; i < nodes.size(); i++) {
        NodePointer ptrNode = nodes.at(i);
        if(ptrNode->isActive()) {
            Point3 pos = visualization->nodePosition(ptrNode);
            IndexBoxPointer box = indexBoxForPoint(pos);
            box->indices.insert(i);
        }
    }
}

IndexBoxPointer MapData::indexBoxForPoint(const Point3& point) {
    
    int posX = (int)fabsf((point.getX() + fabsf(IndexBoxMinX))/boxSizeXWithoutOverlap);
    int posY = (int)fabsf((point.getY() + fabsf(IndexBoxMinY))/boxSizeYWithoutOverlap);
    int posZ = (int)fabsf((point.getZ() + fabsf(IndexBoxMinZ))/boxSizeZWithoutOverlap);
    int posInArray = posX + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*posY + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*(fabsf(IndexBoxMinY)+fabsf(IndexBoxMaxY))/boxSizeYWithoutOverlap*posZ;
    
    return boxesForNodes[posInArray];
}

void MapData::dumpUnified(void) {
    std::ofstream out("/Users/shayla/Downloads/unified.txt");
    
    int numNodes =0;
    int numConnections = 0;

    for(int i = 0; i < nodes.size(); i++) {
        if(!nodes[i]->neverLoaded) {
            numNodes++;
        }
    }

    for(int i = 0; i < connections.size(); i++) {
        if(!nodes[connections[i]->first->index]->neverLoaded && !nodes[connections[i]->second->index]->neverLoaded) {
            numConnections++;
        }
    }


    out << numNodes << std::endl;
    out << numConnections << std::endl;
    
    for(int i = 0; i < nodes.size(); i++) {
        if(nodes[i]->neverLoaded) {
            continue;
        }
        
        std::string desc = nodes[i]->rawTextDescription;
        
        if(desc.length() == 0) {
            desc = "?";
        }
        
        out << nodes[i]->asn << "\t"
            << desc << "\t"
            << nodes[i]->type << "\t"
            << nodes[i]->timelineActive << "\t"
            << nodes[i]->hasLatLong << "\t"
            << nodes[i]->latitude << "\t"
            << nodes[i]->longitude << "\t"
            << nodes[i]->positionX << "\t"
            << nodes[i]->positionY << "\t"
            << nodes[i]->importance << "\t" << std::endl;
    }
    
    for(int i = 0; i < connections.size(); i++) {
        if(nodes[connections[i]->first->index]->neverLoaded || nodes[connections[i]->second->index]->neverLoaded) {
            continue;
        }

        out << connections[i]->first->index << " " << connections[i]->second->index << std::endl;
    }
}
