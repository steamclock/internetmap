//
//  GlobeVisualization.cpp
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-31.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#include "GlobeVisualization.hpp"
#include "DisplayLines.hpp"
#include "MapDisplay.hpp"
#include <stdlib.h>

static bool sPortrait = false;

Point3 polarToCartesian(float latitude, float longitude, float radius) {
    // We want to build the globe so that the default rotation axis is between the poles, and North America is
    // facing the camera. Need slightly different contruction for landscape and portrait mode (due to different
    // camera rotations)
    if(sPortrait) {
        float x = radius * sin(latitude);
        float y = -radius * cos(latitude) * cos(longitude);
        float z = -radius * cos(latitude) * sin(longitude);
        return Point3(x, y, z);
    }
    else {
        float x = radius * cos(latitude) * cos(longitude);
        float y = radius * sin(latitude);
        float z = -radius * cos(latitude) * sin(longitude);
        return Point3(x, y, z);
    }
}

void GlobeVisualization::setPortrait(bool b) {
    sPortrait = b;
}

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
    
    return polarToCartesian(node->latitude, node->longitude, r);
}

Color GlobeVisualization::nodeColor(NodePointer node) {
    if(!node->hasLatLong) {
        return Color(0.3f, 0.3f, 0.3f, 1.0f);
    }

    return DefaultVisualization::nodeColor(node);
}

float GlobeVisualization::nodeSize(NodePointer node) {
    return 0.005 + 0.2 * powf(node->importance, .60);
}

void GlobeVisualization::updateLineDisplay(shared_ptr<MapDisplay> display, std::vector<ConnectionPointer>connections) {
    
    shared_ptr<DisplayLines> lines(new DisplayLines(20 * 20 + 20 * 20));
    
    int currentIndex = 0;
    
    float intensity = 0.2;
    
    lines->beginUpdate();
    
    for(int j = 0; j < 20; j++) {
        for(unsigned int i = 0; i < 20; i++) {
            float longitude = (float(j) * (M_PI / 10));
            float latitude = M_PI_2 + (float(i) * (M_PI / 20));
            float nextLatitude = M_PI_2 + (float(i+1) * (M_PI / 20));
            
            Color lineColorA = Color(intensity, intensity,intensity, 1.0);
            Color lineColorB = Color(intensity, intensity, intensity, 1.0);
            
            Point3 positionA = polarToCartesian(latitude, longitude, 1.1);
            Point3 positionB = polarToCartesian(nextLatitude, longitude, 1.1);
            
            lines->updateLine(currentIndex, positionA, lineColorA, positionB, lineColorB);
            currentIndex++;
        }
    }
    
    for(int j = 0; j < 20; j++) {
        for(unsigned int i = 0; i < 20; i++) {
            float longitude = (float(i) * (M_PI / 10));
            float nextLongitude = (float(i+1) * (M_PI / 10));
            float latitude = M_PI_2 + (float(j) * (M_PI / 20));
            
            Color lineColorA = Color(intensity, intensity,intensity, 1.0);
            Color lineColorB = Color(intensity, intensity, intensity, 1.0);

            if((j == 10) || (j==2) || (j==18)) {
                lineColorA = Color(0.4f, 0.4f, 0.4f, 1.0f);
                lineColorB = Color(0.4f, 0.4f, 0.4f, 1.0f);
            }
            Point3 positionA = polarToCartesian(latitude, longitude, 1.1);
            Point3 positionB = polarToCartesian(latitude, nextLongitude, 1.1);
            
            lines->updateLine(currentIndex, positionA, lineColorA, positionB, lineColorB);
            currentIndex++;
        }
    }
    
    lines->endUpdate();;
    
    display->visualizationLines = lines;
}

