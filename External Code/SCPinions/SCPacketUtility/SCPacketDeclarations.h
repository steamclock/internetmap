//
//  SCPacketDeclarations.h
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


__Check_Compile_Time(sizeof(IPHeader) == 20);
__Check_Compile_Time(offsetof(IPHeader, versionAndHeaderLength) == 0);
__Check_Compile_Time(offsetof(IPHeader, differentiatedServices) == 1);
__Check_Compile_Time(offsetof(IPHeader, totalLength) == 2);
__Check_Compile_Time(offsetof(IPHeader, identification) == 4);
__Check_Compile_Time(offsetof(IPHeader, flagsAndFragmentOffset) == 6);
__Check_Compile_Time(offsetof(IPHeader, timeToLive) == 8);
__Check_Compile_Time(offsetof(IPHeader, protocol) == 9);
__Check_Compile_Time(offsetof(IPHeader, headerChecksum) == 10);
__Check_Compile_Time(offsetof(IPHeader, sourceAddress) == 12);
__Check_Compile_Time(offsetof(IPHeader, destinationAddress) == 16);

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

__Check_Compile_Time(sizeof(ICMPHeader) == 8);
__Check_Compile_Time(offsetof(ICMPHeader, type) == 0);
__Check_Compile_Time(offsetof(ICMPHeader, code) == 1);
__Check_Compile_Time(offsetof(ICMPHeader, checksum) == 2);
__Check_Compile_Time(offsetof(ICMPHeader, identifier) == 4);
__Check_Compile_Time(offsetof(ICMPHeader, sequenceNumber) == 6);

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

__Check_Compile_Time(sizeof(UDPHeader) == 8);
__Check_Compile_Time(offsetof(UDPHeader, sport) == 0);
__Check_Compile_Time(offsetof(UDPHeader, dport) == 2);
__Check_Compile_Time(offsetof(UDPHeader, length) == 4);
__Check_Compile_Time(offsetof(UDPHeader,checksum) == 6);


#endif
