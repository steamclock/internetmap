//
//  GlobeVisualization.cpp
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-31.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#include "GlobeVisualization.hpp"
#include <stdlib.h>

void GlobeVisualization::activate(std::vector<NodePointer> nodes) {
    srand(81531);
    
    for(unsigned int i = 0; i < nodes.size(); i++) {
#if 0
        nodes[i]->visualizationActive = true;
#else
        nodes[i]->visualizationActive = nodes[i]->hasLatLong;
#endif
    }
}

float unitRandom() {
    return float(rand()) / float(RAND_MAX);
}

Point3 GlobeVisualization::nodePosition(NodePointer node) {
    float r;
    
    if(!node->hasLatLong && (node->latitude == 0.0f) && (node->longitude == 0.0f)) {
        node->latitude = (2 * M_PI) * unitRandom();
        node->longitude = acos(2.0f * unitRandom() - 1.0f);
    }
    
    r = node->hasLatLong ? 1.1f : 1.0f;
    
    float x = r * cos(node->latitude) * cos(node->longitude);
    float y = r * cos(node->latitude) * sin(node->longitude);
    float z = r * sin(node->latitude);
    return Point3(x, y, z);
}

Color GlobeVisualization::nodeColor(NodePointer node) {
    if(!node->hasLatLong) {
        return Color(0.3f, 0.3f, 0.3f, 1.0f);
    }

    return DefaultVisualization::nodeColor(node);
}
