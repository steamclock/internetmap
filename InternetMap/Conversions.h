//
//  Conversions.h
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#ifndef InternetMap_Conversions_h
#define InternetMap_Conversions_h

#import <GLKit/GLKit.h>

static Point3 GLKVec3ToPoint(const GLKVector3& in) {
    return Point3(in.x, in.y, in.z);
};

static Color UIColorToColor(UIColor* color) {
    float r;
    float g;
    float b;
    float a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return Color(r, g, b, a);
}

static GLKVector3 Vec3ToGLK(const Vector3& in) {
    return GLKVector3Make(in.getX(), in.getY(), in.getZ());
};

#endif
