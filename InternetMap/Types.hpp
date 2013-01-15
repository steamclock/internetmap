//
//  Types.hpp
//  InternetMap
//

#ifndef InternetMap_Types_hpp
#define InternetMap_Types_hpp

#define ColorFromRGB(rgbValue) Color(((float)((rgbValue & 0xFF0000) >> 16))/255.0, ((float)((rgbValue & 0xFF00) >> 8))/255.0,((float)(rgbValue & 0xFF))/255.0, 1.0)

#include "ExternalCode/vectormath/vmInclude.h"
#include "ExternalCode/vectormath/vmInclude.h"

#ifdef ANDROID
#include <boost/smart_ptr/shared_ptr.hpp>
using boost::shared_ptr;
#else
#include <memory>
using std::shared_ptr;
#endif

#ifdef ANDROID
#include <android/log.h>
#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "InternetMap", __VA_ARGS__)
#else
#define LOG(...) printf(__VA_ARGS__)
#endif

typedef Vectormath::Aos::Matrix4 Matrix4;
typedef vmVector3 Vector3;
typedef Vectormath::Aos::Vector4 Vector4;
typedef vmPoint3 Point3;
typedef Vectormath::Aos::Quat Quaternion;

struct Vector2 {
    Vector2() { x = y = 0.0f; }
    Vector2(float X, float Y) { x = X; y = Y; }
    float x, y;
};

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

// Floating point color
struct Color {
    Color() {
        
    }
    
    Color(float R, float G, float B, float A) {
        r = R; g = G; b = B; a = A;
    }
    
    float r, g, b, a;
};

// Byte-per-component color, suitable for inclusion in vertex arrays
struct ByteColor {
    ByteColor(const Color& color) {
        r = (int)(color.r * 255.0f);
        g = (int)(color.g * 255.0f);
        b = (int)(color.b * 255.0f);
        a = (int)(color.a * 255.0f);
    }
    
    unsigned char r, g, b, a;
};


// Time, stored in seconds so that it matches NSTimeInterval
typedef double TimeInterval;

static inline float DegreesToRadians(float degrees) {
    return (degrees/360.0f) * 2.0f * M_PI;
}

#endif
