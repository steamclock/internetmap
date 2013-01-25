//
//  SCTracerouteUtility.m
//  
// -- Software License --
//
// Copyright (C) 2013, Steam Clock Software, Ltd.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// ----------------------

#import "SCTracerouteUtility.h"
#import "SCIcmpPacketUtility.h"
#import "SCPacketRecord.h"

@interface SCTracerouteUtility ()

@property (nonatomic, strong) SCIcmpPacketUtility* packetUtility;
@property int ttlCount;
@property int timesExceededForHop;
@property int totalHopsTimedOut; // If we hit 4, bail, otherwise it's boring for the user.

@property (nonatomic, strong) NSString *targetIP;
@property (nonatomic, strong) NSString *lastIP;
@property (nonatomic, strong) NSMutableArray  *hopsForCurrentIP;

@end

@implementation SCTracerouteUtility

#pragma mark - Class Methods
+(SCTracerouteUtility*)tracerouteWithAddress:(NSString*)address{
    assert(![address isEqualToString:@""]);
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
        self.targetIP = hostAddress;
        self.hopsForCurrentIP = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - Start/Stop the Traceroute

-(void)start{
    if (!self.packetUtility) {
        self.packetUtility = [SCIcmpPacketUtility utilityWithHostAddress:self.targetIP];
        self.packetUtility.delegate = self;
    }
    [self.packetUtility start];
}
-(void)stop{
    self.ttlCount = 1;
    [self.packetUtility stop];
    self.packetUtility = nil;
}


#pragma mark - Send packets
- (void)sendPackets:(NSData*)data{
    
    //NSLog(@"Sending a batch of packets..");
    if (self.ttlCount <= MAX_HOPS) {
        for (int i = 1; i <= PACKETS_PER_ITER; i++) {
            [self.packetUtility sendPacketWithData:nil andTTL:self.ttlCount];
        }   
    } else if (self.ttlCount > MAX_HOPS) {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidTimeout)]) {
            [self.delegate tracerouteDidTimeout];
        }
    }
}


-(void)debugPacket:(NSData*)packet{
    //Nab IPHeader
    const IPHeader* IPHeader = (const struct IPHeader *) ((const uint8_t *)[packet bytes]);
    
    //Nab ICMP Header
    const ICMPHeader* header = [SCIcmpPacketUtility icmpInPacket:packet];
    NSInteger type = (NSInteger)header->type;
    NSInteger code = (NSInteger)header->code;
    
    NSLog(@"Packet for IP: %@", [NSString stringWithFormat:@"%d.%d.%d.%d", IPHeader->sourceAddress[0], IPHeader->sourceAddress[1], IPHeader->sourceAddress[3], IPHeader->sourceAddress[4]]);
    NSLog(@"ICMP Type: %d and Code: %d", type, code);
}

#pragma mark - Process packets

-(int)processICMPPacket:(NSData *)packet{
    const ICMPHeader* header = [SCIcmpPacketUtility icmpInPacket:packet];
    NSInteger type = (NSInteger)header->type;
    
    if (type == kICMPTimeExceeded) {
        return kICMPTimeExceeded;
    } else if (type == kICMPTypeEchoReply) {
        return kICMPTypeEchoReply;
    } else {
        return kICMPTypeDestinationUnreachable;
    }
}


