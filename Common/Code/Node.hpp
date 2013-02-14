//
//  Node.h
//  InternetMap
//

/** A Node holds data for one ASN.
 ASN = Autonomous System Number
 Each of these systems is an entity that controls the routing for their network.
 We're more interested in the connections between systems, not what goes on inside them.
 */
 
#ifndef InternetMap_Node_hpp
#define InternetMap_Node_hpp

#include <string>
#include <vector>
#include "Connection.hpp"

enum
{
    AS_UNKNOWN,
    AS_T1,
    AS_T2,
    AS_COMP,
    AS_EDU,
    AS_IX,
    AS_NIC
};


class Node {
    
public:
    Node();
    
    std::string asn;
    unsigned int index;
    float importance;
    float positionX;
    float positionY;
    int type;
    bool timelineActive;
    bool visualizationActive;
    
    // cached values for newest data, so that we can switch back quickly
    float activeDefault;
    float defaultImportance;
    float defaultPositionX;
    float defaultPositionY;
    
    std::string typeString;
    std::string name;
    std::string rawTextDescription; //raw node description; do not use in the UI (use friendlyDescription instead)
    std::string dateRegistered;
    std::string address;
    std::string city;
    std::string state;
    std::string postalCode;
    std::string country;
    
    bool hasLatLong;
    float latitude;
    float longitude;
    
    std::vector<ConnectionPointer> connections;
    
    std::string friendlyDescription(); //rawTextDescription with some cleanup applied
    bool isActive() { return timelineActive && visualizationActive; }
private:
    std::string mFriendlyDescription;
    bool mInitializedFriendly;
};


typedef shared_ptr<Node> NodePointer;

#endif
