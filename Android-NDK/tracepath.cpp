#include "tracepath.h"
#include <stdlib.h>
#include <vector>
#include <string>
#include <android/log.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <linux/errqueue.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <arpa/inet.h>
#include <sys/select.h>
#include <unistd.h>

#define HOST_COLUMN_SIZE	52

/**
 * Tracepath attempts to provide the functionality required to generate traceroute functionality.
 * Code based on tracepath implementation found @ https://android.googlesource.com/platform/external/iputils/+/master/tracepath.c
 *
 * According to my research we can't do ping/traceroute in native Java; ping/traceroute  work at
 * the ICMP level which works on top of IP, whereas Java offers support for UDP (which sits on top of IP)
 * and TCP (again on top of IP).
 *
 * Tracepath allows us to setup a socket and send ICMP packets (over UDP) with a given TTL and then
 * return us the probed packet for that TTL.
 */

double getNowMS() {
    // Note, clock() returns CPU time and cannot be relied on for generating
    // time intervals.
    struct timespec res;
    clock_gettime(CLOCK_MONOTONIC, &res);
    return 1000.0 * res.tv_sec + (double) res.tv_nsec / 1e6;
}

void printIcmpHdr(char* title, icmp icmp_hdr) {
    LOG("%s: type=0x%x, id=0x%x, sequence = 0x%x ",
        title, icmp_hdr.icmp_type, icmp_hdr.icmp_id, icmp_hdr.icmp_seq);
}

void print_tracepath_hop_vec(tracepath_hop_vec array) {
    for (tracepath_hop_vec::iterator it = array.begin(); it != array.end(); ++it) {
        LOG("TTL: %d --> %s", it->ttl, it->receive_addr.c_str());
    }
}

Tracepath::Tracepath() {
    return;
}

Tracepath::~Tracepath() {
    LOG_INFO("Renderer instance destroyed");
    return;
}

probe_result Tracepath::probeDestinationAddressWithTTL(struct in_addr *dst, int ttl) {

    probe_result result;
    result.success = false;

    struct tracepath_hop probe;
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof addr);

    addr.sin_family = AF_INET;
    addr.sin_addr = *dst;
    char* snd_addy = inet_ntoa(addr.sin_addr);
    std::string snd_addy_str = std::string(snd_addy);

    LOG("Trace Starting probeDestinationAddressWithTTL to %s with %d", snd_addy, ttl);

    int sock = setupSocket();
    if (sock < 0) {
        LOG("Trace Failed to build send socket");
        return result; // TODO error result
    }

    // Set TTL on socket
    if (ttl > 0) {
        if (setsockopt(sock, SOL_IP, IP_TTL, &ttl, sizeof(ttl))) {
            LOG("Trace Failed to set IP_TTL, cannot make packet request");
            return result;
        }
    }

    probe.ttl = ttl;

    int maxProbes = 3;
    int seq = 0;

    // Send up to 3 probes per TLL
    for (int probeCount = 0; probeCount < maxProbes; probeCount++) {
        probe.sendtime = getNowMS();
        if (sendProbe(sock, addr, ttl, seq++, probe)) {
            if (probe.success) {
                probe.receievetime = getNowMS();
                result.receive_addr = probe.receive_addr;
                result.elapsedMs = probe.receievetime - probe.sendtime;
                result.success = true;
                LOG("Trace Elapsed time %.2f", result.elapsedMs);
                break;
            }
        }
    }

    // Cleanup
    close(sock);

    return result;
}

probe_result Tracepath::ping(struct in_addr *dst) {
    return probeDestinationAddressWithTTL(dst, -1);
}

