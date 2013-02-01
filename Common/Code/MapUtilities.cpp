//
//  MapUtilities.cpp
//  InternetMap
//
//  Created by Alexander on 14.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#include "MapUtilities.hpp"


Point3 MapUtilities::pointOnSurfaceOfNode(float nodeSize, const Point3& centeredAt, const Point3& connectedToPoint) {
    
    float lineLength = Vectormath::Aos::dist(centeredAt, connectedToPoint);
    
    //0.45 is magic number for showing connections from a deep node
    float nodeRatio = 0.32; // Magic number to scale from node size to line length
    
    float offsetRatio = nodeRatio * nodeSize / lineLength;
    return Vectormath::Aos::lerp(offsetRatio, centeredAt, connectedToPoint);
}