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

+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet
{
    const struct ICMPHeader *   result;
    NSUInteger                  icmpHeaderOffset;
    
    result = nil;
    icmpHeaderOffset = [self _icmpHeaderOffsetInPacket:packet];
    if (icmpHeaderOffset != NSNotFound) {
        result = (const struct ICMPHeader *) (((const uint8_t *)[packet bytes]) + icmpHeaderOffset);
    }

    return result;
}

+ (NSUInteger)_icmpHeaderOffsetInPacket:(NSData *)packet
{
    NSUInteger              result;
    const struct IPHeader * ipPtr;
    size_t                  ipHeaderLength;
    
    result = 0;
    
    if ([packet length] >= (sizeof(IPHeader) + sizeof(ICMPHeader))) {
        ipPtr = (const IPHeader *) [packet bytes];
        if (ipPtr->protocol == 1 &&( (ipPtr->versionAndHeaderLength & 0xF0) == 0x40) ) { //Verify packet is IPv4 and ICMP
            ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);
            if ([packet length] >= (ipHeaderLength + sizeof(ICMPHeader))) {
                result = ipHeaderLength;
            }
        }
    }
    
    return result;
}


#pragma mark - Instance Methods

- (id)initWithAddress:(NSString*)hostAddress
{
    assert(hostAddress != nil);
    NSData* hostAddressData = [self _formatAddress:hostAddress];
    
    self = [super init];
    if (self != nil) {
        self->_targetAddressString = [hostAddress copy];
        self->_targetAddress = hostAddressData;
        self->_packetRecords = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSData*)_formatAddress:(NSString*)address{
    const char *ipstring = [address UTF8String];
    struct sockaddr_in ip;
    inet_aton(ipstring, &ip.sin_addr);
    ip.sin_family = AF_INET;
    NSData* hostAddress = [NSData dataWithBytes:&ip length:sizeof(ip)];
    return hostAddress;
}

- (void)_startWithHostAddress
{
    int                     err;
    int                     fd;
    const struct sockaddr * addrPtr;
    
    assert(self.targetAddress != nil);
    
    // Open the socket.
    
    addrPtr = (const struct sockaddr *) [self.targetAddress bytes];
    
    fd = -1;
    err = 0;
    switch (addrPtr->sa_family) {
        case AF_INET: {
            fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
            
            if (fd < 0) {
                err = errno;
            }
        } break;
        case AF_INET6:
            assert(NO);
            // fall through
        default: {
            err = EPROTONOSUPPORT;
        } break;
    }
    
    if (err != 0) {
        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
    } else {
        CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        CFRunLoopSourceRef  rls;
        
        // Wrap it in a CFSocket and schedule it on the runloop.

        self->_socket = CFSocketCreateWithNative(NULL, fd, kCFSocketReadCallBack, SocketReadCallback, &context);
        assert(self->_socket != NULL);
        
        // The socket will now take care of clean up our file descriptor.
        
        assert( CFSocketGetSocketFlags(self->_socket) & kCFSocketCloseOnInvalidate );
        fd = -1;
        
        rls = CFSocketCreateRunLoopSource(NULL, self->_socket, 0);
        assert(rls != NULL);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        
        CFRelease(rls);
        
        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didStartWithAddress:)] ) {
            [self.delegate SCIcmpPacketUtility:self didStartWithAddress:self.targetAddress];
        }
    }
    assert(fd == -1);
}

- (void)start
{
    // If the user supplied us with an address, just start pinging that.  Otherwise... uh.
    
    if (self->_targetAddress != nil) {
        [self _startWithHostAddress];
    } else {
        // wat.
    }
}

- (void)stop
{
    if (self->_socket != NULL) {
        CFSocketInvalidate(self->_socket);
        CFRelease(self->_socket);
        self->_socket = NULL;
    }
}

#pragma mark - Packet sending


