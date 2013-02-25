//
//  IndexBox.h
//  InternetMap
//
//  Created by Alexander on 11.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#ifndef InternetMap_IndexBox_hpp
#define InternetMap_IndexBox_hpp

#include "Types.hpp"
#include <set>

static const float IndexBoxMinX = -8;
static const float IndexBoxMaxX = 8;
static const float IndexBoxMinY = -2.1;
static const float IndexBoxMaxY = 2.1;
static const float IndexBoxMinZ = -2.1;
static const float IndexBoxMaxZ = 2.1;
static const float lengthX = -IndexBoxMinX + IndexBoxMaxX;
static const float lengthY = -IndexBoxMinY + IndexBoxMaxY;
static const float lengthZ = -IndexBoxMinZ + IndexBoxMaxZ;

static const int numberOfCellsX = 32;
static const int numberOfCellsY = 4;
static const int numberOfCellsZ = 4;
static const float boxSizeXWithoutOverlap = lengthX/numberOfCellsX;
static const float boxSizeYWithoutOverlap = lengthY/numberOfCellsY;
static const float boxSizeZWithoutOverlap = lengthZ/numberOfCellsZ;

class IndexBox {
    Point3 _parameters[2];
    Point3 _center;
    Point3 _minCorner;
    Point3 _maxCorner;
    
public:

    std::set<int> indices;
    
    bool isPointInside(const Point3& point);
    bool doesLineIntersectOptimized(const Vector3& origin, const Vector3& invertedDirection, int* sign);
    
    Point3 minCorner();
    Point3 maxCorner();
    Point3 center();
    void setMinCorner(const Point3& minCorner);
    void setMaxCorner(const Point3& maxCorner);
    void setCenter(const Point3& center);
};

typedef shared_ptr<IndexBox> IndexBoxPointer;

#endif
