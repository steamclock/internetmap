//
//  NodeWrapper.m
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "NodeWrapper.h"
#include "Node.hpp"

@interface NodeWrapper ()

@property (nonatomic, readwrite, assign) NodePointer node;

@end

@implementation NodeWrapper

- (id)init {
    if (self = [super init]) {
        _node = NodePointer(new Node());
    }

    return self;
}

-(id)initWithNodePointer:(NodePointer)node {
    if (self = [super init]) {
        _node = node;
    }
    return self;
}

- (NSString*)asn {
    return [NSString stringWithUTF8String:_node->asn.c_str()];
}

- (NSString*)textDescription {
    return [NSString stringWithUTF8String:_node->textDescription.c_str()];
}

- (NSString*)typeString {
    return [NSString stringWithUTF8String:_node->typeString.c_str()];
}

- (int)index {
    return _node->index;
}

- (float)importance {
    return _node->importance;
}

- (int)numberOfConnections {
    return _node->connections.size();
}

- (void)setAsn:(NSString *)asn {
    _node->asn = std::string([asn UTF8String]);
}

- (void)setTextDescription:(NSString *)textDescription {
    _node->textDescription = std::string([textDescription UTF8String]);
}

- (void)setTypeString:(NSString *)typeString {
    _node->typeString = std::string([typeString UTF8String]);
}

- (void)setIndex:(int)index {
    _node->index = index;
}

- (void)setImportance:(float)importance {
    _node->importance = importance;
}

@end
