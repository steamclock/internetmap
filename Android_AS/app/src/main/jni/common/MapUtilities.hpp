//
//  MapUtilities.h
//  InternetMap
//
//  Created by Alexander on 14.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#ifndef __InternetMap__MapUtilities__
#define __InternetMap__MapUtilities__

#include "Types.hpp"
#include "Node.hpp"

class MapUtilities {

public:
    static Point3 pointOnSurfaceOfNode(float nodeSize, const Point3& centeredAt, const Point3& connectedToPoint);
};

#endif /* defined(__InternetMap__MapUtilities__) */
