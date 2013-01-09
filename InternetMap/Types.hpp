//
//  Types.hpp
//  InternetMap
//

#ifndef InternetMap_Types_hpp
#define InternetMap_Types_hpp

#include "ExternalCode/vectormath/vmInclude.h"

typedef vmVector3 Vector3;
typedef vmPoint3 Point3;

// Above classes are stored in 128 bytes for efficiency, so don't work as partof vertex structures,
// where we need to guarantee 3 actual floats. Use this instead in those cases
struct RawVector3 {
    RawVector3() {
        
    }
    
    RawVector3(const Point3& in) {
        x = in.getX();
        y = in.getY();
        z = in.getZ();
    }
    
    RawVector3(const Vector3& in) {
        x = in.getX();
        y = in.getY();
        z = in.getZ();
    }
    
    float x, y, z;
};

// Floating point colour
struct Colour {
    Colour() {
        
    }
    
    Colour(float R, float G, float B, float A) {
        r = R= g = G; b = B; a = A;
    }
    
    float r, g, b, a;
};

// Byte-per-component colour, suitable for inclusion in vertex arrays
struct ByteColour {
    ByteColour(const Colour& colour) {
        r = (int)(colour.r * 255.0f);
        g = (int)(colour.g * 255.0f);
        b = (int)(colour.b * 255.0f);
        a = (int)(colour.a * 255.0f);
    }
    
    unsigned char r, g, b, a;
};


// Time, stored in seconds so that it matches NSTimeInterval
typedef double Time;

#endif
