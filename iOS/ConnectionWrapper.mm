//
//  ConnectionWrapper.m
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "ConnectionWrapper.h"
#include "Connection.hpp"

@interface ConnectionWrapper ()

@property (nonatomic, readwrite, assign) Connection* connection;

@end

@implementation ConnectionWrapper

- (id)init {
    if (self = [super init]) {
        _connection = new Connection();
    }
    
    return self;
}

@end
