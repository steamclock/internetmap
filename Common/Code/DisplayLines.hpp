//
//  DisplayLines
//  InternetMap
//

// A group of lines to be rendered

#ifndef InternetMap_DisplayLines_hpp
#define InternetMap_DisplayLines_hpp

#include "Types.hpp"
#include "VertexBuffer.hpp"

struct LineVertex;

class DisplayLines : public VertexBuffer {
    float _width;
    int _count;
    
    LineVertex* vertexAtIndex(unsigned int index);
public:
    DisplayLines(int count);

    void setWidth(float width) { _width = width; }
    
    void updateLine(int index, const Point3& start, const Color& startColor, const Point3& end, const Color& endColor);
    void display(void);
};

#endif