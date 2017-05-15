package com.peer1.internetmap.utils;

import android.os.AsyncTask;
import android.util.Log;

import com.peer1.internetmap.utils.opennms.ICMPHeader;
import com.peer1.internetmap.utils.opennms.OC16ChecksumProducer;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Date;
import java.util.Random;

import timber.log.Timber;

/**
 * Created by shayla on 2017-05-12.
 *
 *
 * Existing app: Visual Traceroute will show you, on a map, the path your data travels to any server in the world. Very easy to use, just enter the server’s name and press go.
 * Visual Traceroute will use the ‘ping’ command available on most devices to determine the path your data travels, and will then use a database to look up the geographic location of this path.
 * If your device is rooted, Visual Traceroute will use ‘nmap’ instead of ‘ping’, which provides for better and faster (UDP based) host detection.
 * Some routers block ‘ping’ (ICMP), and you will need a rooted device in this case. Some devices do not have ‘ping’ installed on them, and you will need a rooted device in this case too. The app will notify you in this case.
 */

public class PacketUtil {

    private final String TAG = "Traceroute";

    public interface EventListener {
        void onStartWithAddress();
        void receivedResponsePacket(byte[] packet, Date arrivedAt);
        //void receivedUnexpectedPacket(byte packet, Date arrivedAt);
    }

    private EventListener listener;

    private String targetAddress;
    private short nextSequenceNumber;
    private ArrayList<PacketRecord> packetRecords;

    private DatagramSocket socket;

//    @property (nonatomic, assign, readwrite) id<SCIcmpPacketUtilityDelegate> delegate;
//    @property (nonatomic, copy,   readonly) NSData*               targetAddress;
//    @property (nonatomic, copy, readwrite) NSString*             targetAddressString;
//    @property (nonatomic, assign, readonly) uint16_t              nextSequenceNumber;
//    @property (strong, nonatomic, readonly) NSMutableArray*       packetRecords;


    public PacketUtil() {
        targetAddress = null;
        nextSequenceNumber = 0;
        packetRecords = new ArrayList<PacketRecord>();

        setListener(new EventListener() {
            public void onStartWithAddress() {
                // Do nothing.
            }
            public void receivedResponsePacket(byte[] packet, Date arrivedAt) {
                // Do nothing.
            }
        });
    }

    public PacketUtil initWithAddress(String hostAddress) {
        targetAddress = hostAddress;
        return this;
    }

    public PacketUtil setListener(EventListener listener) {
        this.listener = listener;
        return this;
    }

    public void start() {
        if (targetAddress == null) {
            // TODO error
        } else {
            startWithHostAddress();
        }
    }

    public void stop() {
        if (socket != null) {
            // TODO close may not be good enough and may throw SocketException
            socket.close();
        }
    }

