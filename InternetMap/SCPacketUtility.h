//
//  SCPacketUtility.h
//  SCPacketUtility
//
//  Created by Angelina Fabbro on 12-12-07.
//  Copyright (c) 2012 Steamclock Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#include <AssertMacros.h>

#pragma mark - SCPacketUtility

// Packet types
// TODO:could expand to support TCP maybe?
typedef enum {
    kUDP   = 0,           // code is always 0
    kICMP   = 1,
}packetType;

// SCPacketUtility is a simple class for sending and receiving ICMP packets.

@protocol SCPacketUtilityDelegate;

@interface SCPacketUtility : NSObject
{
    NSString *              _hostName;
    NSData *                _hostAddress;
    CFHostRef               _host;
    CFSocketRef             _socket;
     __unsafe_unretained    id<SCPacketUtilityDelegate>  _delegate;
    uint16_t                _identifier;                            // host byte order
    uint16_t                _nextSequenceNumber;                    // host byte order
}


+ (SCPacketUtility*)utilityWithHostName:(NSString *)hostName;        // chooses first IPv4 address
+ (SCPacketUtility*)utilityWithHostAddress:(NSData *)hostAddress;    // contains (struct sockaddr)

@property (nonatomic, assign, readwrite) id<SCPacketUtilityDelegate> delegate;
@property (nonatomic, copy,   readonly)  NSString*             hostName;
@property (nonatomic, copy,   readonly)  NSData*               hostAddress;
@property (nonatomic, assign, readonly)  uint16_t               identifier;
@property (nonatomic, assign, readonly)  uint16_t               nextSequenceNumber;

// Packet types

- (void)start;
// Starts the packet utility object doing it's thing.  You should call this after
// you've setup the delegate and any packet parameters.

- (void)sendPacketOfType:(packetType)type withData:(NSData *)data withTTL:(int)ttl;
// Sends a packet.
// Do not try to send a packet before you receive the -SCPacketUtility:didStartWithAddress: delegate
// callback.

- (void)stop;
// Stops the packet utility object.  You should call this when you're done using it.

+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet;
// Given a valid IP packet contains an ICMP, returns the address of the ICMP header that
// follows the IP header.  This doesn't do any significant validation of the packet.

@end

@protocol SCPacketUtilityDelegate <NSObject>

@optional

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didStartWithAddress:(NSData *)address;
// Called after the SCPacketUtility has successfully started up.  After this callback, you
// can start sending packets via -sendPacketWithData:

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didFailWithError:(NSError *)error;
// If this is called, the SCPacketUtility object has failed.  By the time this callback is
// called, the object has stopped (that is, you don't need to call -stop yourself).

// IMPORTANT: On the send side the packet does not include an IP header.
// On the receive side, it does.  In that case, use +[SCPacketUtility icmpInPacket:]
// to find the ICMP header within the packet.

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didSendPacket:(NSData *)packet;
// Called whenever the SCPacketUtility object has successfully sent a packet.

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didFailToSendPacket:(NSData *)packet error:(NSError *)error;
// Called whenever the SCPacketUtility object tries and fails to send a packet.

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didReceiveResponsePacket:(NSData *)packet;
// Called whenever the SCPacketUtility object receives an ICMP packet that looks like
// a response to one of our traceroute packets (that is, has a valid ICMP checksum, has
// an identifier that matches our identifier, and has a sequence number in
// the range of sequence numbers that we've sent out).

- (void)SCPacketUtility:(SCPacketUtility*)packetUtility didReceiveUnexpectedPacket:(NSData *)packet;
// Called whenever the SCPacketUtility object receives an ICMP packet that does not
// look like a response to one of our packets.

@end

#pragma mark - Traceroute packet structure declarations

struct IPHeader {
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // options...
    // data...
};

typedef struct IPHeader IPHeader;

check_compile_time(sizeof(IPHeader) == 20);
check_compile_time(offsetof(IPHeader, versionAndHeaderLength) == 0);
check_compile_time(offsetof(IPHeader, differentiatedServices) == 1);
check_compile_time(offsetof(IPHeader, totalLength) == 2);
check_compile_time(offsetof(IPHeader, identification) == 4);
check_compile_time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
check_compile_time(offsetof(IPHeader, timeToLive) == 8);
check_compile_time(offsetof(IPHeader, protocol) == 9);
check_compile_time(offsetof(IPHeader, headerChecksum) == 10);
check_compile_time(offsetof(IPHeader, sourceAddress) == 12);
check_compile_time(offsetof(IPHeader, destinationAddress) == 16);

// ICMP:

struct ICMPHeader {
    uint8_t     type;
    uint8_t     code;
    uint16_t    checksum;
    uint16_t    identifier;
    uint16_t    sequenceNumber;
    // data...
};

typedef struct ICMPHeader ICMPHeader;

// ICMP type and code combinations

enum {
    kICMPTypeEchoReply   = 0,           // code is always 0
    kICMPTypeDestinationUnreachable = 3,
    kICMPTypeEchoRequest = 8,            // code is always 0
    kICMPTimeExceeded = 11
};

check_compile_time(sizeof(ICMPHeader) == 8);
check_compile_time(offsetof(ICMPHeader, type) == 0);
check_compile_time(offsetof(ICMPHeader, code) == 1);
check_compile_time(offsetof(ICMPHeader, checksum) == 2);
check_compile_time(offsetof(ICMPHeader, identifier) == 4);
check_compile_time(offsetof(ICMPHeader, sequenceNumber) == 6);

struct ICMPErrorPacket {
    // IP Header
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // ICMP error
    uint8_t type;
    uint8_t code;
    uint16_t checksum;
    uint32_t unused;
    //Original IP header
    uint8_t     versionAndHeaderLengthOriginal;
    uint8_t     differentiatedServicesOriginal;
    uint16_t    totalLengthOriginal;
    uint16_t    identificationOriginal;
    uint16_t    flagsAndFragmentOffsetOriginal;
    uint8_t     timeToLiveOriginal;
    uint8_t     protocolOriginal;
    uint16_t    headerChecksumOriginal;
    uint8_t     sourceAddressOriginal[4];
    uint8_t     destinationAddressOriginal[4];
    //Original ICMP header
    uint8_t     typeOriginal;
    uint8_t     codeOriginal;
    uint16_t    checksumOriginal;
    uint16_t    identifierOriginal;
    uint16_t    sequenceNumberOriginal;
};

typedef struct ICMPErrorPacket ICMPErrorPacket;

// UDP:

struct UDPHeader {
    uint16_t sport;  /* source port      */
    uint16_t dport;  /* destination port */
    uint16_t length;     /* udp length       */
    uint16_t checksum;    /* udp checksum     */
    // data
};

typedef struct UDPHeader UDPHeader;

check_compile_time(sizeof(UDPHeader) == 8);
check_compile_time(offsetof(UDPHeader, sport) == 0);
check_compile_time(offsetof(UDPHeader, dport) == 2);
check_compile_time(offsetof(UDPHeader, length) == 4);
check_compile_time(offsetof(UDPHeader,checksum) == 6);


