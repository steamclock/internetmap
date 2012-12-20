//
//  SCTraceroute.h
//  SCTraceroute
//
//  Created by Angelina Fabbro on 12-12-09.
//  Copyright (c) 2012 Steamclock Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCPacketUtility.h"

static const int MAX_HOPS = 30;

@protocol SCTracerouteDelegate <NSObject>

- (void)tracerouteDidFindHop:(NSString*)report withHops:(NSArray*)hops;
- (void)tracerouteDidComplete:(NSArray*)hops;
- (void)tracerouteDidTimeout;

@end

@interface SCTraceroute : NSObject <SCPacketUtilityDelegate>

@property (weak, nonatomic) id<SCTracerouteDelegate> delegate;

+(SCTraceroute*)tracerouteWithHostName:(NSString*)hostname ofType:(packetType)type;
+(SCTraceroute*)tracerouteWithAddress:(NSString*)address ofType:(packetType)type; //Pass me an IP as a string

-(void)start;
-(void)stop;

@end
