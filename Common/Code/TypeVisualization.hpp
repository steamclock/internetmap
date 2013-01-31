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
    TypeVisualization(const std::string& name, int typeToHighlight);
    
    virtual Color nodeColor(NodePointer node);
    
    virtual std::string name(void) { return _name; }
    
private:
    int _typeToHighlight;
    std::string _name;
};

#endif /* defined(__InternetMap__TypeVisualization__) */