-(void)sendPacketWithData:(NSData *)data andTTL:(int)ttl{
    
    int             err;
    NSData *        payload;
    NSMutableData * packet;
    ICMPHeader *    icmpPtr;
    ssize_t         bytesSent;
    
    // Construct the ICMP
    
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
    icmpPtr->identifier = (uint16_t) arc4random();
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
            
            SCPacketRecord* packetRecord = [[SCPacketRecord alloc] init];
            packetRecord.sentWithTTL = ttl;
            packetRecord.sequenceNumber = self.nextSequenceNumber;
            packetRecord.departure = now;
            
            [self.packetRecords addObject:packetRecord];
        }
    }
    
    // Handle the results of the send.
    
    if ((bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length]) ) {
        
        // Succcess: Tell the client, woop woop
        
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

#pragma mark - Receive packets

- (void)_readData{
    // Called by the socket handling code (SocketReadCallback) to process a message waiting on the socket
    int                     err;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    ssize_t                 bytesRead;
    void *                  buffer;
    enum { kBufferSize = 65535 };
    
    // 65535 is the maximum IP packet size, which seems like a reasonable bound
    // here (plus it's what <x-man-page://8/ping> uses).
    
    buffer = malloc(kBufferSize);
    assert(buffer != NULL);
    
    // Actually read the data.
    
    addrLen = sizeof(addr);
    bytesRead = recvfrom(CFSocketGetNative(self->_socket), buffer, kBufferSize, 0, (struct sockaddr *) &addr, &addrLen);
    
    NSDate* now = [NSDate date]; //Pass this up to the delegate in case we care about RTT
    
    err = 0;
    if (bytesRead < 0) {
        err = errno;
    }
    
    // Process the data we read.
    
    if (bytesRead > 0) {
        NSMutableData *     packet;
        
        packet = [NSMutableData dataWithBytes:buffer length:bytesRead];
        assert(packet != nil);
        
        // We got some data, pass it up to our client.
        
        if ( [self _isValidResponsePacket:packet] ) {
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didReceiveResponsePacket:arrivedAt:)] ) {
                [self.delegate SCIcmpPacketUtility:self didReceiveResponsePacket:packet arrivedAt:now];
            }
        } else {
            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didReceiveUnexpectedPacket:)] ) {
                [self.delegate SCIcmpPacketUtility:self didReceiveUnexpectedPacket:packet];
            }
        }
    } else {
        
        // We failed to read the data, so shut everything down.
        
        if (err == 0) {
            err = EPIPE;
        }
        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
    }
    
    free(buffer);
    
    // Note that we don't loop back trying to read more data.  Rather, we just
    // let CFSocket call us again.
}

static void SocketReadCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
// This C routine is called by CFSocket when there's data waiting on our
// ICMP socket.  It just redirects the call to Objective-C code.
{
    SCIcmpPacketUtility*    obj;
    
    obj = (__bridge SCIcmpPacketUtility*) info;
    assert([obj isKindOfClass:[SCIcmpPacketUtility class]]);
    
#pragma unused(s)
    assert(s == obj->_socket);
#pragma unused(type)
    assert(type == kCFSocketReadCallBack);
#pragma unused(address)
    assert(address == nil);
#pragma unused(data)
    assert(data == nil);
    
    [obj _readData];
}

- (BOOL)_isValidResponsePacket:(NSMutableData *)packet
//Not sure if we really need this since we return any kind now
{
    //    BOOL                result;
    //    NSUInteger          icmpHeaderOffset;
    //    ICMPHeader *        icmpPtr;
    //    ICMPErrorPacket *   errorPtr;
    //    uint16_t            receivedChecksum;
    //    uint16_t            calculatedChecksum;
    //
    //    result = NO;
    //
    //    icmpHeaderOffset = [[self class] _icmpHeaderOffsetInPacket:packet];
    //
    //    if (icmpHeaderOffset != NSNotFound) {
    //
    //        icmpPtr = (struct ICMPHeader *) (((uint8_t *)[packet mutableBytes]) + icmpHeaderOffset);
    //
    //
    //        if (icmpPtr->type == kICMPTimeExceeded) {
    //            errorPtr = (struct ICMPErrorPacket *)((uint8_t *)[packet bytes]);
    //            receivedChecksum = errorPtr->checksum;
    //            errorPtr->checksum = 0;
    //            calculatedChecksum = in_cksum(errorPtr, [packet length] - icmpHeaderOffset);
    //            errorPtr->checksum = receivedChecksum;
    //
    //        } else {
    //            receivedChecksum   = icmpPtr->checksum;
    //            icmpPtr->checksum  = 0;
    //            calculatedChecksum = in_cksum(icmpPtr, [packet length] - icmpHeaderOffset);
    //            icmpPtr->checksum  = receivedChecksum;
    //        }
    //
    //        if (receivedChecksum == calculatedChecksum) {
    //            NSLog(@"YAY");
    //            result = YES;
    //        }
    //    }
    
    return YES;
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
