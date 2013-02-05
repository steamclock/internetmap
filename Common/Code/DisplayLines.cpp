//
//  DisplayLines.cpp
//  InternetMap
//

#include "OpenGL.hpp"
#include "DisplayLines.hpp"
#include "Program.hpp"
#include <stdlib.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

extern float gDisplayScale;

struct LineVertex {
    RawVector3 position;
    ByteColor color;
};

DisplayLines::DisplayLines(int count) :
    VertexBuffer(count * 2 * sizeof(LineVertex)),
    _width(1.0f),
    _count(count)
{
}


LineVertex* DisplayLines::vertexAtIndex(unsigned int index) {
    return &(((LineVertex*)_lockedVertices)[index]);
}

void DisplayLines::updateLine(int index, const Point3& start, const Color& startColor, const Point3& end, const Color& endColor) {
    if(index >= _count) {
        return;
    }
    
    LineVertex* vert0 = vertexAtIndex(index * 2);
    LineVertex* vert1 = vertexAtIndex(index * 2 + 1);
    
    vert0->position = start;
    vert0->color = startColor;
    
    vert1->position = end;
    vert1->color = endColor;
}

void DisplayLines::display(void) {
    glLineWidth(_width * gDisplayScale);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);

    glEnableVertexAttribArray(ATTRIB_POSITION);
    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, GL_FALSE, sizeof(LineVertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(LineVertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    glDrawArrays(GL_LINES, 0, _count * 2);
    
    glDisableVertexAttribArray(ATTRIB_POSITION);
    glDisableVertexAttribArray(ATTRIB_COLOR);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

}
