//
//  Types.hpp
//  InternetMap
//

#ifndef InternetMap_Types_hpp
#define InternetMap_Types_hpp

#include <GLKit/GLKMath.h>

typedef GLKVector4 Colour;
typedef GLKVector3 Vector3;

struct ByteColour {
    ByteColour(const Colour& colour) {
        r = (int)(colour.x * 255.0f);
        g = (int)(colour.y * 255.0f);
        b = (int)(colour.z * 255.0f);
        a = (int)(colour.w * 255.0f);
    }
    
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
};

#endif