-(void)processErrorICMPPacket:(NSData *)packet arrivedAt:(NSDate*)dateTime{
    
    // Get sequence number
    NSInteger sequenceNumber = [self getSequenceNumberForPacket:packet];
    
    //Get IP for machine the packet originated from
    NSString* ipInPacket = [self getIpFromIPHeader:packet];
    
    //Tracks number of packets we've received that are from the same IP
    int numberOfRepliesForIP = 0;    
    //If we have a packet record with a response address that matches our IP, then we increment our number of replies
    for (SCPacketRecord* packetRecord in self.packetUtility.packetRecords) {
        if ([packetRecord.responseAddress isEqualToString:ipInPacket]) {
            numberOfRepliesForIP++;
        }
    }
    
    //Check if the sequence number matches for any packetrecord that we have
    for (SCPacketRecord* packetRecord in self.packetUtility.packetRecords) {

        if ((packetRecord.sequenceNumber == sequenceNumber) && !packetRecord.timedOut) {
            // If the sequence numbers match, record the time the packet arrived & rtt
            packetRecord.arrival = dateTime;
            packetRecord.rtt = [packetRecord.arrival timeIntervalSinceDate:packetRecord.departure] * 1000;
            packetRecord.responseAddress = ipInPacket;
            
            if (numberOfRepliesForIP == 0) {
                
                [self foundNewIP:ipInPacket withReport:[NSString stringWithFormat:@"%d: %@  %.2fms", self.ttlCount, ipInPacket, packetRecord.rtt]];
                
                if ([ipInPacket isEqualToString:self.targetIP]) {
                    // We're done the traceroute! Woo. 
                    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidComplete:)]) {
                        NSArray* hops = self.hopsForCurrentIP;
                        [self.delegate tracerouteDidComplete:hops];
                    }
                    break;
                }
            }
        }
    }
    
    if (numberOfRepliesForIP == 2) {
        // If we got back all three packets, that's great
        self.ttlCount++;
        [self sendPackets:nil];
    }
}
-(void)timeExceededForPacket:(NSData*)packet {
    NSInteger sequenceNumber = [self getSequenceNumberForPacket:packet];
    int numberOfTimeoutsForIP = 0;
    for (SCPacketRecord* packetRecord in [self.packetUtility.packetRecords copy]) {
        if (packetRecord.sequenceNumber == sequenceNumber) {
            packetRecord.timedOut = YES;
        }
        
        if (packetRecord.timedOut) {
            numberOfTimeoutsForIP++;
        }
    }
    
    if (numberOfTimeoutsForIP > 2) {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:withHops:)]) {
            NSArray* hops = self.hopsForCurrentIP;
            [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: * * * Hop did not reply or timed out.", self.ttlCount] withHops:hops];
            self.totalHopsTimedOut++;
            
            //Send m0ar packets?
            self.ttlCount++;
            [self sendPackets:nil];
        }
        
        if (self.totalHopsTimedOut >= 3) {
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidTimeout)]) {
                [self.delegate tracerouteDidTimeout];
            }
        }
    }
}

-(void)foundNewIP:(NSString*)ip withReport:(NSString*)report{
    [self.hopsForCurrentIP addObject:ip];
    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:withHops:)]) {
        NSArray* hops = self.hopsForCurrentIP;
        [self.delegate tracerouteDidFindHop:report withHops:hops];
    }
}

-(NSInteger)getSequenceNumberForPacket:(NSData*)packet{
    
    NSInteger sequenceNumber = 0;
    const ICMPHeader* header = [SCIcmpPacketUtility icmpInPacket:packet];
    NSInteger type = (NSInteger)header->type;
    
    if (type == kICMPTypeEchoRequest) {
        // This was a packet we sent, probably it timed out
        sequenceNumber = CFSwapInt16BigToHost(header->sequenceNumber);
    } else if (type == kICMPTimeExceeded) {
        const ICMPErrorPacket* errorPacket = (const struct ICMPErrorPacket *)[packet bytes];
        sequenceNumber = CFSwapInt16BigToHost(errorPacket->sequenceNumberOriginal);
    }
    return sequenceNumber;
}

-(NSString*)getIpFromIPHeader:(NSData*)packet{
    const IPHeader* IPHeader = (const struct IPHeader *) ((const uint8_t *)[packet bytes]);
    NSString* ip = [NSString stringWithFormat:@"%d.%d.%d.%d", IPHeader->sourceAddress[0], IPHeader->sourceAddress[1], IPHeader->sourceAddress[3], IPHeader->sourceAddress[4]];
    return ip;
}


#pragma mark - SCIcmpPacketUtility Delegate Methods

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didStartWithAddress:(NSData *)address{
    NSLog(@"ICMP Packet Utility Ready.");
    [self sendPackets:nil];
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didSendPacket:(NSData *)packet{
    
    //If we just don't get ANY packets back after a whole two seconds, bail on the hop
    [self performSelector:@selector(timeExceededForPacket:) withObject:packet afterDelay:0.5];
    
    
}

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didReceiveResponsePacket:(NSData *)packet arrivedAt:(NSDate *)dateTime{
    
    // If we have even one packet, we don't have an outright failure/timeout ...yet?
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // Check what kind of packet from header
    int typeOfPacket = [self processICMPPacket:packet];
    
    if (typeOfPacket == kICMPTimeExceeded) {
        [self processErrorICMPPacket:packet arrivedAt:dateTime];
    } else if (typeOfPacket == kICMPTypeEchoReply) {
        // Check if we've reached our final destination
    } else if (typeOfPacket == kICMPTypeDestinationUnreachable){
        NSLog(@"Destination unreachable");
        [self processErrorICMPPacket:packet arrivedAt:dateTime];
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