int Tracepath::setupSocket() {
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
    if (sock < 0) {
        perror("socket");
        return sock;
    }

    // TODO if this is not supported, we cannot run tracepath.
    // IP_MTU_DISCOVER: Set or receive the Path MTU Discovery setting for a socket. When enabled,
    // Linux will perform Path MTU Discovery as defined in RFC 1191 on SOCK_STREAM sockets.
    // For non-SOCK_STREAM sockets, IP_PMTUDISC_DO forces the don't-fragment flag to be set on all
    // outgoing packets. It is the user's responsibility to packetize data in MTU-sized chunks and
    // to do the retransmits if necessary. The kernel will reject (with EMSGSIZE) datagrams that are
    // bigger than the known path MTU. IP_PMTUDISC_WANT will fragment a datagram if needed according
    // to the path MTU, or will set the don't-fragment flag otherwise.
    int on = IP_PMTUDISC_PROBE;
    if (setsockopt(sock, SOL_IP, IP_MTU_DISCOVER, &on, sizeof(on)) && (on = IP_PMTUDISC_DO, setsockopt(sock, SOL_IP, IP_MTU_DISCOVER, &on, sizeof(on)))) {
        LOG("IP_MTU_DISCOVER");
        //exit(1);
    }

    on = 1;
    // SOL_IP: (set/configure various IP packet options, IP layer behaviors, [as here] netfilter module options)
    // IP_RECVERR: Enable extended reliable error message passing. When enabled on a datagram socket,
    // all generated errors will be queued in a per-socket error queue. When the user receives an error from a socket operation,
    // the errors can be received by calling recvmsg with the MSG_ERRQUEUE flag set.
    if (setsockopt(sock, SOL_IP, IP_RECVERR, &on, sizeof(on))) {
        LOG("IP_RECVERR");
        // TODO if this is not supported, we cannot run tracepath.
    }

    // IP_RECVTTL: When this flag is set, pass a IP_TTL control message with the time to live field of the received
    // packet as a byte. Not supported for SOCK_STREAM sockets.
    // TODO, not sure if required for tracepath
    if (setsockopt(sock, SOL_IP, IP_RECVTTL, &on, sizeof(on))) {
        LOG("IP_RECVTTL");
    }

    return sock;
}

int Tracepath::waitForReply(int sock) {
    // Wait for a reply with a timeout
    fd_set fds;
    struct timeval tv;
    FD_ZERO(&fds);
    FD_SET(sock, &fds);
    tv.tv_sec = 1;
    tv.tv_usec = 0;
    return select(sock+1, &fds, NULL, NULL, &tv);
}

struct probehdr {
    int ttl;
    struct timeval tv;
};

void printCharArray(char list[]) {
    std::string listStr (list);
    LOG("%s", listStr.c_str());
}

/**
 * Will attempt to set probe.error if data returned indicates an issue with the probe.
 */
