//
//  Connection.h
//  InternetMap
//

#ifndef InternetMap_Connection_hpp
#define InternetMap_Connection_hpp

#include "Node.hpp"

class Connection {
public:
    NodePointer first;
    NodePointer second;
};

typedef std::shared_ptr<Connection> ConnectionPointer;

#endif