    private void startWithHostAddress() {

        if (targetAddress == null) {
            // TODO error
            return;
        }

        int err;
        int fd;
        // const struct sockaddr * addrPtr;

        // TODO determine addr type AF_INET
//        switch (addrPtr->sa_family) {
//            case AF_INET: {
//                fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
//
//                if (fd < 0) {
//                    err = errno;
//                }
//            } break;
//            case AF_INET6:
//                assert(NO);
//                // fall through
//            default: {
//                err = EPROTONOSUPPORT;
//            } break;
//        }

        // Open socket
        try {
            socket = new DatagramSocket();
        } catch (SocketException e) {
            // TODO
            e.printStackTrace();
            return;
        }

        // TODO do we need to run on a run loop?

        // Inform listener that socket has been correctly created.
        listener.onStartWithAddress();

//
//        if (err != 0) {
//        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
//        } else {
//            CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
//            CFRunLoopSourceRef  rls;
//
//            // Wrap it in a CFSocket and schedule it on the runloop.
//
//            self->_socket = CFSocketCreateWithNative(NULL, fd, kCFSocketReadCallBack, SocketReadCallback, &context);
//            assert(self->_socket != NULL);
//
//            // The socket will now take care of clean up our file descriptor.
//
//            assert( CFSocketGetSocketFlags(self->_socket) & kCFSocketCloseOnInvalidate );
//            fd = -1;
//
//            rls = CFSocketCreateRunLoopSource(NULL, self->_socket, 0);
//            assert(rls != NULL);
//
//            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
//
//            CFRelease(rls);
//
//            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didStartWithAddress:)] ) {
//            [self.delegate SCIcmpPacketUtility:self didStartWithAddress:self.targetAddress];
//            }
//        }
//        assert(fd == -1);




//        int err;
//        int fd;
//
//        DatagramPacket sendPacket;
//
//        int port = 9001;
//
//        // Send
//        try {
//            byte[] msg = new byte[4096];
//            InetAddress serverAddr = InetAddress.getByName(targetAddress);
//
//            // TODO is there a way to determine type (ie. AF_INET, AF_INET6 etc...)?
//            // DO we need to do anything special here?
//
//            socket = new DatagramSocket();
//            sendPacket = new DatagramPacket(msg, msg.length, serverAddr, port);
//            socket.send(sendPacket);
////            byte[] response = new byte[4096];
////            receivePacket = new DatagramPacket(response, response.length);
////            socket.receive(receivePacket);
////
////            String result = new String(response, 0, response.length);
////            Log.v(TAG, result);
//
//
//        } catch (Exception e) {
//            Log.v(TAG, "Newp: " + e.getMessage());
//        }
//
//        // Read
    //    readData();
    }

//    - (void)_startWithHostAddress
//    {
//        int                     err;
//        int                     fd;
//    const struct sockaddr * addrPtr;
//
//        assert(self.targetAddress != nil);
//
//        // Open the socket.
//
//        addrPtr = (const struct sockaddr *) [self.targetAddress bytes];
//
//        fd = -1;
//        err = 0;
//        switch (addrPtr->sa_family) {
//            case AF_INET: {
//                fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
//
//                if (fd < 0) {
//                    err = errno;
//                }
//            } break;
//            case AF_INET6:
//                assert(NO);
//                // fall through
//            default: {
//                err = EPROTONOSUPPORT;
//            } break;
//        }
//
//        if (err != 0) {
//        [self _didFailWithError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
//        } else {
//            CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
//            CFRunLoopSourceRef  rls;
//
//            // Wrap it in a CFSocket and schedule it on the runloop.
//
//            self->_socket = CFSocketCreateWithNative(NULL, fd, kCFSocketReadCallBack, SocketReadCallback, &context);
//            assert(self->_socket != NULL);
//
//            // The socket will now take care of clean up our file descriptor.
//
//            assert( CFSocketGetSocketFlags(self->_socket) & kCFSocketCloseOnInvalidate );
//            fd = -1;
//
//            rls = CFSocketCreateRunLoopSource(NULL, self->_socket, 0);
//            assert(rls != NULL);
//
//            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
//
//            CFRelease(rls);
//
//            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didStartWithAddress:)] ) {
//            [self.delegate SCIcmpPacketUtility:self didStartWithAddress:self.targetAddress];
//            }
//        }
//        assert(fd == -1);
//    }


    public void sendPacketWithData() {
        sendPacketWithData(1);
    }

