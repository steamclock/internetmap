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
@property (nonatomic, strong) NSString *targetIP;
@property (nonatomic, strong) NSString *lastIP;
@property (nonatomic, strong )NSMutableArray *ipsForCurrentRequest;

@end

@implementation SCTraceroute

//We init with 
- (id)initWithAddress:(NSString *)hostAddress
{
    self = [super init];
    if (self != nil) {
        NSData *address = [self formatAddress:hostAddress];
        self.packetUtility = [SCPacketUtility utilityWithHostAddress:address];
        self.packetUtility.delegate = self;
    }
    return self;
}

- (id)initWithHostName:(NSString*)hostName{
    
    self = [super init];
    if (self != nil) {
        self.packetUtility = [SCPacketUtility utilityWithHostName:hostName];
        self.packetUtility.delegate = self;
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


+ (SCTraceroute*)tracerouteWithAddress:(NSString*)address
{
    return [[SCTraceroute alloc] initWithAddress:address];
}

+(SCTraceroute*)tracerouteWithHostName:(NSString*)hostname{
    return [[SCTraceroute alloc] initWithHostName:hostname];
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

-(void)processPacket:(NSData *)packet{
    
    // TODO: Swap in constants for magic numbers (ICMP Codes), remove NSLogs since delegation is working, and generally fix this up since it's hairy in here.
    
    const ICMPHeader* header = [SCPacketUtility icmpInPacket:packet];
    NSInteger type = (NSInteger)header->type;
    NSInteger code = (NSInteger)header->code;
    
    const IPHeader* IPHeader = (const struct IPHeader *) [packet bytes];
    
    int ip[4];
    ip[0] = IPHeader->sourceAddress[0];
    ip[1] = IPHeader->sourceAddress[1];
    ip[2] = IPHeader->sourceAddress[2];
    ip[3] = IPHeader->sourceAddress[3];
    
    self.lastIP = [NSString stringWithFormat:@"%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]];

    if (type == 11) { //TTL Expired
        
        if (self.ipsForCurrentRequest.count < 1) {
            // First address/hop case, empty array
            [self.ipsForCurrentRequest addObject:self.lastIP];
            self.totalResponsesForHop++;
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:)]) {
                [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: %@", self.ttlCount, self.lastIP]];
            }
        } else {
            
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
            
            //We check against count and THEN modify the array to avoid issues modifying array while it is being enumerated
            if (haveIP) {
                if (self.totalResponsesForHop == 3) {
                    self.ttlCount++;
                    [self sendPackets:nil];
                    self.totalResponsesForHop = 0;
                }
            } else {
                [self.ipsForCurrentRequest addObject:self.lastIP];
                self.totalResponsesForHop++;
                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:)]) {
                    [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: %@", self.ttlCount, self.lastIP]];
                }
            }
        }
    } else if (type == 0) { //ECHO Response
        if (![self reachedTargetAddress]) {
            // This should always return true
            NSLog(@"Error, if we have a type 0 then our IPs should match");
        } else {
            [self.ipsForCurrentRequest addObject:self.lastIP];
            self.totalResponsesForHop++;
            if (self.totalResponsesForHop == 1) { //We only need to call this once even though there are three packets coming back
                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:)]) {
                    [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: %@", self.ttlCount, self.lastIP]];
                }
                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidComplete:)]) {
                    [self.delegate tracerouteDidComplete:self.ipsForCurrentRequest];
                }
            }
        }
    } else { //Everything else we don't want
        NSLog(@"Something is wrong, and we can't continue.");
        NSLog(@"ICMP Type: %d and Code: %d", type, code);
    }
}

- (void)sendPackets:(NSData*)data{
    self.timeExceededCount = 0;
    //Send three packets each time, 'cause this is a traceroute after all
    
    [self.packetUtility sendPacketWithData:data withTTL:self.ttlCount];
    [self.packetUtility sendPacketWithData:data withTTL:self.ttlCount];
    [self.packetUtility sendPacketWithData:data withTTL:self.ttlCount];
}

-(void)timeExceededForPacket {
    self.timeExceededCount++;
    if (self.timeExceededCount == 3) {
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidFindHop:)]) {
            [self.delegate tracerouteDidFindHop:[NSString stringWithFormat:@"%d: * * * Hop did not reply or timed out.", self.ttlCount]];
        }
        self.ttlCount++;
        [self sendPackets:nil];
    }
}

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
    [self processPacket:packet];
}

- (void)SCPacketUtility:(SCPacketUtility*)tracer didReceiveUnexpectedPacket:(NSData *)packet {
    //This doesn't do much since a big chunk of validation is commented out right now. Angelina will be repurposing this stuff later once we're validating against the sequence number to obtain the RTT
	NSLog(@"Cap'n, tis' a rogue packet!");
    const ICMPHeader* header = [SCPacketUtility icmpInPacket:packet];
	NSLog(@"Received packet! ICMP Header stuff ~ Type: %d, Code: %c", header->type, header->code);
}


@end
