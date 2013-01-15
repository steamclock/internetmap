////
////  SCPacketUtility.m
////  SCPacketUtility
////
////  Created by Angelina Fabbro on 12-12-07.
////  Copyright (c) 2012 Steamclock Software. All rights reserved.
////
//
//#import "SCPacketUtility.h"
//
//#include <sys/socket.h>
//#include <netinet/in.h>
//#include <errno.h>
//
//
//
//#pragma - SCPacketUtility
//
//@interface SCPacketUtility ()
//
//@property (nonatomic, copy,   readwrite) NSData*    hostAddress;
//@property (nonatomic, assign, readwrite) uint16_t   nextSequenceNumber;
//@property (nonatomic, strong) NSMutableDictionary*    packetDepartureTimes;
//
//- (void)_stopHostResolution;
//- (void)_stopDataTransfer;
//
//@end
//
//@implementation SCPacketUtility
//
//- (id)initWithHostName:(NSString*)hostName address:(NSData *)hostAddress
//// The initialiser common to both of our construction class methods.
//{
//    assert( (hostName != nil) == (hostAddress == nil) );
//    self = [super init];
//    if (self != nil) {
//        self->_hostName    = [hostName copy];
//        self->_hostAddress = [hostAddress copy];
//        self->_identifier  = (uint16_t) arc4random();
//        self.packetDepartureTimes = [[NSMutableDictionary alloc] init];
//    }
//    return self;
//}
//
//+ (SCPacketUtility*)utilityWithHostName:(NSString *)hostName
//// See comment in header.
//{
//    return [[SCPacketUtility alloc] initWithHostName:hostName address:nil];
//}
//
//+ (SCPacketUtility*)utilityWithHostAddress:(NSData*)hostAddress
//// See comment in header.
//{
//    return [[SCPacketUtility alloc] initWithHostName:NULL address:hostAddress];
//}
//
//- (void)_didFailWithError:(NSError *)error
//// Shut down the tracer object and tell the delegate about the error.
//{
//    assert(error != nil);
//
//    [self stop];
//    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCPacketUtility:didFailWithError:)] ) {
//        [self.delegate SCPacketUtility:self didFailWithError:error];
//    }
//}
//
//- (void)_didFailWithHostStreamError:(CFStreamError)streamError
//// Convert the CFStreamError to an NSError and then call through to
//// -_didFailWithError: to shut down the tracer object and tell the
//// delegate about the error.
//{
//    NSDictionary*  userInfo;
//    NSError*       error;
//    
//    if (streamError.domain == kCFStreamErrorDomainNetDB) {
//        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                    [NSNumber numberWithInteger:streamError.error], kCFGetAddrInfoFailureKey,
//                    nil];
//    } else {
//        userInfo = nil;
//    }
//    error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:userInfo];
//    assert(error != nil);
//    
//    [self _didFailWithError:error];
//}
//
//- (void)_sendPacketWithData:(NSData *)data withTTL:(int)ttl{
//    [self _sendICMPPacket:data withTTL:ttl];
//}
//
//-(void)_sendICMPPacket:(NSData *)data withTTL:(int)ttl{
//    
//    int             err;
//    NSData *        payload;
//    NSMutableData * packet;
//    ICMPHeader *    icmpPtr;
//    ssize_t         bytesSent;
//    
//    // Construct the traceroute packet.
//    
//    payload = data;
//    if (payload == nil) {
//        payload = [[NSString stringWithFormat:@"%28zd bottles of beer on the wall", (ssize_t) 99 - (size_t) (self.nextSequenceNumber % 100) ] dataUsingEncoding:NSASCIIStringEncoding];
//        assert(payload != nil);
//        assert([payload length] == 56);
//    }
//    
//    packet = [NSMutableData dataWithLength:sizeof(*icmpPtr) + [payload length]];
//    assert(packet != nil);
//    
//    icmpPtr = [packet mutableBytes];
//    icmpPtr->type = kICMPTypeEchoRequest;
//    icmpPtr->code = 0;
//    icmpPtr->checksum = 0;
//    icmpPtr->identifier     = OSSwapHostToBigInt16(self.identifier);
//    icmpPtr->sequenceNumber = OSSwapHostToBigInt16(self.nextSequenceNumber);
//
//    memcpy(&icmpPtr[1], [payload bytes], [payload length]);
//    
//    // The IP checksum returns a 16-bit number that's already in correct byte order
//    // (due to wacky 1's complement maths), so we just put it into the packet as a
//    // 16-bit unit.
//    
//    icmpPtr->checksum = in_cksum([packet bytes], [packet length]);
//    
//    // Send the packet.
//    
//    if (self->_socket == NULL) {
//        bytesSent = -1;
//        err = EBADF;
//    } else {
//        
//        if (!ttl) {
//            ttl = 1;
//        }
//        
//        int test = setsockopt(CFSocketGetNative(self->_socket), IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl));
//        if (test < 0) {
//            err = errno;
//            NSLog(@"%s", strerror(err));
//        }
//        
//        // Store departure time for packet sequence number to calculate RTT if desired
//        NSDate* now = [NSDate date];
//        [self.packetDepartureTimes setValue:now forKey:[NSString stringWithFormat:@"%d", self.nextSequenceNumber]];
//        
//        bytesSent = sendto(
//                           CFSocketGetNative(self->_socket),
//                           [packet bytes],
//                           [packet length],
//                           0,
//                           (struct sockaddr *) [self.hostAddress bytes],
//                           (socklen_t) [self.hostAddress length]
//                           );
//        err = 0;
//        if (bytesSent < 0) {
//            err = errno;
//        }
//    }
//    
//    // Handle the results of the send.
//    
//    if ( (bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length]) ) {
//        
//        // Complete success.  Tell the client.
//        
//        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCPacketUtility:didSendPacket:)] ) {
//            [self.delegate SCPacketUtility:self didSendPacket:packet];
//        }
//    } else {
//        NSError*   error;
//        
//        // Some sort of failure.  Tell the client.
//        
//        if (err == 0) {
//            err = ENOBUFS;          // This is not a hugely descriptor error, alas.
//        }
//        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
//        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCPacketUtility:didFailToSendPacket:error:)] ) {
//            [self.delegate SCPacketUtility:self didFailToSendPacket:packet error:error];
//        }
//    }
//    
//    self.nextSequenceNumber += 1;
//}
//
//-(void)sendUDPPacket:(NSData *)data withTTL:(int)ttl{
//    NSLog(@"I should send a UDP packet nao.");
//}
//
//+ (NSUInteger)_icmpHeaderOffsetInPacket:(NSData *)packet
//// Returns the offset of the ICMPHeader within an IP packet.
//{
//    NSUInteger              result;
//    const struct IPHeader * ipPtr;
//    size_t                  ipHeaderLength;
//    
//    result = NSNotFound;
//    if ([packet length] >= (sizeof(IPHeader) + sizeof(ICMPHeader))) {
//        ipPtr = (const IPHeader *) [packet bytes];
//        assert((ipPtr->versionAndHeaderLength & 0xF0) == 0x40);     // IPv4
//        assert(ipPtr->protocol == 1);                               // ICMP
//        ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);
//        if ([packet length] >= (ipHeaderLength + sizeof(ICMPHeader))) {
//            result = ipHeaderLength;
//        }
//    }
//    return result;
//}
//
//+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet
//// See comment in header.
//{
//    const struct ICMPHeader *   result;
//    NSUInteger                  icmpHeaderOffset;
//    
//    result = nil;
//    icmpHeaderOffset = [self _icmpHeaderOffsetInPacket:packet];
//    if (icmpHeaderOffset != NSNotFound) {
//        result = (const struct ICMPHeader *) (((const uint8_t *)[packet bytes]) + icmpHeaderOffset);
//    }
//    
//    
//    return result;
//}
//
//
//- (BOOL)_isValidResponsePacket:(NSMutableData *)packet
////Not sure if we really need this since we return any kind now
//{
////    BOOL                result;
////    NSUInteger          icmpHeaderOffset;
////    ICMPHeader *        icmpPtr;
////    ICMPErrorPacket *   errorPtr;
////    uint16_t            receivedChecksum;
////    uint16_t            calculatedChecksum;
////    
////    result = NO;
////    
////    icmpHeaderOffset = [[self class] _icmpHeaderOffsetInPacket:packet];
////    
////    if (icmpHeaderOffset != NSNotFound) {
////        
////        icmpPtr = (struct ICMPHeader *) (((uint8_t *)[packet mutableBytes]) + icmpHeaderOffset);
////        
////        
////        if (icmpPtr->type == kICMPTimeExceeded) {
////            errorPtr = (struct ICMPErrorPacket *)((uint8_t *)[packet bytes]);
////            receivedChecksum = errorPtr->checksum;
////            errorPtr->checksum = 0;
////            calculatedChecksum = in_cksum(errorPtr, [packet length] - icmpHeaderOffset);
////            errorPtr->checksum = receivedChecksum;
////            
////        } else {
////            receivedChecksum   = icmpPtr->checksum;
////            icmpPtr->checksum  = 0;
////            calculatedChecksum = in_cksum(icmpPtr, [packet length] - icmpHeaderOffset);
////            icmpPtr->checksum  = receivedChecksum;
////        }
////        
////        if (receivedChecksum == calculatedChecksum) {
////            NSLog(@"YAY");
////            result = YES;
////        }
////    }
//    
//    return YES;
//}
//
//- (void)_readData{
//// Called by the socket handling code (SocketReadCallback) to process a message waiting on the socket
//    int                     err;
//    struct sockaddr_storage addr;
//    socklen_t               addrLen;
//    ssize_t                 bytesRead;
//    void *                  buffer;
//    enum { kBufferSize = 65535 };
//    
//    // 65535 is the maximum IP packet size, which seems like a reasonable bound
//    // here (plus it's what <x-man-page://8/ping> uses).
//    
//    buffer = malloc(kBufferSize);
//    assert(buffer != NULL);
//    
//    // Actually read the data.
//    
//    addrLen = sizeof(addr);
//    bytesRead = recvfrom(CFSocketGetNative(self->_socket), buffer, kBufferSize, 0, (struct sockaddr *) &addr, &addrLen);
//    err = 0;
//    if (bytesRead < 0) {
//        err = errno;
//    }
//    
//    // Process the data we read.
//    
//    if (bytesRead > 0) {
//        NSMutableData *     packet;
//        
//        packet = [NSMutableData dataWithBytes:buffer length:bytesRead];
//        assert(packet != nil);
//        
//        // We got some data, pass it up to our client.
//        
//        if ( [self _isValidResponsePacket:packet] ) {
//            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCPacketUtility:didReceiveResponsePacket:)] ) {
//                [self.delegate SCPacketUtility:self didReceiveResponsePacket:packet];
//            }
//        } else {
//            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCPacketUtility:didReceiveUnexpectedPacket:)] ) {
//                [self.delegate SCPacketUtility:self didReceiveUnexpectedPacket:packet];
//            }
//        }
//    } else {
//        
//        // We failed to read the data, so shut everything down.
//        
//        if (err == 0) {
//            err = EPIPE;
//        }
//        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
//    }
//    
//    free(buffer);
//    
//    // Note that we don't loop back trying to read more data.  Rather, we just
//    // let CFSocket call us again.
//}
//
//static void SocketReadCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
//// This C routine is called by CFSocket when there's data waiting on our
//// ICMP socket.  It just redirects the call to Objective-C code.
//{
//    SCPacketUtility*    obj;
//    
//    obj = (__bridge SCPacketUtility*) info;
//    assert([obj isKindOfClass:[SCPacketUtility class]]);
//    
//#pragma unused(s)
//    assert(s == obj->_socket);
//#pragma unused(type)
//    assert(type == kCFSocketReadCallBack);
//#pragma unused(address)
//    assert(address == nil);
//#pragma unused(data)
//    assert(data == nil);
//    
//    [obj _readData];
//}
//
//- (void)_startWithHostAddress
//// We have a host address, so let's actually start pinging it.
//{
//    int                     err;
//    int                     fd;
//    const struct sockaddr * addrPtr;
//    
//    assert(self.hostAddress != nil);
//    
//    // Open the socket.
//    
//    addrPtr = (const struct sockaddr *) [self.hostAddress bytes];
//    
//    fd = -1;
//    err = 0;
//    switch (addrPtr->sa_family) {
//        case AF_INET: {
//            fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
//
//            if (fd < 0) {
//                err = errno;
//            }
//        } break;
//        case AF_INET6:
//            assert(NO);
//            // fall through
//        default: {
//            err = EPROTONOSUPPORT;
//        } break;
//    }
//    
//    if (err != 0) {
//        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
//    } else {
//        CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
//        CFRunLoopSourceRef  rls;
//        
//        // Wrap it in a CFSocket and schedule it on the runloop.
//        
//
//
//        self->_socket = CFSocketCreateWithNative(NULL, fd, kCFSocketReadCallBack, SocketReadCallback, &context);
//        assert(self->_socket != NULL);
//        
//        // The socket will now take care of clean up our file descriptor.
//        
//        assert( CFSocketGetSocketFlags(self->_socket) & kCFSocketCloseOnInvalidate );
//        fd = -1;
//        
//        rls = CFSocketCreateRunLoopSource(NULL, self->_socket, 0);
//        assert(rls != NULL);
//        
//        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
//        
//        CFRelease(rls);
//        
//        if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCPacketUtility:didStartWithAddress:)] ) {
//            [self.delegate SCPacketUtility:self didStartWithAddress:self.hostAddress];
//        }
//    }
//    assert(fd == -1);
//}
//
//- (void)_hostResolutionDone
//// Called by our CFHost resolution callback (HostResolveCallback) when host
//// resolution is complete.  We just latch the first IPv4 address and kick
//// off the pinging process.
//{
//    Boolean     resolved;
//    NSArray *   addresses;
//    
//    // Find the first IPv4 address.
//    
//    addresses = (__bridge NSArray *) CFHostGetAddressing(self->_host, &resolved);
//    if ( resolved && (addresses != nil) ) {
//        resolved = false;
//        for (NSData * address in addresses) {
//            const struct sockaddr * addrPtr;
//            
//            addrPtr = (const struct sockaddr *) [address bytes];
//            if ( [address length] >= sizeof(struct sockaddr) && addrPtr->sa_family == AF_INET) {
//                self.hostAddress = address;
//                resolved = true;
//                break;
//            }
//        }
//    }
//    
//    // We're done resolving, so shut that down.
//    
//    [self _stopHostResolution];
//    
//    // If all is OK, start sending, otherwise shut it down
//    
//    if (resolved) {
//        [self _startWithHostAddress];
//    } else {
//        [self _didFailWithError:[NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorHostNotFound userInfo:nil]];
//    }
//}
//
//static void HostResolveCallback(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
//// This C routine is called by CFHost when the host resolution is complete.
//// It just redirects the call to the appropriate Objective-C method.
//{
//    SCPacketUtility*  obj;
//    
//    obj = (__bridge SCPacketUtility*)info;
//    assert([obj isKindOfClass:[SCPacketUtility class]]);
//    
//#pragma unused(theHost)
//    assert(theHost == obj->_host);
//#pragma unused(typeInfo)
//    assert(typeInfo == kCFHostAddresses);
//    
//    if ( (error != NULL) && (error->domain != 0) ) {
//        [obj _didFailWithHostStreamError:*error];
//    } else {
//        [obj _hostResolutionDone];
//    }
//}
//
//- (void)start
//// See comment in header.
//{
//    // If the user supplied us with an address, just start pinging that.  Otherwise
//    // start a host resolution.
//    
//    if (self->_hostAddress != nil) {
//        [self _startWithHostAddress];
//    } else {
//        Boolean             success;
//        CFHostClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
//        CFStreamError       streamError;
//        
//        assert(self->_host == NULL);
//        
//        self->_host = CFHostCreateWithName(NULL, (__bridge CFStringRef) self.hostName);
//        assert(self->_host != NULL);
//        
//        CFHostSetClient(self->_host, HostResolveCallback, &context);
//        
//        CFHostScheduleWithRunLoop(self->_host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
//        
//        success = CFHostStartInfoResolution(self->_host, kCFHostAddresses, &streamError);
//        if ( ! success ) {
//            [self _didFailWithHostStreamError:streamError];
//        }
//    }
//}
//
//- (void)_stopHostResolution
//// Shut down the CFHost.
//{
//    if (self->_host != NULL) {
//        CFHostSetClient(self->_host, NULL, NULL);
//        CFHostUnscheduleFromRunLoop(self->_host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
//        CFRelease(self->_host);
//        self->_host = NULL;
//    }
//}
//
//- (void)_stopDataTransfer
//// Shut down anything to do with sending and receiving pings.
//{
//    if (self->_socket != NULL) {
//        CFSocketInvalidate(self->_socket);
//        CFRelease(self->_socket);
//        self->_socket = NULL;
//    }
//}
//
//- (void)stop
//// See comment in header.
//{
//    [self _stopHostResolution];
//    [self _stopDataTransfer];
//    
//    // If we were started with a host name, junk the host address on stop.  If the
//    // client calls -start again, we'll re-resolve the host name.
//    
//    if (self.hostName != nil) {
//        self.hostAddress = NULL;
//    }
//}
//
//
//
//
//
//@end
