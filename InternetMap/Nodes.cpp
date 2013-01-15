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
    _vertexArray(0),
    _vertexBuffer(0),
    _lockedNodes(0)
{
    glEnable(GL_BLEND);
    
    glEnable(GL_POINT_SPRITE_OES);
    
    // setup vertex buffer for nodes
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glBufferData(GL_ARRAY_BUFFER, MAX_NODES * sizeof(RawDisplayNode), NULL, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(RawDisplayNode), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_SIZE);
    glVertexAttribPointer(ATTRIB_SIZE, 1, GL_FLOAT, GL_FALSE, sizeof(RawDisplayNode), BUFFER_OFFSET(sizeof(float) * 3));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(RawDisplayNode), BUFFER_OFFSET(sizeof(float) * 4));
    
    glBindVertexArrayOES(0);

}

Nodes::~Nodes() {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
}


void Nodes::display() {
    if(_lockedNodes) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glUnmapBufferOES(GL_ARRAY_BUFFER);
        _lockedNodes = NULL;
    }
    
    if( _count > MAX_NODES) {
        printf("Display node count is too high, need to increase limit");
        _count = MAX_NODES;
    }
    
    
    glBindVertexArrayOES(_vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glDrawArrays(GL_POINTS, 0, _count);
}

void Nodes::beginUpdate() {
    if(!_lockedNodes) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        _lockedNodes = (RawDisplayNode*)glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    }
}

void Nodes::endUpdate() {
    _lockedNodes = NULL;
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glUnmapBufferOES(GL_ARRAY_BUFFER);
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
