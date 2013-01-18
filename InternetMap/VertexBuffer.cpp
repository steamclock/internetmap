//
//  VertexBuffer.cpp
//  InternetMap
//

#include "VertexBuffer.hpp"
#include "OpenGL.hpp"
#include <stdlib.h>

VertexBuffer::VertexBuffer(int size) :
_size(size),
_vertexBuffer(0),
_lockedVertices(0)
{
    // set up vertex buffer state
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, size, NULL, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

VertexBuffer::VertexBuffer() {
    if(!gHasMapBuffer && _lockedVertices) {
        delete _lockedVertices;
    }
    
    glDeleteBuffers(1, &_vertexBuffer);
}

void VertexBuffer::beginUpdate() {
    if(gHasMapBuffer ) {
        if(!_lockedVertices) {
            glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
            _lockedVertices = (unsigned char*)glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
        }
    }
    else {
        if(!_lockedVertices) {
            _lockedVertices = new unsigned char[_size];
        }
    }
}

void VertexBuffer::endUpdate() {
    if(gHasMapBuffer ) {
        _lockedVertices = NULL;
        glUnmapBufferOES(GL_ARRAY_BUFFER);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, _size, _lockedVertices, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
}
