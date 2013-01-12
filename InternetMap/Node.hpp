//
//  Node.h
//  InternetMap
//


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
    
    std::string asn;
    unsigned int index;
    float importance;
    float positionX;
    float positionY;
    int type;
    
    std::string typeString;
    std::string name;
    std::string textDescription;
    std::string dateRegistered;
    std::string address;
    std::string city;
    std::string state;
    std::string postalCode;
    std::string country;
    
    std::vector<ConnectionPointer> connections;
    
};


typedef std::shared_ptr<Node> NodePointer;

#endif
