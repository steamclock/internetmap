//
//  Nodes.h
//  InternetMap
//
//  Created by Alexander on 17.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#ifndef InternetMap_Nodes_hpp
#define InternetMap_Nodes_hpp

#include "Types.hpp"

struct RawDisplayNode;

class Nodes {
    
    unsigned int _count;
    unsigned int _vertexArray;
    unsigned int _vertexBuffer;
    RawDisplayNode* _lockedNodes;
    
public:
    Nodes(int initialCount);
    ~Nodes();

    void beginUpdate(void);
    void endUpdate(void);
    void updateNode(int index, const Point3& position, float size, const Colour& color);
    void updateNode(int index, const Point3& position);
    void updateNode(int index, float size);
    void updateNode(int index, const Colour& color);
    void display(void);
    int count(void);

}

#endif