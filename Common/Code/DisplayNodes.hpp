//
//  DisplayNodes.h
//  InternetMap
//
//  Created by Alexander on 17.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

/**
 Nodes handles drawing a collection of nodes in openGL.
 */

#ifndef InternetMap_DisplayNodes_hpp
#define InternetMap_DisplayNodes_hpp

#include "Types.hpp"
#include "VertexBuffer.hpp"

struct RawDisplayNode;

class DisplayNodes : public VertexBuffer {
    int _count;
    RawDisplayNode* nodeAtIndex(unsigned int index);
    
public:
    DisplayNodes(int initialCount);

    void updateNode(int index, const Point3& position, float size, const Color& color);
    void updateNode(int index, const Point3& position);
    void updateNode(int index, float size);
    void updateNode(int index, const Color& color);
    void bindBlendTarget(void);
    void display(void);
    int count(void);
    void setCount(int);
};

#endif