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

@property (nonatomic, readwrite, assign) Node* node;

@end

@implementation NodeWrapper

- (id)init {
    if (self = [super init]) {
        _node = new Node();
    }

    return self;
}

@end
