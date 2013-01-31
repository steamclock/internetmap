//
//  TypeVisualization.cpp
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-30.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#include "TypeVisualization.hpp"

TypeVisualization::TypeVisualization(const std::string& name, int typeToHighlight) :
    _typeToHighlight(typeToHighlight),
    _name(name)
{
    
}

Color TypeVisualization::nodeColor(NodePointer node) {
    if(node->type == _typeToHighlight) {
        return DefaultVisualization::nodeColor(node);
    }
    
    return Color(0.3f, 0.3f, 0.3f, 1.0f);
}
