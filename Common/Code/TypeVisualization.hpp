//
//  TypeVisualization.h
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-30.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#ifndef __InternetMap__TypeVisualization__
#define __InternetMap__TypeVisualization__

#include "DefaultVisualization.hpp"

class TypeVisualization : public DefaultVisualization {
public:
    TypeVisualization(int typeToHighlight);
    virtual Color nodeColor(NodePointer node);
    
private:
    int _typeToHighlight;
};

#endif /* defined(__InternetMap__TypeVisualization__) */
