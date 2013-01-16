//
//  Connection.h
//  InternetMap
//

#ifndef InternetMap_Connection_hpp
#define InternetMap_Connection_hpp

#include "Types.hpp"

class Node;

class Connection {
public:
    shared_ptr<Node> first;
    shared_ptr<Node> second;
};

typedef shared_ptr<Connection> ConnectionPointer;

#endif