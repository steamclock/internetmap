//
//  Connection.h
//  InternetMap
//

#ifndef InternetMap_Connection_hpp
#define InternetMap_Connection_hpp

#include <memory>

class Node;

class Connection {
public:
    Node* first;
    Node* second;
};

typedef std::shared_ptr<Connection> ConnectionPointer;

#endif