//
//  Lines.hpp
//  InternetMap
//

// A group of lines to be rendered

#ifndef InternetMap_Lines_hpp
#define InternetMap_Lines_hpp

#include "Types.hpp"

struct LineVertex;

class Lines {
    float _width;
    int _count;
    unsigned int _vertexArray;
    unsigned int _vertexBuffer;
    LineVertex* _lockedVertices;
    
public:
    Lines(int initialCount);
    ~Lines();

    void setWidth(float width) { _width = width; }
    
    void beginUpdate(void);
    void endUpdate(void);
    void updateLine(int index, const Vector3& start, const Colour& startColour, const Vector3& end, const Colour& endColor);
    void display(void);
};

#endif