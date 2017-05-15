package com.peer1.internetmap.utils;

import com.peer1.internetmap.utils.opennms.ICMPHeader;

import java.util.ArrayList;
import java.util.Date;

/**
 * Created by shayla on 2017-05-12.
 *
 * Traceroute works by sending 3 ICMP messages via UDP to an unlikely port number, starts a timer each time, and setting the TTL in the datagram to 1 (max 1 hop).
 * When it reaches the first router, the datagram expires and the router will refuse to send the packet any farther and respond with a expired message (ICMP type 11 code 0)
 * that includes the routers name, IP address, MTU, and a few other bits of data. The source will obtain the round trip time from the timer. Once traceroute gets the data from the first hop,
 * it will repeat these steps but increment the TTL by one, and keep repeating these steps until it finally gets to the host itself.
 *
 * In order for your code to work, you need to be able to manipulate the network layer datagram and set the TTL value in the header. After that it's just a matter of parsing out the
 * responses from each router that returns a TTL expired message.
 */

public class TracerouteUtil implements PacketUtil.EventListener {

//    @property (nonatomic, strong) SCIcmpPacketUtility* packetUtility;
//    @property int ttlCount;
//    @property int timesExceededForHop;
//    @property int totalHopsTimedOut; // If we hit 4, bail, otherwise it's boring for the user.

    static private final int MAX_HOPS = 30;
    static private final int PACKETS_PER_ITER = 1; // How many packets we send each time we increase the TTL

    public interface InteractionListener {
        void tracerouteTimedOut();

    }

    private InteractionListener listener;
    private PacketUtil packetUtil;
    private int ttlCount;
    private int timesExeededForHop;
    private int totalHopsTimedOut;

//    @property (nonatomic, strong) NSString *targetIP;
//    @property (nonatomic, strong) NSString *lastIP;
//    @property (nonatomic, strong) NSMutableArray  *hopsForCurrentIP;

    private String targetIp;
    private String lastIp;
    private ArrayList<String> hopsForCurrentIp;


    public TracerouteUtil() {
        ttlCount = 1;
        timesExeededForHop = 0;
        totalHopsTimedOut = 0;
        hopsForCurrentIp = new ArrayList<String>();
        // Don't set packetUtil until we start (to get address)
    }

    public TracerouteUtil initWithAddress(String hostAddress) {
        targetIp = hostAddress;
        return this;
    }

    public TracerouteUtil setListener(InteractionListener listener) {
        this.listener = listener;
        return this;
    }

    public void start() {
        if (packetUtil == null) {
            packetUtil = new PacketUtil()
                    .initWithAddress(targetIp)
                    .setListener(this);
        }

        packetUtil.start();
    }

    public void stop() {
        if (packetUtil != null) {
            packetUtil.stop();
        }

        ttlCount = 1;
        packetUtil = null;
//        self.ttlCount = 1;
//    [self.packetUtility stop];
//        self.packetUtility = nil;
    }

    private void sendPackets() {

        if (ttlCount <= MAX_HOPS) {
            for (int i=1; i <= PACKETS_PER_ITER; i++) {
                packetUtil.sendPacketWithData(ttlCount);
            }
        } else {
            if (listener != null) {
                listener.tracerouteTimedOut();
            }
        }

        //    #pragma mark - Send packets
//- (void)sendPackets:(NSData*)data{
//
//        //NSLog(@"Sending a batch of packets..");
//        if (self.ttlCount <= MAX_HOPS) {
//            for (int i = 1; i <= PACKETS_PER_ITER; i++) {
//            [self.packetUtility sendPacketWithData:nil andTTL:self.ttlCount];
//            }
//        } else if (self.ttlCount > MAX_HOPS) {
//            if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidTimeout:)]) {
//            [self.delegate tracerouteDidTimeout:self.hopsForCurrentIP];
//            }
//        }
//    }

    }

