//
//  SCTracerouteUtility.m
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "SCTracerouteUtility.h"
#import "SCIcmpPacketUtility.h"

@interface SCTracerouteUtility ()

@property (nonatomic, strong) SCIcmpPacketUtility* packetUtility;
@property int ttlCount;

@property int totalHopsTimedOut; // If we hit 4, bail, otherwise it's boring for the user.

@property (nonatomic, strong) NSString *targetIP;
@property (nonatomic, strong) NSString *lastIP;

@end

@implementation SCTracerouteUtility

#pragma mark - Class Methods
+(SCTracerouteUtility*)tracerouteWithAddress:(NSString*)address{
    return [[SCTracerouteUtility alloc] initWithAddress:address];
}


#pragma mark - Instance Methods

- (id)initWithAddress:(NSString *)hostAddress
{
    self = [super init];
    if (self != nil) {
        self.ttlCount = 1;
        self.packetUtility = [SCIcmpPacketUtility utilityWithHostAddress:hostAddress];
        self.packetUtility.delegate = self;
    }
    return self;
}

-(void)start{
    [self.packetUtility start];   
}
-(void)stop{
    self.ttlCount = 1;
    [self.packetUtility stop];
}

#pragma mark - SCIcmpPacketUtility Delegate Methods

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didStartWithAddress:(NSData *)address{
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didSendPacket:(NSData *)packet{
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didReceiveResponsePacket:(NSData *)packet{
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didReceiveUnexpectedPacket:(NSData *)packet{
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didFailToSendPacket:(NSData *)packet error:(NSError *)error{
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didFailWithError:(NSError *)error{
    
}

@end
