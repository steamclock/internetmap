//
//  GlobeVisualization.h
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-31.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#ifndef __InternetMap__GlobeVisualization__
#define __InternetMap__GlobeVisualization__

#include "DefaultVisualization.hpp"

class GlobeVisualization : public DefaultVisualization {
public:
    void activate(std::vector<NodePointer> nodes);

    virtual Point3 nodePosition(NodePointer node);
    virtual Color nodeColor(NodePointer node);
    
    virtual std::string name(void) { return "Globe"; }
};

#endif /* defined(__InternetMap__GlobeVisualization__) */
