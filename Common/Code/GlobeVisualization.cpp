//
//  GlobeVisualization.cpp
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-31.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#include "GlobeVisualization.hpp"

Point3 GlobeVisualization::nodePosition(NodePointer node) {
    float zenith = node->positionX * M_PI;
    float azimuth = node->positionY * M_PI;
    float radius = 1.5f;
    
    return Point3(radius * sin(zenith) * cos(azimuth), radius * sin(zenith) * sin(azimuth), radius * cos(zenith) );
}
