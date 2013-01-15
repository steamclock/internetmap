//
//  NodeWrapper.h
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NodeWrapper : NSObject

@property (nonatomic) NSString* asn;
@property (nonatomic) NSString* textDescription;
@property (nonatomic) NSString* typeString;
@property (nonatomic) int index;
@property (nonatomic) float importance;
@property (nonatomic, readonly) int numberOfConnections;

@end
