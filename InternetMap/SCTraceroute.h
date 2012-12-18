//
//  SCTraceroute.h
//  SCTraceroute
//
//  Created by Angelina Fabbro on 12-12-09.
//  Copyright (c) 2012 Steamclock Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCPacketUtility.h"

@protocol SCTracerouteDelegate <NSObject>

- (void)tracerouteDidFindHop:(NSString*)report;
- (void)tracerouteDidComplete:(NSMutableArray*)hops;

@end

@interface SCTraceroute : NSObject <SCPacketUtilityDelegate>

@property (weak, nonatomic) id<SCTracerouteDelegate> delegate;

+(SCTraceroute*)tracerouteWithHostName:(NSString*)hostname ofType:(packetType)type;
+(SCTraceroute*)tracerouteWithAddress:(NSString*)address ofType:(packetType)type; //Pass me an IP as a string

-(void)start;
-(void)stop;

@end
