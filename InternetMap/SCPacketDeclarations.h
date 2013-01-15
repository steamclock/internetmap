//
//  SCPacketDeclarations.h
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#ifndef InternetMap_SCPacketDeclarations_h
#define InternetMap_SCPacketDeclarations_h

#include <AssertMacros.h>

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


#endif