   // private byte processErrorICMPPacket(ICMPHeader icmpPacket) {




//        -(void)processErrorICMPPacket:(NSData *)packet arrivedAt:(NSDate*)dateTime{
//            // Get sequence number
//            NSInteger sequenceNumber = [self getSequenceNumberForPacket:packet];
//
//            //Get IP for machine the packet originated from
//            NSString* ipInPacket = [self getIpFromIPHeader:packet];
//
//            //Tracks number of packets we've received that are from the same sequence number
//            int numberOfRepliesForSequenceNumber = 0;
//
//            //Tracks the number of packets we've received that are from the same IP
//            int numberOfRepliesForIP = 0;
//
//            for (SCPacketRecord* packetRecord in self.packetUtility.packetRecords) {
//                if (packetRecord.sequenceNumber == sequenceNumber) {
//                    numberOfRepliesForSequenceNumber++;
//                }
//            }
//
//            BOOL doneTraceroute = NO;
//
//            for (SCPacketRecord* packetRecord in self.packetUtility.packetRecords) {
//                if ((numberOfRepliesForIP == 0) && (numberOfRepliesForSequenceNumber == 1)) {
//
//            [NSObject cancelPreviousPerformRequestsWithTarget:self];
//
//                    // Handles first packet back for a sequence numnber
//
//                    numberOfRepliesForIP++;
//
//                    // Record the time the packet arrived & rtt
//                    packetRecord.arrival = dateTime;
//                    packetRecord.rtt = [packetRecord.arrival timeIntervalSinceDate:packetRecord.departure] * 1000;
//                    packetRecord.responseAddress = ipInPacket;
//
//                    // Report find
//            [self foundNewIP:ipInPacket withReport:[NSString stringWithFormat:@"%@  %.2fms", ipInPacket, packetRecord.rtt] withSequenceNumber:(int)sequenceNumber];
//
//                    doneTraceroute = [self reachedTargetIP:ipInPacket];
//
//                } else if ([packetRecord.responseAddress isEqualToString:ipInPacket]){
//                    //If we receive another packet for the same IP, we don't want to re-report
//                    numberOfRepliesForIP++;
//                }
//            }
//
//            if (doneTraceroute) {
//                if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(tracerouteDidComplete:)]) {
//                    NSArray* hops = self.hopsForCurrentIP;
//            [self.delegate tracerouteDidComplete:hops];
//                }
//            } else {
//                self.ttlCount++;
//        [self sendPackets:nil];
//            }
//
//            //NSLog(@"Number of replies for IP %@ is %d, Number of replies for sequence number %d is %d", ipInPacket, numberOfRepliesForIP, sequenceNumber, numberOfRepliesForSequenceNumber);
//
//        }



    //}



    //------------------------------------------------------
    // PacketUtil.EventListener
    //------------------------------------------------------
    public void onStartWithAddress() {

        sendPackets();
//        NSLog(@"ICMP Packet Utility Ready.");
//    [self sendPackets:nil];
    }

    public void receivedResponsePacket(byte[] packet, Date arrivedAt) {

        ICMPHeader icmpPacket = new ICMPHeader(packet, 0);
        byte packetType = icmpPacket.getType();

        switch (packetType) {
            case ICMPHeader.TYPE_TIME_EXCEEDED:
//        [NSObject cancelPreviousPerformRequestsWithTarget:self];
//        [self processErrorICMPPacket:packet arrivedAt:dateTime];
                // TODO
                break;
            case ICMPHeader.TYPE_ECHO_REPLY:
                // TODO
                break;
            case ICMPHeader.TYPE_DESTINATION_UNREACHABLE:
                // TODO
                break;
            default:
                // TODO?
                break;

        }


// Check what kind of packet from header
//        int typeOfPacket = [self processICMPPacket:packet];
//
//        if (typeOfPacket == kICMPTimeExceeded) {
//        [NSObject cancelPreviousPerformRequestsWithTarget:self];
//        [self processErrorICMPPacket:packet arrivedAt:dateTime];
//        } else if (typeOfPacket == kICMPTypeEchoReply) {
//        [NSObject cancelPreviousPerformRequestsWithTarget:self];
//            // Check if we've reached our final destination
//        } else if (typeOfPacket == kICMPTypeDestinationUnreachable){
//        [NSObject cancelPreviousPerformRequestsWithTarget:self];
//            NSLog(@"Destination unreachable");
//        [self processErrorICMPPacket:packet arrivedAt:dateTime];
//        } else {
//            NSLog(@"What should happen here?");
//        }

    }


    //-(void)start{
//        if (!self.packetUtility) {
//            self.packetUtility = [SCIcmpPacketUtility utilityWithHostAddress:self.targetIP];
//            self.packetUtility.delegate = self;
//        }
//    [self.packetUtility start];
//    }
//-(void)stop{
//        self.ttlCount = 1;
//    [self.packetUtility stop];
//        self.packetUtility = nil;
//    }


}
