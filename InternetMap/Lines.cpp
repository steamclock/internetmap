//
//  Lines.cpp
//  InternetMap
//

#include "OpenGL.hpp"
#include "Lines.hpp"
#include <stdlib.h>

// TODO: Duplicated from Program.h during C++ conversion, should be able to remove once that's done
enum
{
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    ATTRIB_SIZE,
    NUM_ATTRIBUTES
};

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

struct LineVertex {
    RawVector3 position;
    ByteColour colour;
};

Lines::Lines(int initialCount) :
    _width(1.0f),
    _count(initialCount),
    _vertexArray(0),
    _vertexBuffer(0),
    _lockedVertices(0)
{
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glBufferData(GL_ARRAY_BUFFER, _count * 2 * sizeof(LineVertex), NULL, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(LineVertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(LineVertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    glBindVertexArrayOES(0);
}

Lines::~Lines() {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
}

void Lines::beginUpdate(void) {
    if(!_lockedVertices) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        _lockedVertices = (LineVertex*)glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    }
}

void Lines::endUpdate(void) {
    _lockedVertices = NULL;
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glUnmapBufferOES(GL_ARRAY_BUFFER);
}

void Lines::updateLine(int index, const Point3& start, const Colour& startColour, const Point3& end, const Colour& endColour) {
    if(index >= _count) {
        return;
    }
    
    LineVertex* vert0 = &_lockedVertices[index * 2];
    LineVertex* vert1 = &_lockedVertices[index * 2 + 1];
    
    vert0->position = start;
    vert0->colour = startColour;
    
    vert1->position = end;
    vert1->colour = endColour;
}


void Lines::display(void) {
    glLineWidth(_width);
    glBindVertexArrayOES(_vertexArray);
    glDrawArrays(GL_LINES, 0, _count * 2);
}
