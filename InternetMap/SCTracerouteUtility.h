//
//  SCTracerouteUtility.h
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCIcmpPacketUtility.h"

static const int MAX_HOPS = 30;
static const int PACKETS_PER_ITER = 3; // How many packets we send each time we increase the TTL

@protocol SCTracerouteUtilityDelegate <NSObject>

- (void)tracerouteDidFindHop:(NSString*)report withHops:(NSArray*)hops;
- (void)tracerouteDidComplete:(NSArray*)hops;
- (void)tracerouteDidTimeout;

@end

@interface SCTracerouteUtility : NSObject <SCIcmpPacketUtilityDelegate>

@property (weak, nonatomic) id<SCTracerouteUtilityDelegate> delegate;

+(SCTracerouteUtility*)tracerouteWithAddress:(NSString*)address; //Pass me an IP as a string

-(void)start;
-(void)stop;


@end
