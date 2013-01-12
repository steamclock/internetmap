//
//  MapData
//  InternetMap
//

#include "MapData.hpp"
#include "Node.hpp"
#include "Lines.hpp"
#include "Connection.hpp"
#include "IndexBox.hpp"
#include "MapDisplay.hpp"
#include <sstream>
#include <stdlib.h>

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
        nodesByAsn.insert(std::make_pair(node->asn, node));
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
    
//    NSLog(@"load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

void MapData::loadFromAttrString(std::string json){
    std::map<std::string, int> asTypeDict;
    asTypeDict.insert(std::make_pair("abstained", AS_UNKNOWN));
    asTypeDict.insert(std::make_pair("t1", AS_T1));
    asTypeDict.insert(std::make_pair("t2", AS_T2));
    asTypeDict.insert(std::make_pair("comp", AS_COMP));
    asTypeDict.insert(std::make_pair("edu", AS_EDU));
    asTypeDict.insert(std::make_pair("ix", AS_IX));
    asTypeDict.insert(std::make_pair("nic", AS_NIC));
    
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
    
    
//    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
//    
//    NSString *fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
//    NSError *parseError = nil;
//    NSData* data = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
//    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
//    
//    //    NSLog(@"%d", [jsonObject count]);
//    for(id key in jsonObject)
//    {
//        NodePointer node = self.nodesByAsn[std::string([key UTF8String])];
//        if(node){
//            NSArray *as = [jsonObject objectForKey:key];
//            node->name = std::string([[as objectAtIndex:1] UTF8String]);
//            node->textDescription = std::string([[as objectAtIndex:5] UTF8String]);
//            node->dateRegistered = std::string([[as objectAtIndex:3] UTF8String]);
//            node->address = std::string([[as objectAtIndex:7] UTF8String]);
//            node->city = std::string([[as objectAtIndex:8] UTF8String]);
//            node->state = std::string([[as objectAtIndex:9] UTF8String]);
//            node->postalCode = std::string([[as objectAtIndex:10] UTF8String]);
//            node->country = std::string([[as objectAtIndex:11] UTF8String]);
//        }
//    }
//    
//    NSLog(@"asinfo load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
    
}

void MapData::updateDisplay(std::shared_ptr<MapDisplay> display){


//    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    visualization->resetDisplayForNodes(display, nodes);
    visualization->updateLineDisplay(display, connections);
//    NSLog(@"update display : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);

}


void MapData::createNodeBoxes() {
//    self.boxesForNodes = [NSMutableArray array];
//    
//    for (int k = 0; k < numberOfCellsZ; k++) {
//        float z = IndexBoxMinZ + boxSizeZWithoutOverlap*k;
//        for (int j = 0; j < numberOfCellsY; j++) {
//            float y = IndexBoxMinY + boxSizeYWithoutOverlap*j;
//            for(int i = 0; i < numberOfCellsX; i++) {
//                float x = IndexBoxMinX + boxSizeXWithoutOverlap*i;
//                IndexBoxPointer box = IndexBoxPointer(new IndexBox());
//                box->setCenter(Point3(x+boxSizeXWithoutOverlap/2, y+boxSizeYWithoutOverlap/2, z+boxSizeZWithoutOverlap/2));
//                box->setMinCorner(Point3(x, y, z));
//                box->setMaxCorner(Point3(x+boxSizeXWithoutOverlap, y+boxSizeYWithoutOverlap, z+boxSizeZWithoutOverlap));
//                [self.boxesForNodes addObject:box];
//            }
//        }
//    }
//    
//    for (int i = 0; i < self.nodes.size(); i++) {
//        NodePointer ptrNode = self.nodes.at(i);
//        GLKVector3 pos = [self.visualization nodePosition:ptrNode];
//        IndexBox* box = [self indexBoxForPoint:pos];
//        [box.indices addIndex:i];
//    }
}

IndexBox MapData::indexBoxForPoint(const Point3& point) {
//    GLKVector3 pos = point;
//    
//    int posX = (int)fabsf((pos.x + fabsf(IndexBoxMinX))/boxSizeXWithoutOverlap);
//    int posY = (int)fabsf((pos.y + fabsf(IndexBoxMinY))/boxSizeYWithoutOverlap);
//    int posZ = (int)fabsf((pos.z + fabsf(IndexBoxMinZ))/boxSizeZWithoutOverlap);
//    int posInArray = posX + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*posY + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*(fabsf(IndexBoxMinY)+fabsf(IndexBoxMaxY))/boxSizeYWithoutOverlap*posZ;
//    
//    return [self.boxesForNodes objectAtIndex:posInArray];
    return IndexBox();
}

