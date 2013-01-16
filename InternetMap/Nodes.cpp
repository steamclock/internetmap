//
//  Nodes.m
//  InternetMap
//
//  Created by Alexander on 17.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#include "OpenGL.hpp"
#include "Program.hpp"
#include "Nodes.hpp"
#include <stdlib.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

const unsigned int MAX_NODES = 30000;

// GL vertex data for nodes
struct RawDisplayNode {
    RawVector3 position;
    float size;
    ByteColor color;
};

Nodes::Nodes(int initialCount) :
    _count(initialCount),
    _vertexBuffer(0),
    _lockedNodes(0)
{
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, MAX_NODES * sizeof(RawDisplayNode), NULL, GL_DYNAMIC_DRAW);
}

Nodes::~Nodes() {
    glDeleteBuffers(1, &_vertexBuffer);
}


void Nodes::display() {
    if( _count > MAX_NODES) {
        printf("Display node count is too high, need to increase limit");
        _count = MAX_NODES;
    }

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

void Nodes::beginUpdate() {
    if(!_lockedNodes) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        _lockedNodes = (RawDisplayNode*)glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    }
}

void Nodes::endUpdate() {
    _lockedNodes = NULL;
    glUnmapBufferOES(GL_ARRAY_BUFFER);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void Nodes::updateNode(int index, const Point3& position, float size, const Color& color) {
    updateNode(index, position);
    updateNode(index, size);
    updateNode(index, color);
    
}

void Nodes::updateNode(int index, const Point3& position) {
    RawDisplayNode* node = &_lockedNodes[index];
    node->position = position;
}

void Nodes::updateNode(int index, float size) {
    RawDisplayNode* node = &_lockedNodes[index];
    node->size = size;
}

void Nodes::updateNode(int index, const Color& color) {
    RawDisplayNode* node = &_lockedNodes[index];
    node->color = color;
}
