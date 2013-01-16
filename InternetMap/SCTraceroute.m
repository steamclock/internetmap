//
//  SCTraceroute.m
//  SCTraceroute
//
//  Created by Angelina Fabbro on 12-12-09.
//  Copyright (c) 2012 Steamclock Software. All rights reserved.
//

#import "SCTraceroute.h"
#import "SCPacketUtility.h"
#include <netinet/in.h>
#include <arpa/inet.h>

@interface SCTraceroute ()

@property (nonatomic, strong) SCPacketUtility* packetUtility;
@property int ttlCount;
@property int timeExceededCount;
@property int totalResponsesForHop;
@property int totalHopsTimedOut; // If we hit 4, bail, otherwise it's boring for the user.
@property (nonatomic, strong) NSString *targetIP;
@property (nonatomic, strong) NSString *lastIP;
@property (nonatomic, strong )NSMutableArray *ipsForCurrentRequest;
@property packetType currentTracerouteType;


@end

@implementation SCTraceroute

//We init with 
- (id)initWithAddress:(NSString *)hostAddress andPacketType:(packetType)type
{
    self = [super init];
    if (self != nil) {
        NSData *address = [self formatAddress:hostAddress];
        self.packetUtility = [SCPacketUtility utilityWithHostAddress:address];
        self.packetUtility.delegate = self;
        self.currentTracerouteType = type;
        
    }
    return self;
}

- (id)initWithHostName:(NSString*)hostName andPacketType:(packetType)type{
    
    self = [super init];
    if (self != nil) {
        self.packetUtility = [SCPacketUtility utilityWithHostName:hostName];
        self.packetUtility.delegate = self;
        self.currentTracerouteType = type;
    }
    return self;
}

- (NSData*)formatAddress:(NSString*)address{
    self.targetIP = address;
    const char *ipstring = [address UTF8String];
    struct sockaddr_in ip;
    inet_aton(ipstring, &ip.sin_addr);
    ip.sin_family = AF_INET;
    NSData* hostAddress = [NSData dataWithBytes:&ip length:sizeof(ip)];
    return hostAddress;
}


+ (SCTraceroute*)tracerouteWithAddress:(NSString*)address ofType:(packetType)type
{
    return [[SCTraceroute alloc] initWithAddress:address andPacketType:type];
}

+(SCTraceroute*)tracerouteWithHostName:(NSString*)hostname ofType:(packetType)type{
    return [[SCTraceroute alloc] initWithHostName:hostname andPacketType:type];
}

#pragma Start/Stop

-(void)start{
    self.ttlCount = 1;
    self.timeExceededCount = 0;
    self.totalResponsesForHop = 0;
    self.ipsForCurrentRequest = [[NSMutableArray alloc] init];
    [self.packetUtility start];
}

-(BOOL)reachedTargetAddress{
    if ([self.targetIP isEqualToString:self.lastIP]) {
        return YES;
    } else {
        return NO;
    }
}

-(void)stop{
    [self.packetUtility stop];
}

#pragma mark - ICMP Traceroute

-(void)processICMPPacket:(NSData *)packet{
    
    //TODO: This is a really long function, compartmentalize a bit and factor portions into their own functions

    //Nab IPHeader
    const IPHeader* IPHeader = (const struct IPHeader *) ((const uint8_t *)[packet bytes]);
    
    //Nab ICMP Header
    const ICMPHeader* header = [SCPacketUtility icmpInPacket:packet];
    NSInteger type = (NSInteger)header->type;
    NSInteger code = (NSInteger)header->code;
    
    //  NSLog(@"ICMP Type: %d and Code: %d with sequenceNumber: %d", type, code, (NSInteger)sequenceNumber);
    
    //Store last IP
    self.lastIP = [NSString stringWithFormat:@"%d.%d.%d.%d", IPHeader->sourceAddress[0], IPHeader->sourceAddress[1], IPHeader->sourceAddress[3], IPHeader->sourceAddress[4]];

    if (type == kICMPTimeExceeded) {
        //TTL Expired, error packet friend
        [self processErrorICMPPacket:packet];
        
    } else if (type == kICMPTypeEchoReply) {
        //ECHO Response - final hop
        [self processValidICMPPacket:packet];

     } else {
        //Everything else we don't want
         // TODO handle type 3 code 1 better (machine unreachable)
        
        NSLog(@"Something is wrong, and we can't continue.");
        NSLog(@"ICMP Type: %d and Code: %d", type, code);
    }
}

-(void)processErrorICMPPacket:(NSData *)packet{
    //Use ICMP error packet structure rather than valid response structure
    const ICMPErrorPacket* errorPacket = (const struct ICMPErrorPacket *)[packet bytes];
    
    //Get sequence number to calculate RTT
    NSInteger sequenceNumber = CFSwapInt16BigToHost(errorPacket->sequenceNumberOriginal);
    double rtt = [self getResponseTimeForSequence:sequenceNumber];
    
    if (self.ipsForCurrentRequest.count < 1) {
        // First address/hop case, empty array
        [self.ipsForCurrentRequest addObject:self.lastIP];
        self.totalResponsesForHop++;
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:withHops:)]) {
            NSArray* hops = self.ipsForCurrentRequest;
            [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: %@  %.2fms", self.ttlCount, self.lastIP, rtt] withHops:hops];
        }
    } else {
        // Check if we've received an error packet for this address before
        [self checkForResponseAddressWithErrorPacket:packet];
    }
}