bool Tracepath::receiveError(int sock, int ttl, tracepath_hop &probe) {
    struct msghdr msg;

    struct iovec  iov;
    struct sockaddr_in addr;
    char cbuf[512];

    struct icmp rcv_icmp_hdr;
    struct probehdr rcv_probe_hdr;
    int messageSize = sizeof(rcv_icmp_hdr) + sizeof(rcv_probe_hdr);
    char data[messageSize];
    memset(data, 0, messageSize);

    printCharArray(data);

    //memset(&rcv_icmp_hdr, -1, sizeof(rcv_icmp_hdr));
    //memset(&rcv_probe_hdr, -1, sizeof(rcv_probe_hdr));

    // The recvmsg() call uses a msghdr structure to minimize the number of directly supplied arguments.
    iov.iov_base = data;
    iov.iov_len = sizeof(data);
    msg.msg_name = (__u8*)&addr;
    msg.msg_namelen = sizeof(addr);
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_flags = 0;
    msg.msg_control = cbuf;
    msg.msg_controllen = sizeof(cbuf);

    // recvmsg: Returns the length of the message on successful completion. If a message is too
    // long to fit in the supplied buffer, excess bytes may be discarded depending on the type of
    // socket the message is received from.

    int res = recvmsg(sock, &msg, MSG_ERRQUEUE);
    if (res < 0) {
        // EAGAIN is often raised when performing non-blocking I/O.
        // It means "there is no data available right now, try again later".
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            // If there is no error available, then we may have a valid response coming back.
            LOG("errno == EAGAIN");
            probe.error = EAGAIN;
            return false;
        } else {
            // Else, attempt to read MSG_ERRQUEUE again
            return receiveError(sock, ttl, probe);
        }
    }

    printCharArray(data);

    memcpy(&rcv_icmp_hdr, data, sizeof rcv_icmp_hdr);
    memcpy(&rcv_probe_hdr, data + sizeof rcv_icmp_hdr, sizeof rcv_probe_hdr);

    if (res == sizeof(rcv_probe_hdr)) {
        if (rcv_probe_hdr.ttl == 0 || rcv_probe_hdr.tv.tv_sec == 0) {
            //broken_router = 1;
        } else {
            //LOG("ttl %d", rcv_probe_hdr.ttl);
            //LOG("tv %d", rcv_probe_hdr.tv);
        }
    }

    struct cmsghdr *cmsg;
    struct sock_extended_err *e;
    int rethops;
    int sndhops;

    e = NULL;

    // Parse message into sock_extended_err object.
    for (cmsg = CMSG_FIRSTHDR(&msg); cmsg; cmsg = CMSG_NXTHDR(&msg, cmsg)) {
        if (cmsg->cmsg_level == SOL_IP) {
            if (cmsg->cmsg_type == IP_RECVERR) {
                e = (struct sock_extended_err *) CMSG_DATA(cmsg);
            } else if (cmsg->cmsg_type == IP_TTL) {
                memcpy(&rethops, CMSG_DATA(cmsg), sizeof(rethops));
            } else {
                LOG("Could not parse sock_extended_err; Invalid cmsg_type:%d\n ", cmsg->cmsg_type);
            }
        }
    }

    if (e == NULL) {
        printf("no info\n");
        return 0;
    }

    if (e->ee_origin == SO_EE_ORIGIN_LOCAL) {
        LOG("%2d?: %*s ", ttl, -(HOST_COLUMN_SIZE - 1), "[LOCALHOST]");
    } else if (e->ee_origin == SO_EE_ORIGIN_ICMP) {
        char abuf[128];
        struct sockaddr_in *sin = (struct sockaddr_in*)(e+1);
        //struct hostent *h = NULL;
        //char *idn = NULL;
        inet_ntop(AF_INET, &sin->sin_addr, abuf, sizeof(abuf));

        // We have pulled out the error for this TTL level, count the probe
        // as a success.
        probe.receive_addr = std::string(abuf);
        probe.success = true;
        probe.error = e->ee_errno;

        LOG("Receive from %s", abuf);

//        if (sndhops>0)
//            LOG("%2d:  ", sndhops);
//        else
//            LOG("%2d?: ", ttl);
    }

    rethops = -1;
    sndhops = -1;

    switch (e->ee_errno) {
        case EHOSTUNREACH:
            LOG("EHOSTUNREACH");
//            if (e->ee_origin == SO_EE_ORIGIN_ICMP &&
//                e->ee_type == 11 &&
//                e->ee_code == 0) {
//                if (rethops>=0) {
//                    if (rethops<=64)
//                        rethops = 65-rethops;
//                    else if (rethops<=128)
//                        rethops = 129-rethops;
//                    else
//                        rethops = 256-rethops;
//                    if (sndhops>=0 && rethops != sndhops)
//                        LOG("asymm %2d ", rethops);
//                    else if (sndhops<0 && rethops != ttl)
//                        LOG("asymm %2d ", rethops);
//                }
//            }
            break;
        case ENETUNREACH:
            LOG("ENETUNREACH");
            break;
        case ETIMEDOUT:
            LOG("ETIMEDOUT");
            // If timed out, then attempt to receive error again.
            return receiveError(sock, ttl, probe);
            break;
        case EMSGSIZE:
            LOG("EMSGSIZE");
            LOG("pmtu %d\n", e->ee_info);
            //mtu = e->ee_info;
            //progress = mtu;
            break;
        case ECONNREFUSED:
            LOG("ECONNREFUSED");
            LOG("reached\n");
            //hops_to = sndhops<0 ? ttl : sndhops;
            //hops_from = rethops;
            break;
        case EPROTO:
            LOG("EPROTO");
            LOG("!P\n");
            break;
        case EACCES:
            LOG("EACCES");
            break;
        default:
            errno = e->ee_errno;
            LOG("NET ERROR");
            break;
    }

    return true;
}

