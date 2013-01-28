//
//  DisplayNodes.m
//  InternetMap
//
//  Created by Alexander on 17.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#include "OpenGL.hpp"
#include "Program.hpp"
#include "DisplayNodes.hpp"
#include <stdlib.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

static const int MAX_DISPLAY_NODES = 40000;

// GL vertex data for nodes
struct RawDisplayNode {
    RawVector3 position;
    float size;
    ByteColor color;
};

DisplayNodes::DisplayNodes(int count) :
    VertexBuffer(MAX_DISPLAY_NODES * sizeof(RawDisplayNode)),
    _count(count)
{
}

void DisplayNodes::display() {
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);

    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(RawDisplayNode), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_SIZE);
    glVertexAttribPointer(ATTRIB_SIZE, 1, GL_FLOAT, GL_FALSE, sizeof(RawDisplayNode), BUFFER_OFFSET(sizeof(float) * 3));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(RawDisplayNode), BUFFER_OFFSET(sizeof(float) * 4));
    
    glDrawArrays(GL_POINTS, 0, _count);
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glDisableVertexAttribArray(ATTRIB_SIZE);
    glDisableVertexAttribArray(ATTRIB_COLOR);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

RawDisplayNode* DisplayNodes::nodeAtIndex(unsigned int index) {
    return &(((RawDisplayNode*)_lockedVertices)[index]);
}

void DisplayNodes::updateNode(int index, const Point3& position, float size, const Color& color) {
    updateNode(index, position);
    updateNode(index, size);
    updateNode(index, color);
    
}

void DisplayNodes::updateNode(int index, const Point3& position) {
    RawDisplayNode* node = nodeAtIndex(index);
    node->position = position;
}

void DisplayNodes::updateNode(int index, float size) {
    RawDisplayNode* node = nodeAtIndex(index);
    node->size = size;
}

void DisplayNodes::updateNode(int index, const Color& color) {
    RawDisplayNode* node = nodeAtIndex(index);
    node->color = color;
}

int DisplayNodes::count(void) {
    return _count;
}
void DisplayNodes::setCount(int count) {
    if(_count < MAX_DISPLAY_NODES) {
        _count = count;
    }
    else {
        LOG("ERROR: trying to extend display nodes beyond vertex buffer size");
    }
}