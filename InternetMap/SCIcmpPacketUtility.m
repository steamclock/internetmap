//
//  SCIcmpPacketUtility.m
//  InternetMap
//
//  Created by Angelina Fabbro on 2013-01-04.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "SCIcmpPacketUtility.h"
#import "SCPacketRecord.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <arpa/inet.h>

#pragma - SCIcmpPacketUtility

@interface SCIcmpPacketUtility ()

@property (nonatomic, copy,   readwrite) NSData*    targetAddress;
@property (nonatomic, assign, readwrite) uint16_t   nextSequenceNumber;

- (void)_stopDataTransfer;

@end

@implementation SCIcmpPacketUtility

#pragma mark - Standard BSD Checksum

// TODO: Put this in a place where other files can use it too?

static uint16_t in_cksum(const void *buffer, size_t bufferLen)
// This is the standard BSD checksum code, modified to use modern types.
{
	size_t              bytesLeft;
    int32_t             sum;
	const uint16_t *    cursor;
	union {
		uint16_t        us;
		uint8_t         uc[2];
	} last;
	uint16_t            answer;
    
	bytesLeft = bufferLen;
	sum = 0;
	cursor = buffer;
    
	/*
	 * Our algorithm is simple, using a 32 bit accumulator (sum), we add
	 * sequential 16 bit words to it, and at the end, fold back all the
	 * carry bits from the top 16 bits into the lower 16 bits.
	 */
	while (bytesLeft > 1) {
		sum += *cursor;
        cursor += 1;
		bytesLeft -= 2;
	}
    
	/* mop up an odd byte, if necessary */
	if (bytesLeft == 1) {
		last.uc[0] = * (const uint8_t *) cursor;
		last.uc[1] = 0;
		sum += last.us;
	}
    
	/* add back carry outs from top 16 bits to low 16 bits */
	sum = (sum >> 16) + (sum & 0xffff);	/* add hi 16 to low 16 */
	sum += (sum >> 16);			/* add carry */
	answer = ~sum;				/* truncate to 16 bits */
    
	return answer;
}

#pragma mark - Class Methods

+ (SCIcmpPacketUtility*)utilityWithHostAddress:(NSString*)hostAddress
{
    return [[SCIcmpPacketUtility alloc] initWithAddress:hostAddress];
}

#pragma mark - Instance Methods

- (id)initWithAddress:(NSString*)hostAddress
{
    assert(hostAddress != nil);
    NSData* hostAddressData = [self formatAddress:hostAddress];
    
    self = [super init];
    if (self != nil) {
        self->_targetAddressString = [hostAddress copy];
        self->_targetAddress = hostAddressData;
        self->_packetRecords = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSData*)formatAddress:(NSString*)address{
    const char *ipstring = [address UTF8String];
    struct sockaddr_in ip;
    inet_aton(ipstring, &ip.sin_addr);
    ip.sin_family = AF_INET;
    NSData* hostAddress = [NSData dataWithBytes:&ip length:sizeof(ip)];
    return hostAddress;
}


#pragma mark - Packet sending


-(void)sendPacketWithData:(NSData *)data andTTL:(int)ttl{
    
    int             err;
    NSData *        payload;
    NSMutableData * packet;
    ICMPHeader *    icmpPtr;
    ssize_t         bytesSent;
    
    // Construct the traceroute packet.
    
    payload = data;
    if (payload == nil) {
        payload = [[NSString stringWithFormat:@"%28zd bottles of beer on the wall", (ssize_t) 99 - (size_t) (self.nextSequenceNumber % 100) ] dataUsingEncoding:NSASCIIStringEncoding];
        assert(payload != nil);
        assert([payload length] == 56);
    }
    
    packet = [NSMutableData dataWithLength:sizeof(*icmpPtr) + [payload length]];
    assert(packet != nil);
    
    icmpPtr = [packet mutableBytes];
    icmpPtr->type = kICMPTypeEchoRequest;
    icmpPtr->code = 0;
    icmpPtr->checksum = 0;
    icmpPtr->sequenceNumber = OSSwapHostToBigInt16(self.nextSequenceNumber);
    
    memcpy(&icmpPtr[1], [payload bytes], [payload length]);
    
    // The IP checksum returns a 16-bit number that's already in correct byte order
    // (due to wacky 1's complement maths), so we just put it into the packet as a
    // 16-bit unit.
    
    icmpPtr->checksum = in_cksum([packet bytes], [packet length]);
    
    // Send the packet.
    
    if (self->_socket == NULL) {
        bytesSent = -1;
        err = EBADF;
    } else {
        
        if (!ttl) {
            ttl = 1;
        }
        
        int sockopt = setsockopt(CFSocketGetNative(self->_socket), IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl));
        if (sockopt < 0) {
            err = errno;
            NSLog(@"%s", strerror(err));
        }
        
        // Store departure time for packet sequence number to calculate RTT if desired
        NSDate* now = [NSDate date];
        bytesSent = sendto(
                           CFSocketGetNative(self->_socket),
                           [packet bytes],
                           [packet length],
                           0,
                           (struct sockaddr *) [self.targetAddress bytes],
                           (socklen_t) [self.targetAddress length]
                           );
        err = 0;
        if (bytesSent < 0) {
            err = errno;
        } else {
            // Complete success. Track ze packet!
            
            SCPacketRecord* packet = [[SCPacketRecord alloc] init];
            packet.sentWithTTL = ttl;
            packet.sequenceNumber = self.nextSequenceNumber;
            packet.departure = now;
            packet.
        }
    }
    
    // Handle the results of the send.
    
    if ((bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length]) ) {
        
        // Tell the client, woop woop
        
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didSendPacket:)] ) {
            [self.delegate SCIcmpPacketUtility:self didSendPacket:packet];
        }
    } else {
        NSError*   error;
        
        // Some sort of failure.  Tell the client.
        
        if (err == 0) {
            err = ENOBUFS;          // This is not a hugely descriptor error, alas.
        }
        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didFailToSendPacket:error:)] ) {
            [self.delegate SCIcmpPacketUtility:self didFailToSendPacket:packet error:error];
        }
    }
    
    self.nextSequenceNumber += 1;
}


#pragma mark - Error handling

- (void)_didFailWithError:(NSError *)error
// Shut down the tracer object and tell the delegate about the error.
{
    assert(error != nil);
    
    [self stop];
    if ((self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didFailWithError:)] ) {
        [self.delegate SCIcmpPacketUtility:self didFailWithError:error];
    }
}

- (void)_didFailWithHostStreamError:(CFStreamError)streamError
// Convert the CFStreamError to an NSError and then call through to _didFailWithError
{
    NSDictionary*  userInfo;
    NSError*       error;
    
    if (streamError.domain == kCFStreamErrorDomainNetDB) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInteger:streamError.error], kCFGetAddrInfoFailureKey,
                    nil];
    } else {
        userInfo = nil;
    }
    error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:userInfo];
    assert(error != nil);
    
    [self _didFailWithError:error];
}



@end
