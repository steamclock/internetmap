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
#include "MapUtilities.hpp"
#include <stdlib.h>

Point3 polarToCartesian(float latitude, float longitude, float radius) {
    float x = radius * cos(latitude) * cos(longitude);
    float y = radius * sin(latitude);
    float z = -radius * cos(latitude) * sin(longitude);
    return Point3(x, y, z);
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
    return DefaultVisualization::sNodeScale * (0.005 + 0.2 * powf(node->importance, .90));
}

void GlobeVisualization::updateLineDisplay(shared_ptr<MapDisplay> display) {
    
    shared_ptr<DisplayLines> lines(new DisplayLines(20 * 20 + 20 * 20));
    
    int currentIndex = 0;
    
    float intensity = 0.12;
    float highlightIntensity = 0.17;
    
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

            // Equator and artic circle get a little brightness bump
            if((j == 10) || (j==2) || (j==18)) {
                lineColorA = Color(highlightIntensity, highlightIntensity, highlightIntensity, 1.0f);
                lineColorB = Color(highlightIntensity, highlightIntensity, highlightIntensity, 1.0f);
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

void GlobeVisualization::updateHighlightRouteLines(shared_ptr<MapDisplay> display, std::vector<NodePointer> nodeList) {
    int numSubdiv = 30;
    float radius = length(Vector3(nodePosition(nodeList[0])));
    float maxElevation = 0.0f;//radius * 0.25;

    shared_ptr<DisplayLines> lines(new DisplayLines(static_cast<int>(nodeList.size() - 1) * numSubdiv));
    lines->beginUpdate();
    Color lineColor = ColorFromRGB(ROUTE_COLOR);

    for(unsigned int i = 0; i < nodeList.size() - 1; i++) {
        NodePointer a = nodeList[i];
        NodePointer b = nodeList[i+1];

        Point3 start = nodePosition(a);
        Point3 end = nodePosition(b);
        Point3 lastSubdivPoint = start;
        float segmentElevation = fmin(maxElevation * (length(start - end) / radius), maxElevation);

        for(unsigned int j = 0; j < numSubdiv; j++) {
            float t = float(j + 1) / float(numSubdiv);
            Vector3 newSubdivVector = normalize(Vector3(lerp(t, start, end)));
            float elevation = radius + (segmentElevation * (1.414f * sqrt(0.5 - fabs(t - 0.5)) ));
            Point3 newSubdivPoint = scale(Point3(newSubdivVector), elevation);
            lines->updateLine((i * numSubdiv) + j, lastSubdivPoint, lineColor, newSubdivPoint, lineColor);
            lastSubdivPoint = newSubdivPoint;
        }
    }

    lines->endUpdate();
    lines->setWidth(5.0);

    display->highlightLines = lines;
}

void GlobeVisualization::updateConnectionLines(shared_ptr<MapDisplay> display, NodePointer node, std::vector<ConnectionPointer> connections) {
    int numSubdiv = 30;
    float radius = length(Vector3(nodePosition(node)));


    shared_ptr<DisplayLines> lines(new DisplayLines(connections.size() * numSubdiv));
    lines->beginUpdate();

    Color selfColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_SELF_HEX);
    Color otherColor = ColorFromRGB(SELECTED_CONNECTION_COLOR_OTHER_HEX);

    for(unsigned int i = 0; i < connections.size(); i++) {
        ConnectionPointer connection = connections[i];
        NodePointer a = connection->first;
        NodePointer b = connection->second;

        if(node == b) {
            b = a;
            a = node;
        }

        // Draw lines from outside of nodes instead of center
        Point3 positionA = nodePosition(a);
        Point3 positionB = nodePosition(b);

        Point3 start = MapUtilities().pointOnSurfaceOfNode(nodeSize(a), positionA, positionB);
        Point3 end = MapUtilities().pointOnSurfaceOfNode(nodeSize(b), positionB, positionA);

        Point3 lastSubdivPoint = start;
        Color lastSubdivColor = selfColor;

        for(unsigned int j = 0; j < numSubdiv; j++) {
            float t = float(j + 1) / float(numSubdiv);
            Vector3 newSubdivVector = normalize(Vector3(lerp(t, start, end)));
            Point3 newSubdivPoint = scale(Point3(newSubdivVector), radius);
            Color newSubdivColor = Color(selfColor.r + ((otherColor.r - selfColor.r) * t), selfColor.g + ((otherColor.g - selfColor.g) * t), selfColor.b + ((otherColor.b - selfColor.b) * t), selfColor.a + ((otherColor.a - selfColor.a) * t));
            lines->updateLine((i * numSubdiv) + j, lastSubdivPoint, lastSubdivColor, newSubdivPoint, newSubdivColor);
            lastSubdivPoint = newSubdivPoint;
            lastSubdivColor = newSubdivColor;
        }
    }

    lines->endUpdate();
    lines->setWidth(((connections.size() < 20) ? 2 : 1));
    display->highlightLines = lines;
}
