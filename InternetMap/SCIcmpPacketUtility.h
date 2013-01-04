//
//  SCIcmpPacketUtility.h
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "SCPacketDeclarations.h"

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#include <AssertMacros.h> //Where are these used? Derp derp.

#pragma mark - SCIcmpPacketUtility

// SCPacketUtility is a simple class for sending and receiving ICMP packets.

@protocol SCPacketUtilityDelegate;

@interface SCPacketUtility : NSObject
{
    NSString*   hostName;
    NSData*     hostAddress;
    CFHostRef   host;
    CFSocketRef socket;
    __unsafe_unretained id<SCPacketUtilityDelegate>  delegate;
    uint16_t    identifier; // host byte order
    uint16_t    nextSequenceNumber; // host byte order
}

@property (nonatomic, assign, readwrite) id<SCPacketUtilityDelegate> delegate;
@property (nonatomic, copy,   readonly)  NSString*             hostName;
@property (nonatomic, copy,   readonly)  NSData*               hostAddress;
@property (nonatomic, assign, readonly)  uint16_t               identifier;
@property (nonatomic, assign, readonly)  uint16_t               nextSequenceNumber;
@property (nonatomic, strong, readonly)   NSMutableDictionary*         packetDepartureTimes;

- (void)start;
// Starts the packet utility object doing it's thing.  You should call this after you've setup the delegate.

- (void)sendPacket:(NSData *)data withTTL:(int)ttl;
// Sends an ICMP packet. Do not try to send a packet before you receive the -SCPacketUtility:didStartWithAddress: delegate callback.

- (void)stop;
// Stops the packet utility object.  You should call this when you're done using it.

+ (SCIcmpPacketUtility*)utilityWithHostAddress:(NSData *)hostAddress;    // contains (struct sockaddr) - should have this take IP string, then convert to struct sockaddr

+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet;
// Given a valid IP packet contains an ICMP, returns the address of the ICMP header that follows the IP header.  This doesn't do any significant validation of the packet.

@end

@protocol SCPacketUtilityDelegate <NSObject>

@optional

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didStartWithAddress:(NSData *)address;
// Called after the SCPacketUtility has successfully started up.  After this callback, you can start sending packets via -sendPacketWithData:

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didFailWithError:(NSError *)error;
// If this is called, the SCPacketUtility object has failed.  By the time this callback is called, the object has stopped (that is, you don't need to call -stop yourself).

// IMPORTANT: On the send side the packet does not include an IP header.
// On the receive side, it does.  In that case, use +[SCPacketUtility icmpInPacket:]
// to find the ICMP header within the packet.

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didSendPacket:(NSData *)packet;
// Called whenever the SCPacketUtility object has successfully sent a packet.

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didFailToSendPacket:(NSData *)packet error:(NSError *)error;
// Called whenever the SCPacketUtility object tries and fails to send a packet.

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didReceiveResponsePacket:(NSData *)packet;
// Called whenever the SCPacketUtility object receives an ICMP packet that looks like a response to one of our packets

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didReceiveUnexpectedPacket:(NSData *)packet;
// Called whenever the SCPacketUtility object receives an ICMP packet that does not look like a response to one of our packets.

@end

