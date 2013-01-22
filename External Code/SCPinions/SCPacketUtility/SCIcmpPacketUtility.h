//
//  SCIcmpPacketUtility.h
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

#import <Foundation/Foundation.h>
#include "SCPacketDeclarations.h"

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#pragma mark - SCIcmpPacketUtility

// SCIcmpPacketUtility is a simple class for sending and receiving ICMP packets.

@protocol SCIcmpPacketUtilityDelegate;

@interface SCIcmpPacketUtility : NSObject
{
    NSData*     _targetAddress;
    NSString*   _targetAddressString;
    CFHostRef   _host;
    CFSocketRef _socket;
    __unsafe_unretained id<SCIcmpPacketUtilityDelegate>  _delegate;
    uint16_t    _nextSequenceNumber; // host byte order
}

@property (nonatomic, assign, readwrite) id<SCIcmpPacketUtilityDelegate> delegate;
@property (nonatomic, copy,   readonly) NSData*               targetAddress;
@property (nonatomic, copy, readwrite) NSString*             targetAddressString;
@property (nonatomic, assign, readonly) uint16_t              nextSequenceNumber;
@property (strong, nonatomic, readonly) NSMutableArray*       packetRecords;

+ (SCIcmpPacketUtility*)utilityWithHostAddress:(NSString*)hostAddress;    // contains (struct sockaddr) - should have this take IP string, then convert to struct sockaddr

+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet;
// Given a valid IP packet contains an ICMP, returns the address of the ICMP header that follows the IP header.  This doesn't do any significant validation of the packet.

- (void)start;
// Starts the packet utility object doing it's thing.  You should call this after you've setup the delegate.

- (void)sendPacketWithData:(NSData *)data andTTL:(int)ttl;
// Sends an ICMP packet. Do not try to send a packet before you receive the -SCIcmpPacketUtility:didStartWithAddress: delegate callback.

- (void)stop;
// Stops the packet utility object.  You should call this when you're done using it.


@end

@protocol SCIcmpPacketUtilityDelegate <NSObject>

@optional

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didStartWithAddress:(NSData *)address;
// Called after the SCIcmpPacketUtility has successfully started up.  After this callback, you can start sending packets via -sendPacketWithData:

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didFailWithError:(NSError *)error;
// If this is called, the SCIcmpPacketUtility object has failed.  By the time this callback is called, the object has stopped (that is, you don't need to call -stop yourself).

// IMPORTANT: On the send side the packet does not include an IP header.
// On the receive side, it does.  In that case, use +[SCIcmpPacketUtility icmpInPacket:]
// to find the ICMP header within the packet.

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didSendPacket:(NSData *)packet;
// Called whenever the SCIcmpPacketUtility object has successfully sent a packet.

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didFailToSendPacket:(NSData *)packet error:(NSError *)error;
// Called whenever the SCIcmpPacketUtility object tries and fails to send a packet.

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didReceiveResponsePacket:(NSData *)packet arrivedAt:(NSDate*)dateTime;
// Called whenever the SCIcmpPacketUtility object receives an ICMP packet that looks like a response to one of our packets

- (void)SCIcmpPacketUtility:(SCIcmpPacketUtility*)packetUtility didReceiveUnexpectedPacket:(NSData *)packet;
// Called whenever the SCIcmpPacketUtility object receives an ICMP packet that does not look like a response to one of our packets.

@end

