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

@protocol SCTracerouteDelegate <NSObject>

- (void)tracerouteDidFindHop:(NSString*)report withHops:(NSArray*)hops;
- (void)tracerouteDidComplete:(NSArray*)hops;
- (void)tracerouteDidTimeout;

@end

@interface SCTracerouteUtility : NSObject <SCIcmpPacketUtilityDelegate>

@property (weak, nonatomic) id<SCTracerouteDelegate> delegate;

+(SCTracerouteUtility*)tracerouteWithAddress:(NSString*)address; //Pass me an IP as a string

-(void)start;
-(void)stop;


@end
