//
//  VertexBuffer.h
//  InternetMap
//

#ifndef __InternetMap__VertexBuffer__
#define __InternetMap__VertexBuffer__

class VertexBuffer {
protected:
    unsigned long _size;
    unsigned int _vertexBuffer;
    unsigned char* _lockedVertices;
    
public:
    VertexBuffer(long size);
    VertexBuffer();
    
    void beginUpdate(void);
    void endUpdate(void);
    long vertexCount(void);
};

#endif /* defined(__InternetMap__VertexBuffer__) */
