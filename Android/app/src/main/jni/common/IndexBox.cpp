//
//  IndexBox.m
//  InternetMap
//
//  Created by Alexander on 11.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#include "IndexBox.hpp"

bool IndexBox::isPointInside(const Point3& point) {
    return (point.getX() > _center.getX()-boxSizeXWithoutOverlap) && (point.getX() < _center.getX()+boxSizeXWithoutOverlap) &&
    (point.getY() > _center.getY()-boxSizeYWithoutOverlap) && (point.getY() <  _center.getY()+boxSizeYWithoutOverlap) &&
    (point.getZ() > _center.getZ()-boxSizeZWithoutOverlap) && (point.getZ() < _center.getZ()+boxSizeZWithoutOverlap);

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
    _parameters[1] = maxCorner;
}

void IndexBox::setCenter(const Point3& center){
    _center = center;
}

bool IndexBox::doesLineIntersectOptimized(const Vector3 &origin, const Vector3 &invertedDirection, int *sign) {
    float tmin, tmax, tymin, tymax, tzmin, tzmax;
    
    tmin = (_parameters[sign[0]].getX() - origin.getX()) * invertedDirection.getX();
    tmax = (_parameters[1-sign[0]].getX() - origin.getX()) * invertedDirection.getX();
    tymin = (_parameters[sign[1]].getY() - origin.getY()) * invertedDirection.getY();
    tymax = (_parameters[1-sign[1]].getY() - origin.getY()) * invertedDirection.getY();
    if ( (tmin > tymax) || (tymin > tmax) )
        return false;
    if (tymin > tmin)
        tmin = tymin;
    if (tymax < tmax)
        tmax = tymax;
    tzmin = (_parameters[sign[2]].getZ() - origin.getZ()) * invertedDirection.getZ();
    tzmax = (_parameters[1-sign[2]].getZ() - origin.getZ()) * invertedDirection.getZ();
    if ( (tmin > tzmax) || (tzmin > tmax) )
        return false;
    
    
    return true;

}

