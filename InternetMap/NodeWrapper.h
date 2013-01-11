//
//  NodeWrapper.h
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NodeWrapper : NSObject

@property (nonatomic, readonly) NSString* asn;
@property (nonatomic, readonly) NSString* textDescription;
@property (nonatomic, readonly) NSString* typeString;
@property (nonatomic, readonly) int index;
@property (nonatomic, readonly) float importance;
@property (nonatomic, readonly) int numberOfConnections;

@end
