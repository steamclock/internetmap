//
//  SCTracerouteUtility.m
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "SCTracerouteUtility.h"
#import "SCIcmpPacketUtility.h"
#import "SCPacketRecord.h"

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


#pragma mark - Start/Stop the Traceroute

-(void)start{
    [self.packetUtility start];   
}
-(void)stop{
    self.ttlCount = 1;
    [self.packetUtility stop];
}


#pragma mark - Send packets
- (void)sendPackets:(NSData*)data{
    if (self.ttlCount <= MAX_HOPS) {
        for (int i = 0; i <= PACKETS_PER_ITER; i++) {
            [self.packetUtility sendPacketWithData:nil andTTL:self.ttlCount];
        }   
    } else if (self.ttlCount > MAX_HOPS) {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidTimeout)]) {
            [self.delegate tracerouteDidTimeout];
        }
    }
}


#pragma mark - Process packets

-(int)processICMPPacket:(NSData *)packet{
    //Nab IPHeader
    const IPHeader* IPHeader = (const struct IPHeader *) ((const uint8_t *)[packet bytes]);
    
    //Nab ICMP Header
    const ICMPHeader* header = [SCIcmpPacketUtility icmpInPacket:packet];
    NSInteger type = (NSInteger)header->type;
    NSInteger code = (NSInteger)header->code;
    
    //Store last IP
    self.lastIP = [NSString stringWithFormat:@"%d.%d.%d.%d", IPHeader->sourceAddress[0], IPHeader->sourceAddress[1], IPHeader->sourceAddress[3], IPHeader->sourceAddress[4]];
    if (type == kICMPTimeExceeded) {
        return kICMPTimeExceeded;
    } else if (type == kICMPTypeEchoReply) {
        return kICMPTypeEchoReply;
    } else {
        // Everything else we don't want
        // TODO handle type 3 code 1 better (machine unreachable)
        NSLog(@"Something is wrong, and we can't continue.");
        NSLog(@"ICMP Type: %d and Code: %d", type, code);
        return -1;
    }
}

-(void)processErrorICMPPacket:(NSData *)packet arrivedAt:(NSDate*)dateTime{
    // Use ICMP error packet structure rather than valid response structure
    const ICMPErrorPacket* errorPacket = (const struct ICMPErrorPacket *)[packet bytes];
    
    // Get sequence number to calculate RTT
    NSInteger sequenceNumber = CFSwapInt16BigToHost(errorPacket->sequenceNumberOriginal);

    // If the sequence numbers match, record the time the packet arrived & rtt
    for (SCPacketRecord* packetRecord in self.packetUtility.packetRecords) {
        if (packetRecord.sequenceNumber == sequenceNumber) {
            packetRecord.arrival = dateTime;
            [self calculateResponseTimeForSequence:sequenceNumber];
        }
    }
    
}

-(void)calculateResponseTimeForSequence:(NSInteger)sequenceNumber{
    for (SCPacketRecord* packetRecord in self.packetUtility.packetRecords) {
        if (packetRecord.sequenceNumber == sequenceNumber) {
            // If we sent a packet with a corresponding sequence number, let's calculate the RTT
            packetRecord.rtt = [packetRecord.arrival timeIntervalSinceDate:packetRecord.departure] * 1000;
        }
    }
}


#pragma mark - SCIcmpPacketUtility Delegate Methods

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didStartWithAddress:(NSData *)address{
    [self sendPackets:nil];
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didSendPacket:(NSData *)packet{
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didReceiveResponsePacket:(NSData *)packet arrivedAt:(NSDate *)dateTime{
    // Check what kind of packet from header
    
    int typeOfPacket = [self processICMPPacket:packet];
    
    if (typeOfPacket == kICMPTimeExceeded) {
        [self processErrorICMPPacket:packet arrivedAt:dateTime];
    } else if (typeOfPacket == kICMPTypeEchoReply) {
        // Check if we've reached our final destination
    } else {
        NSLog(@"What should happen here?");
    }
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didReceiveUnexpectedPacket:(NSData *)packet{
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didFailToSendPacket:(NSData *)packet error:(NSError *)error{
	NSLog(@"ERROR: %@", error);
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didFailWithError:(NSError *)error{
	NSLog(@"ERROR: %@", error);    
}

@end
