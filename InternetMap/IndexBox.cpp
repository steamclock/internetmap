//
//  IndexBox.m
//  InternetMap
//
//  Created by Alexander on 11.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "IndexBox.hpp"

bool IndexBox::isPointInside(const Point3 &point) {
    return (point.x > center.x-boxSizeXWithoutOverlap) && (point.x < center.x+boxSizeXWithoutOverlap) &&
    (point.y > center.y-boxSizeYWithoutOverlap) && (point.y <  center.y+boxSizeYWithoutOverlap) &&
    (point.z > center.z-boxSizeZWithoutOverlap) && (point.z < center.z+boxSizeZWithoutOverlap);

}

Point3 IndexBox::minCorner() {
    return _minCorner;
}

Point3 IndexBox::maxCorner() {
    return _maxCorner;
}

Point3 IndexBox::center() {
    return _center;
}

void IndexBox::setMinCorner(const Point3& minCorner){
    _minCorner = minCorner;
    _parameters[0] = minCorner;
}

void IndexBox::setMaxCorner(const Point3& maxCorner){
    _maxCorner = maxCorner;
    _parameters[0] = minCorner;
}

void IndexBox::setCenter(const Point3& center){
    _center = center;
}

void IndexBox::doesLineIntersectOptimized(const Point3 &origin, const Point3 &invertedDirection, int *sign) {
    float tmin, tmax, tymin, tymax, tzmin, tzmax;
    
    tmin = (_parameters[sign[0]].x - origin.x) * invertedDirection.x;
    tmax = (_parameters[1-sign[0]].x - origin.x) * invertedDirection.x;
    tymin = (_parameters[sign[1]].y - origin.y) * invertedDirection.y;
    tymax = (_parameters[1-sign[1]].y - origin.y) * invertedDirection.y;
    if ( (tmin > tymax) || (tymin > tmax) )
        return false;
    if (tymin > tmin)
        tmin = tymin;
    if (tymax < tmax)
        tmax = tymax;
    tzmin = (_parameters[sign[2]].z - origin.z) * invertedDirection.z;
    tzmax = (_parameters[1-sign[2]].z - origin.z) * invertedDirection.z;
    if ( (tmin > tzmax) || (tzmin > tmax) )
        return false;
    
    
    return true;

}