    public void sendPacketWithData(final int ttl) {

        AsyncTask<Void, Void, Void> sendPacketTask = new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {

                DatagramPacket sendPacket;
                int err;
                String payload;
                ICMPHeader icmpHeader;
                int bytesSent;

//        int             err;
//        NSData *        payload;
//        NSMutableData * packet;
//        ICMPHeader *    icmpPtr;
//        ssize_t         bytesSent;


                payload = String.format("%d bottles of beer on the wall", 99 - nextSequenceNumber);
//
//        payload = data;
//        if (payload == nil) {
//            payload = [[NSString stringWithFormat:@"%28zd bottles of beer on the wall", (ssize_t) 99 - (size_t) (self.nextSequenceNumber % 100) ] dataUsingEncoding:NSASCIIStringEncoding];
//            assert(payload != nil);
//            assert([payload length] == 56);
//        }

                Random rand = new Random();
                short id = (short) rand.nextInt(Short.MAX_VALUE + 1);
                short seq = (short) nextSequenceNumber;
                byte zero = 0;

                icmpHeader = new ICMPHeader(payload.getBytes(), 0);
                icmpHeader.setM_type(ICMPHeader.TYPE_ECHO_REQUEST);
                icmpHeader.setCode(zero);
                icmpHeader.setM_checksum(zero);
                icmpHeader.setM_ident(id);
                icmpHeader.setM_sequence(seq);

                //        packet = [NSMutableData dataWithLength:sizeof(*icmpPtr) + [payload length]];
//        assert(packet != nil);
//
//        icmpPtr = [packet mutableBytes];
//        icmpPtr->type = kICMPTypeEchoRequest;
//        icmpPtr->code = 0;
//        icmpPtr->checksum = 0;
//        icmpPtr->identifier = (uint16_t) arc4random();
//        icmpPtr->sequenceNumber = OSSwapHostToBigInt16(self.nextSequenceNumber);

                // TODO do ... this?
                //
//        memcpy(&icmpPtr[1], [payload bytes], [payload length]);
//
//        // The IP checksum returns a 16-bit number that's already in correct byte order
//        // (due to wacky 1's complement maths), so we just put it into the packet as a
//        // 16-bit unit.
//

                icmpHeader.computeChecksum();
//        icmpPtr->checksum = in_cksum([packet bytes], [packet length]);


                if (socket == null) {
                    // Problem
                    bytesSent = -1;
                    err = ICMPHeader.CODE_BAD_IP_HEADER; // TODO different error?
                } else {

                    // Get targetAddress
                    InetAddress serverAddr;
                    try {
                        serverAddr = InetAddress.getByName(targetAddress);
                    } catch (UnknownHostException e) {
                        e.printStackTrace();
                        return null;
                    }

                    // Setup socket
                    try {
                        socket = new DatagramSocket();
                    } catch (SocketException e) {
                        e.printStackTrace();
                        return null;
                    }

                    // Create DatagramPacket using ICMP message
                    byte[] message = icmpHeader.toBytes();
                    Date now = new Date();
                    sendPacket = new DatagramPacket(message, message.length, serverAddr, 1);

                    // Send!
                    try {
                        socket.send(sendPacket);
                        // TODO how to verify send was successul?
                        // If we did not crash, then the send was a success?

                        // Track the packet
                        PacketRecord packetRecord = new PacketRecord();
                        packetRecord.sentWithTTL = ttl;
                        packetRecord.departure = now;
                        packetRecord.sequenceNumber = nextSequenceNumber;

                        packetRecords.add(packetRecord);

                    } catch (IOException e) {
                        err = 0; // TODO what is errno?
                        e.printStackTrace();
                        return null;
                    }

                    // Handle the results


                    // // Handle the results of the send.

//            if ((bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length]) ) {
//
//                // Succcess: Tell the client, woop woop
//
//                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didSendPacket:)] ) {
//            [self.delegate SCIcmpPacketUtility:self didSendPacket:packet];
//                }
//            } else {
//                NSError*   error;
//
//                // Some sort of failure.  Tell the client.
//
//                if (err == 0) {
//                    err = ENOBUFS;          // This is not a hugely descriptor error, alas.
//                }
//                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
//                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didFailToSendPacket:error:)] ) {
//            [self.delegate SCIcmpPacketUtility:self didFailToSendPacket:packet error:error];
//                }
//            }
//
//            self.nextSequenceNumber += 1;


                    // int port = 9001;
                    int msgBufferSize = 65535; // 65535 is the maximum IP packet size, which seems like a reasonable bound
                    byte[] msgBuffer = new byte[msgBufferSize];


//        struct sockaddr_storage addr;
//        socklen_t               addrLen;
//        ssize_t                 bytesRead;
//        void *                  buffer;
//        enum { kBufferSize = 65535 };

//        // 65535 is the maximum IP packet size, which seems like a reasonable bound
//        // here (plus it's what <x-man-page://8/ping> uses).

//        buffer = malloc(kBufferSize);
//        assert(buffer != NULL);
//
                    // Actually read the data.
                    DatagramPacket receivePacket = new DatagramPacket(msgBuffer, msgBufferSize);
                    Date receivedDate;

                    try {
                        socket.setSoTimeout(10000);
                        socket.receive(receivePacket);
                        receivedDate = new Date();

//        NSDate* now = [NSDate date]; //Pass this up to the delegate in case we care about RTT
//        addrLen = sizeof(addr);
//        bytesRead = recvfrom(CFSocketGetNative(self->_socket), buffer, kBufferSize, 0, (struct sockaddr *) &addr, &addrLen);
                    } catch (SocketTimeoutException e) {
                        // resend
                        Timber.e("sendPacketWithData receive SocketTimeoutException: " + e.getMessage());
                        return null;
                    } catch (IOException e) {
                        e.printStackTrace();
                        Timber.e("sendPacketWithData receive IOException: " + e.getMessage());
                        // TODO log error
                        err = 1;
                        return null;
                    }

                    // Convert data
                    String result = new String(msgBuffer, 0, msgBuffer.length);

                    Log.v(TAG, result);

                    if (isValidResponsePacket(msgBuffer)) {
                        listener.receivedResponsePacket(msgBuffer, receivedDate);
                    } else {
                        // TODO, since isValidResponsePacket always returns true, we should not get here yet.
                        //                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didReceiveUnexpectedPacket:)] ) {
//                [self.delegate SCIcmpPacketUtility:self didReceiveUnexpectedPacket:packet];
                    }


//            if ( [self _isValidResponsePacket:packet] ) {
//                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didReceiveResponsePacket:arrivedAt:)] ) {
//                [self.delegate SCIcmpPacketUtility:self didReceiveResponsePacket:packet arrivedAt:now];
//                }
//            } else {
//                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(SCIcmpPacketUtility:didReceiveUnexpectedPacket:)] ) {
//                [self.delegate SCIcmpPacketUtility:self didReceiveUnexpectedPacket:packet];
//                }
//            }

                    // TODO clear buffer?
//        free(buffer);
//
//        // Note that we don't loop back trying to read more data.  Rather, we just
//        // let CFSocket call us again.


                    return null;
                }

                return null;
            }

        };

        sendPacketTask.execute();
    }



        //        try {
//            byte[] msg = new byte[4096];
//            InetAddress serverAddr = InetAddress.getByName(targetAddress);
//
//            // TODO is there a way to determine type (ie. AF_INET, AF_INET6 etc...)?
//            // DO we need to do anything special here?
//
//            socket = new DatagramSocket();
//            sendPacket = new DatagramPacket(msg, msg.length, serverAddr, port);
//
//            socket.send(sendPacket);
//            byte[] response = new byte[4096];
//            receivePacket = new DatagramPacket(response, response.length);
//            socket.receive(receivePacket);
//
//            String result = new String(response, 0, response.length);
//            Log.v(TAG, result);
//
//
//        } catch (Exception e) {
//            Log.v(TAG, "Newp: " + e.getMessage());
//        }

    private boolean isValidResponsePacket(byte[] packet) {
        // iOS does no validation at the moment.
        return true;
    }

    public class PacketRecord {
        public short sequenceNumber;
        public int sentWithTTL;
        public String v;
        public Date departure;
        public Date arrival;
        public float rtt;
        public boolean timedOut;
    }

}