/**
 * Will attempt to set probe.receive_addr with the IP address found at the given TTL.
 */
bool Tracepath::receiveData(int sock, tracepath_hop &probe) {
    struct sockaddr_in rcv_addr;
    socklen_t slen = sizeof rcv_addr;

    unsigned char data[2048];
    struct icmp rcv_hdr;

    int rc = recvfrom(sock, data, sizeof data, 0, (struct sockaddr*)&rcv_addr, &slen);
    char* rcv_addy = inet_ntoa(rcv_addr.sin_addr);
    LOG("Receive length, %d bytes from %s", slen, rcv_addy);

    if (rc <= 0) {
        LOG("Failed to recvfrom");
        return false;
    } else if (rc < sizeof rcv_hdr) {
        LOG("Error, got short ICMP packet, %d bytes", rc);
        return false;
    }

    probe.receive_addr = std::string(rcv_addy);
    probe.success = true;

    memcpy(&rcv_hdr, data, sizeof rcv_hdr);
    if (rcv_hdr.icmp_type == ICMP_ECHOREPLY) {
        printIcmpHdr((char *)"Received", rcv_hdr);
        return true;
    } else {
        LOG("Got ICMP packet with type 0x%x ?!?", rcv_hdr.icmp_type);
    }

    return false;
}

bool Tracepath::sendProbe(int sock, sockaddr_in addr, int ttl, int attempt, tracepath_hop &probe) {

    struct icmp icmp_hdr;
    struct probehdr probe_hdr;
    struct timeval tv;
    int sequence = 0;

    LOG("-------------------------------------------");
    memset(&icmp_hdr, 0, sizeof icmp_hdr);
    icmp_hdr.icmp_type = ICMP_ECHO;
    int max_attempts = 10;
    int i = 0;
    bool error_msg_received = false;

    probe_hdr.ttl = ttl;

    //for (i=0; i < max_attempts; i++) {

        icmp_hdr.icmp_seq = attempt;
        unsigned char data[2048];
        memcpy(data, &icmp_hdr, sizeof icmp_hdr);
        memcpy(data + sizeof icmp_hdr, &probe_hdr, sizeof probe_hdr); //icmp payload

        LOG("TTL: %d", ttl);
        printIcmpHdr((char *)"Sending", icmp_hdr);

        // sendto: On success, return the number of characters sent. On error, -1 is returned, and errno is set appropriately.
        int rc = sendto(sock, data, sizeof icmp_hdr + sizeof probe_hdr, 0, (struct sockaddr*)&addr, sizeof addr);
        if (rc <= 0) {
            LOG("Failed to send ICMP packet");
            return false;
        }

        bool foundError = receiveError(sock, ttl, probe);
        if (!foundError) {
            LOG("No Error message received, attempting to read incoming data");
            // If there is no error available, then we may have a valid response coming back.
            // TODO Do We want to send out another packet to make sure this is the case?
            //continue;
        } else {
            // We have parsed out and handled an error message.
            // This means that we will not be getting data on the socket, so there is no
            // need to continue.
            LOG("Error message received, moving to next TTL");
            error_msg_received = true;
            //break;
        }
    //}

    if (error_msg_received) {
        // If we received an error we should have logged the data in probe.
        // Count as a successful probe.
        return true;
    } else {
        // No error found, We may have data waiting for us on the socket.
        int reply = waitForReply(sock);
        if (reply == 0) {
            LOG("waitForReply, no reply");
            return false;
        } else if (reply < 0) {
            LOG("Failed waitForReply");
            return false;
        } else {
            return receiveData(sock, probe);
        }
    }
}