-(void)processValidICMPPacket:(NSData*)packet{
    // If we have an echo response, then we should be done, let's check:
    const ICMPHeader* header = [SCPacketUtility icmpInPacket:packet];
    NSInteger sequenceNumber = CFSwapInt16BigToHost(header->sequenceNumber);
    double rtt = [self getResponseTimeForSequence:sequenceNumber];
    
    if (![self reachedTargetAddress]) {
        NSLog(@"Error, if we have a type 0 then our IPs should match - something is derped.");
    } else {
        [self.ipsForCurrentRequest addObject:self.lastIP];
        self.totalResponsesForHop++;
        
        if (self.totalResponsesForHop == 1) {
            //We only need to call this once even though there are three packets coming back
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:withHops:)]) {
                NSArray* hops = self.ipsForCurrentRequest;
                [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: %@  %.2f", self.ttlCount, self.lastIP, rtt] withHops:hops];
            }
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidComplete:)]) {
                [self.delegate tracerouteDidComplete:self.ipsForCurrentRequest];
            }
        } else if (self.totalResponsesForHop == 3) {
            // Check average RTT of all three packets?
        }
    }
}

-(void)checkForResponseAddressWithErrorPacket:(NSData*)packet{
    // Check if we've received a packet for this IP before
    BOOL haveIP = NO;
    
    for (NSString* item in self.ipsForCurrentRequest)
    {
        if ([item isEqualToString:self.lastIP]){
            haveIP = YES;
            self.totalResponsesForHop++;
        } else {
            haveIP = NO;
        }
    }
    //Use ICMP error packet structure rather than valid response structure
    const ICMPErrorPacket* errorPacket = (const struct ICMPErrorPacket *)[packet bytes];
    
    //Get sequence number to calculate RTT
    NSInteger sequenceNumber = CFSwapInt16BigToHost(errorPacket->sequenceNumberOriginal);
    double rtt = [self getResponseTimeForSequence:sequenceNumber];
    
    //We check against count and THEN modify the array to avoid issues modifying array while it is being enumerated
    if (haveIP) {
        if (self.totalResponsesForHop == 3) {
            // We have three responses, move on to the next hop
            // TODO: This is fragile - What if we get one packet and two bad?
            self.ttlCount++;
            [self sendPackets:nil];
            self.totalResponsesForHop = 0;
        }
    } else {
        // We've found a new hop address
        [self.ipsForCurrentRequest addObject:self.lastIP];
        self.totalResponsesForHop++;
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:withHops:)]) {
            NSArray* hops = self.ipsForCurrentRequest;
            [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: %@  %.2fms", self.ttlCount, self.lastIP, rtt] withHops:hops];
        }
    }
}

-(double)getResponseTimeForSequence:(NSInteger)sequenceNumber{
    NSDate*  nowDate = [NSDate date];
    double rtt = 0;
    NSDate* departureTimeDate = [self.packetUtility.packetDepartureTimes objectForKey:[NSString stringWithFormat:@"%d", sequenceNumber]];
    if (departureTimeDate) {
        // If we sent a packet with a corresponding sequence number, let's calculate the RTT
        rtt = [nowDate timeIntervalSinceDate:departureTimeDate] * 1000;
        //NSLog(@"Packet sequence %d took %.2fms", sequenceNumber, rtt);
    }
    
    return rtt;
}

- (void)sendPackets:(NSData*)data{
    self.timeExceededCount = 0;
    if (self.ttlCount <= MAX_HOPS) {
        switch (self.currentTracerouteType) {
            case kICMP:
                [self.packetUtility sendPacketOfType:kICMP withData:data withTTL:self.ttlCount];
                [self.packetUtility sendPacketOfType:kICMP withData:data withTTL:self.ttlCount];
                [self.packetUtility sendPacketOfType:kICMP withData:data withTTL:self.ttlCount];
                break;
            case kUDP:
                [self.packetUtility sendPacketOfType:kUDP withData:data withTTL:self.ttlCount];
                [self.packetUtility sendPacketOfType:kUDP withData:data withTTL:self.ttlCount];
                [self.packetUtility sendPacketOfType:kUDP withData:data withTTL:self.ttlCount];
                break;
            default:
                break;
        }
    } else if (self.ttlCount > MAX_HOPS) {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidTimeout)]) {
            [self.delegate tracerouteDidTimeout];
        }
    }
}

-(void)timeExceededForPacket {
    self.timeExceededCount++;
    if (self.timeExceededCount == 3) {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:withHops:)]) {
            NSArray* hops = self.ipsForCurrentRequest;
            [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: * * * Hop did not reply or timed out.", self.ttlCount] withHops:hops];
            self.totalHopsTimedOut++;
        }
        
        if (self.totalHopsTimedOut > 3) {
            //SHUT. DOWN. EVERYTHING.
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidTimeout)]) {
                [self.delegate tracerouteDidTimeout];
            }
        } else {
            self.ttlCount++;
            [self sendPackets:nil];
        }

    }
}


#pragma mark - UDP 

//UDP specific stuff here?

#pragma mark - Packet utility delegate

// When the tracer starts, send the a first packet immediately
- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didStartWithAddress:(NSData*)address {
    [self sendPackets: nil];
}

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didFailWithError:(NSError*)error{
	NSLog(@"ERROR: %@", error);
}
- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didSendPacket:(NSData *)packet{
    [self performSelector:@selector(timeExceededForPacket) withObject:nil afterDelay:1];
}

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didFailToSendPacket:(NSData*)packet error:(NSError*)error {
	NSLog(@"ERROR: %@", error);
}

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didReceiveResponsePacket:(NSData *)packet {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self processICMPPacket:packet];
}

- (void)SCPacketUtility:(SCPacketUtility*)tracer didReceiveUnexpectedPacket:(NSData *)packet {
    //This doesn't do much since a big chunk of validation is commented out right now. Angelina will be repurposing this stuff later once we're validating against the sequence number to obtain the RTT
	NSLog(@"Cap'n, tis' a rogue packet!");
}




@end
