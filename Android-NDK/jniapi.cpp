#include <stdint.h>
#include <jni.h>
#include <android/native_window.h> // requires ndk r5 or newer
#include <android/native_window_jni.h> // requires ndk r5 or newer
#include <string>
#include "jniapi.h"
#include "renderer.h"

#include <../Common/Code/MapController.hpp>
#include <../Common/Code/MapDisplay.hpp>
#include <../Common/Code/Camera.hpp>

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <linux/types.h>
#include <linux/errqueue.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <arpa/inet.h>
#include <sys/select.h>

static ANativeWindow *window = 0;
static Renderer *renderer = 0;

static jobject activity = 0;
static JavaVM* javaVM;

#define HOST_COLUMN_SIZE	52

jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    JNIEnv *env;
    javaVM = vm;
    if (vm->GetEnv((void**) &env, JNI_VERSION_1_6) != JNI_OK) {
        LOG_ERROR("Could not get JNIEnv");
        return -1;
    }

    return JNI_VERSION_1_6;
}

//helper function for wrappers returning a node
jobject wrapNode(JNIEnv* jenv, NodePointer node) {
    if (!node) return 0;

    //strings that need to be freed after
    //note: normally jni cleans these up on return to java, but allNodes just generates too many of them (the limit is 512)
    jstring asn = jenv->NewStringUTF(node->asn.c_str());
    jstring textDesc = jenv->NewStringUTF(node->rawTextDescription.c_str());
    jstring type = jenv->NewStringUTF(node->typeString.c_str());

    jclass nodeWrapperClass = jenv->FindClass("com/peer1/internetmap/NodeWrapper");
    jmethodID constructor = jenv->GetMethodID(nodeWrapperClass, "<init>",
            "(IFILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
    //note: if you change this code, triple-check that the argument order matches NodeWrapper.
    jobject wrapper = jenv->NewObject(nodeWrapperClass, constructor, node->index, node->importance,
            node->connections.size(), asn, textDesc, type);

    //free up the strings
    jenv->DeleteLocalRef(asn);
    jenv->DeleteLocalRef(textDesc);
    jenv->DeleteLocalRef(type);
    //oh, we need to free this too
    jenv->DeleteLocalRef(nodeWrapperClass);

    return wrapper;
}

JNIEXPORT jboolean JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnCreate(JNIEnv* jenv, jobject obj, bool smallScreen)
{
    LOG("OnCreate");
    activity = jenv->NewGlobalRef(obj);

    if(!renderer) {
        renderer = new Renderer(smallScreen);
        return true;
    }

    LOG("Renderer already exists");
    return false;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnResume(JNIEnv* jenv, jobject obj)
{
    renderer->resume();
    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnPause(JNIEnv* jenv, jobject obj)
{
    renderer->pause();
    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnDestroy(JNIEnv* jenv, jobject obj)
{
    jenv->DeleteGlobalRef(activity);
    activity = NULL;

    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeSetSurface(JNIEnv* jenv, jobject obj, jobject surface, float scale)
{
    if (surface != 0) {
        window = ANativeWindow_fromSurface(jenv, surface);
        renderer->setWindow(window, scale);
    } else {
        renderer->setWindow(NULL, scale);
        ANativeWindow_release(window);
    }

    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_rotateRadiansXY(JNIEnv* jenv, jobject obj,
		float radX, float radY) {
    renderer->bufferedRotationX(radX);
    renderer->bufferedRotationY(radY);
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_startMomentumPanWithVelocity(JNIEnv* jenv, jobject obj,
        float vX, float vY) {
    MapController* controller = renderer->beginControllerModification();
    controller->display->camera->startMomentumPanWithVelocity(Vector2(vX, vY));
    renderer->endControllerModification();

}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_handleTouchDownAtPoint(JNIEnv* jenv, jobject obj,
        float x, float y) {
    MapController* controller = renderer->beginControllerModification();
    controller->handleTouchDownAtPoint(Vector2(x, y));
    renderer->endControllerModification();
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_zoomByScale(JNIEnv* jenv, jobject obj,
        float scale) {
    renderer->bufferedZoom(scale);
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_startMomentumZoomWithVelocity(JNIEnv* jenv, jobject obj,
        float velocity) {
    MapController* controller = renderer->beginControllerModification();
    controller->display->camera->startMomentumZoomWithVelocity(velocity);
    renderer->endControllerModification();
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_rotateRadiansZ(JNIEnv* jenv, jobject obj,
        float radians) {
    renderer->bufferedRotationZ(radians);
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_startMomentumRotationWithVelocity(JNIEnv* jenv, jobject obj,
        float velocity) {
    MapController* controller = renderer->beginControllerModification();
    controller->display->camera->startMomentumRotationWithVelocity(velocity);
    renderer->endControllerModification();
}

JNIEXPORT bool JNICALL Java_com_peer1_internetmap_MapControllerWrapper_selectHoveredNode(JNIEnv* jenv, jobject obj) {
    MapController* controller = renderer->beginControllerModification();
    bool ret = controller->selectHoveredNode();
    renderer->endControllerModification();
    return ret;
}

JNIEXPORT jobject JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nodeAtIndex(JNIEnv* jenv, jobject obj,
        int index) {
    MapController* controller = renderer->beginControllerModification();
    if (index < 0 || index >= controller->data->nodes.size()) {
        LOG("node index out of range");
        renderer->endControllerModification();
        return 0;
    }
    NodePointer node = controller->data->nodes[index];
    jobject wrapper = wrapNode(jenv, node);

    renderer->endControllerModification();
    return wrapper;
}

JNIEXPORT jobject JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nodeByAsn(JNIEnv* jenv, jobject obj,
        jstring asn) {
    MapController* controller = renderer->beginControllerModification();

    const char *asnCstr = jenv->GetStringUTFChars(asn, 0);
    NodePointer node = controller->data->nodesByAsn[asnCstr];
    jenv->ReleaseStringUTFChars(asn, asnCstr);

    if(node != NULL && node->isActive()) {
        jobject wrapper = wrapNode(jenv, node);

        renderer->endControllerModification();
        return wrapper;
    }
    else {
        renderer->endControllerModification();
        return 0;
    }
}

JNIEXPORT int JNICALL Java_com_peer1_internetmap_MapControllerWrapper_targetNodeIndex(JNIEnv* jenv, jobject obj) {
    MapController* controller = renderer->beginControllerModification();
    //not actually modifying anything here... but we still need to be threadsafe.
    int ret = controller->targetNode;
    renderer->endControllerModification();
    return ret;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_updateTargetForIndex(JNIEnv* jenv, jobject obj, int index) {
    MapController* controller = renderer->beginControllerModification();
    controller->updateTargetForIndex(index);
    renderer->endControllerModification();
}

JNIEXPORT jobjectArray JNICALL Java_com_peer1_internetmap_MapControllerWrapper_allNodes(JNIEnv* jenv, jobject obj) {
    MapController* controller = renderer->beginControllerModification();
    jclass nodeWrapperClass = jenv->FindClass("com/peer1/internetmap/NodeWrapper");
    jobjectArray array = jenv->NewObjectArray(controller->data->nodes.size(), nodeWrapperClass, 0);
    //populate array
    for (int i = 0; i < controller->data->nodes.size(); i++) {
        NodePointer node = controller->data->nodes[i];
        if (node && node->isActive()) {
            jobject wrapper = wrapNode(jenv, node);
            jenv->SetObjectArrayElement(array, i, wrapper);
            //cleanup because we loop >512 times
            jenv->DeleteLocalRef(wrapper);
        }
    }
    renderer->endControllerModification();
    return array;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_setTimelinePoint(JNIEnv* jenv, jobject obj, jstring year) {
    const char *yearCstr = jenv->GetStringUTFChars(year, 0);
    char date[5];
    sprintf(date, "%s", yearCstr);
    jenv->ReleaseStringUTFChars(year, yearCstr);

    MapController* controller = renderer->beginControllerModification();
    controller->setTimelinePoint(date);
    renderer->endControllerModification();
}

JNIEXPORT jobjectArray JNICALL Java_com_peer1_internetmap_MapControllerWrapper_visualizationNames(JNIEnv* jenv, jobject obj) {
    MapController* controller = renderer->beginControllerModification();
    std::vector<std::string> names = controller->visualizationNames();
    jclass stringClass = jenv->FindClass("java/lang/String");
    jobjectArray array = jenv->NewObjectArray(names.size(), stringClass, 0);
    for (int i = 0; i < names.size(); i++) {
        //this should be small enough to let JNI handle memory
        jstring name = jenv->NewStringUTF(names[i].c_str());
        jenv->SetObjectArrayElement(array, i, name);
    }
    renderer->endControllerModification();
    return array;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_setVisualization(JNIEnv* jenv, jobject obj, int index) {
    MapController* controller = renderer->beginControllerModification();
    controller->setVisualization(index);
    renderer->endControllerModification();
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_deselectCurrentNode(JNIEnv* jenv, jobject obj) {
    MapController* controller = renderer->beginControllerModification();
    controller->deselectCurrentNode();
    renderer->endControllerModification();
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_resetZoomAndRotationAnimated(JNIEnv* jenv, jobject obj, bool isPortraitMode) {
    MapController* controller = renderer->beginControllerModification();
    controller->display->camera->resetZoomAndRotationAnimated(isPortraitMode);
    renderer->endControllerModification();
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_setAllowIdleAnimation(JNIEnv* jenv, jobject obj, bool allow) {
    MapController* controller = renderer->beginControllerModification();
    controller->display->camera->setAllowIdleAnimation(allow);
    renderer->endControllerModification();
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_unhoverNode(JNIEnv* jenv, jobject obj) {
    MapController* controller = renderer->beginControllerModification();
    controller->unhoverNode();
    renderer->endControllerModification();
}

JNIEXPORT jstring JNICALL Java_com_peer1_internetmap_NodeWrapper_nativeFriendlyDescription(JNIEnv* jenv, jobject obj, int index) {
    MapController* controller = renderer->beginControllerModification();
    if (index < 0 || index >= controller->data->nodes.size()) {
        LOG("node index out of range");
        renderer->endControllerModification();
        return 0;
    }
    NodePointer node = controller->data->nodes[index];
    jstring ret = jenv->NewStringUTF(node->friendlyDescription().c_str());
    renderer->endControllerModification();
    return ret;
}

void printIcmpHdr(char* title, icmp icmp_hdr) {
    LOG("%s: type=0x%x, id=0x%x, sequence = 0x%x ",
    title, icmp_hdr.icmp_type, icmp_hdr.icmp_id, icmp_hdr.icmp_seq);
}

/**
 * https://stackoverflow.com/questions/8290046/icmp-sockets-linux
 * @param dst
 */
void ping_it(struct in_addr *dst)
{
    struct icmp icmp_hdr;
    struct sockaddr_in addr;
    struct sockaddr_in rcv_addr;

    int sequence = 0;
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
    if (sock < 0) {
        perror("socket");
        return ;
    }

    memset(&addr, 0, sizeof addr);

    addr.sin_family = AF_INET;
    addr.sin_addr = *dst;

    char* snd_addy = inet_ntoa(addr.sin_addr);

    memset(&icmp_hdr, 0, sizeof icmp_hdr);
    icmp_hdr.icmp_type = ICMP_ECHO;
    //icmp_hdr.un.echo.id = 1234;//arbitrary id


    int on = IP_PMTUDISC_PROBE;
//    if (setsockopt(sock, SOL_IP, IP_MTU_DISCOVER, &on, sizeof(on)) &&
//        (on = IP_PMTUDISC_DO,
//                setsockopt(sock, SOL_IP, IP_MTU_DISCOVER, &on, sizeof(on)))) {
//        perror("IP_MTU_DISCOVER");
//        //exit(1);
//    }
    on = 1;
    if (setsockopt(sock, SOL_IP, IP_RECVERR, &on, sizeof(on))) {
        perror("IP_RECVERR");
        //exit(1);
    }
    if (setsockopt(sock, SOL_IP, IP_RECVTTL, &on, sizeof(on))) {
        perror("IP_RECVTTL");
        //exit(1);
    }

    for (int ttl = 2; ttl < 255; ttl++) {

        setsockopt(sock, SOL_IP/*IPPROTO_IP*/, IP_TTL, (char *)&ttl, sizeof(ttl));
        LOG("----------------------------------------------");
        LOG("Sending to %s with ttl %d", snd_addy, ttl);

        unsigned char data[2048];
        int rc;
        struct timeval timeout = {3, 0}; //wait max 3 seconds for a reply
        fd_set read_set;
        socklen_t slen;
        struct icmp rcv_hdr;

        // TODO 3 probes

        icmp_hdr.icmp_seq = sequence++;
        memcpy(data, &icmp_hdr, sizeof icmp_hdr);
        memcpy(data + sizeof icmp_hdr, "hello", 5); //icmp payload
        rc = sendto(sock, data, sizeof icmp_hdr + 5,
                    0, (struct sockaddr*)&addr, sizeof addr);

        printIcmpHdr("Send   ", icmp_hdr);

        if (rc <= 0) {
            LOG("Sendto");
            break;
        }

        LOG("Sent ICMP");

        memset(&read_set, 0, sizeof read_set);
        FD_SET(sock, &read_set);

        //wait for a reply with a timeout
        rc = select(sock + 1, &read_set, NULL, NULL, &timeout);

        if (rc == 0) {
            LOG("Got no reply");
            continue;
        } else if (rc < 0) {
            LOG("Select");
            break;
        }

        slen = sizeof rcv_addr;
        rc = recvfrom(sock, data, sizeof data, 0, (struct sockaddr*)&rcv_addr, &slen);

        char* rcv_addy = inet_ntoa(rcv_addr.sin_addr);
        LOG("Receive length, %d bytes from %s", slen, rcv_addy);

        if (rc <= 0) {
            LOG("recvfrom");
            break;
        } else if (rc < sizeof rcv_hdr) {
            LOG("Error, got short ICMP packet, %d bytes", rc);
            break;
        }

        memcpy(&rcv_hdr, data, sizeof rcv_hdr);
        if (rcv_hdr.icmp_type == ICMP_ECHOREPLY) {
            printIcmpHdr("Receive", rcv_hdr);
        } else {
            LOG("Got ICMP packet with type 0x%x ?!?", rcv_hdr.icmp_type);
        }

        //break; // Test For now always break after getting reply
    }
}

struct tracepath_hop {
    int ttl;
    char* ip;
    struct timeval sendtime;
    struct timeval receievetime;
};

int setupSocket(struct in_addr *dst) {
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
    if (sock < 0) {
        perror("socket");
        return sock;
    }

    // TODO if this is not supported, we cannot run tracepath.
    // IP_MTU_DISCOVER: Set or receive the Path MTU Discovery setting for a socket. When enabled, Linux will perform Path MTU Discovery as defined in RFC 1191 on SOCK_STREAM sockets.
    // For non-SOCK_STREAM sockets, IP_PMTUDISC_DO forces the don't-fragment flag to be set on all outgoing packets. It is the user's responsibility to packetize
    // e data in MTU-sized chunks and to do the retransmits if necessary. The kernel will reject (with EMSGSIZE) datagrams that are bigger than the known path MTU.
    // IP_PMTUDISC_WANT will fragment a datagram if needed according to the path MTU, or will set the don't-fragment flag otherwise.
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

int waitForReply(int sock) {
    // Wait for a reply with a timeout
    fd_set fds;
    struct timeval tv;
    FD_ZERO(&fds);
    FD_SET(sock, &fds);
    tv.tv_sec = 3;
    tv.tv_usec = 0;
    return select(sock+1, &fds, NULL, NULL, &tv);
}


struct probehdr
{
    __u32 ttl;
    struct timeval tv;
};

// TODO define this better.
// returns the size of the error received.
// < 0  == no error message available
// 0    == error found, but could not correctly read host data
// > 0  == error found, EHOSTUNREACH returned with intermediate host info
int receiveError(int sock, int ttl) {
    struct msghdr msg;
    struct probehdr rcvbuf;
    struct iovec  iov;
    struct sockaddr_in addr;
    char cbuf[512];

    // The recvmsg() call uses a msghdr structure to minimize the number of directly supplied arguments.
    memset(&rcvbuf, -1, sizeof(rcvbuf));
    iov.iov_base = &rcvbuf;
    iov.iov_len = sizeof(rcvbuf);
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
        if (errno == EAGAIN) {
            // If there is no error available, then we may have a valid response coming back.
            LOG("errno == EAGAIN");
            return res;
        } else if (errno == EWOULDBLOCK) {
            // TODO, do we need to handle this? Since we are not setting MSG_DONTWAIT
            // we may not have to.
            LOG("errno == EWOULDBLOCK");
            return res;
        } else {
            // Else, attempt to read MSG_ERRQUEUE again
            return receiveError(sock, ttl);
        }
    }

//    if (res == sizeof(rcvbuf)) {
//        if (rcvbuf.ttl == 0 || rcvbuf.tv.tv_sec == 0) {
//            //broken_router = 1;
//        } else {
//            LOG("ttl %d", rcvbuf.ttl);
//            LOG("tv %d", rcvbuf.tv);
//        }
//    }

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

        char* rcv_addy = inet_ntoa(sin->sin_addr);
        LOG("Receive from %s", rcv_addy);

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
            if (e->ee_origin == SO_EE_ORIGIN_ICMP &&
                e->ee_type == 11 &&
                e->ee_code == 0) {
                if (rethops>=0) {
                    if (rethops<=64)
                        rethops = 65-rethops;
                    else if (rethops<=128)
                        rethops = 129-rethops;
                    else
                        rethops = 256-rethops;
                    if (sndhops>=0 && rethops != sndhops)
                        LOG("asymm %2d ", rethops);
                    else if (sndhops<0 && rethops != ttl)
                        LOG("asymm %2d ", rethops);
                }
                break;
            }
            return res; // res should be +
        case ENETUNREACH:
            LOG("ENETUNREACH");
            return 0;
        case ETIMEDOUT:
            LOG("ETIMEDOUT");
            // If timed out, then attempt to receive error again.
            return receiveError(sock, ttl);
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

    // goto restart
    return 0;
}

bool receiveData(int sock) {
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

    memcpy(&rcv_hdr, data, sizeof rcv_hdr);
    if (rcv_hdr.icmp_type == ICMP_ECHOREPLY) {
        printIcmpHdr("Received", rcv_hdr);
        return true;
    } else {
        LOG("Got ICMP packet with type 0x%x ?!?", rcv_hdr.icmp_type);
    }

    return false;
}

bool sendProbe(int sock, sockaddr_in addr, int ttl) {

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

    for (i=0; i < max_attempts; i++) {

        icmp_hdr.icmp_seq = i;
        unsigned char data[2048];
        memcpy(data, &icmp_hdr, sizeof icmp_hdr);
        memcpy(data + sizeof icmp_hdr, "hello", 5); //icmp payload

        LOG("TTL: %d", ttl);
        printIcmpHdr("Sending", icmp_hdr);


        // sendto: On success, return the number of characters sent. On error, -1 is returned, and errno is set appropriately.
        int rc = sendto(sock, data, sizeof icmp_hdr + 5, 0, (struct sockaddr*)&addr, sizeof addr);
        if (rc <= 0) {
            LOG("Failed to send ICMP packet");
            return false;
        }

        int err = receiveError(sock, ttl);
        // if err < 0, then
        if (err == EAGAIN) {
            // If there is no error available, then we may have a valid response coming back.
            // We want to send out another packet to make sure this is the case.
            continue;
        } else if (err == 0) {
            // If err = 0, then we have parsed out and handled an error message.
            // This means that we will not be getting data on the socket, so there is no
            // need to continue.
            LOG("Error message received, moving to next TTL");
            error_msg_received = true;
            break;
        }
    }

    if (error_msg_received) {
        return false;
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
            return receiveData(sock);
        }
    }
}

void tracepath(struct in_addr *dst)
{
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof addr);

    addr.sin_family = AF_INET;
    addr.sin_addr = *dst;
    char* snd_addy = inet_ntoa(addr.sin_addr);

    LOG("----------------------------------------------");
    LOG(" Starting trace to %s", snd_addy);

    int sock = setupSocket(dst);
    if (sock < 0) {
        LOG("Failed to build send socket");
        return;
    }

    int maxHops = 255;

    for (int ttl = 1; ttl < maxHops; ttl++) {

        // Set TTL on socket
        if (setsockopt(sock, SOL_IP, IP_TTL, &ttl, sizeof(ttl))) {
            LOG("Failed to set IP_TTL");
            return;
        }

        // Send up to 3 probes
        for (int probeCount = 0; probeCount < 1; probeCount++) {

            if (sendProbe(sock, addr, ttl)) {
                ttl = maxHops; //break; // break;
            }

        }
    }

    LOG("----------------------------------------------");
    LOG(" Trace complete");
    LOG("----------------------------------------------");
}



JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_sendPacket(JNIEnv* jenv, jobject obj) {

    LOG("traceroute start");

    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);

    if (sock < 0) {
        LOG("Failed to create socket");
        return;
    }

    // TODO use instead:
    //inet_ntop() and inet_pton()

    struct in_addr testaddr;
    inet_aton("172.217.3.164"/*"13.32.253.9"*/, &testaddr);

    //ping_it(&testaddr);
    tracepath(&testaddr);

    //----
    // https://books.google.ca/books?id=JYhA5uqOxIAC&pg=PA253&lpg=PA253&dq=icmp6_filt+example&source=bl&ots=PdgcvSgI_H&sig=it25MHd-k8ZcLg2ZEJO8WTy0RJU&hl=en&sa=X&ved=0ahUKEwis9qjyupHWAhUB9GMKHdBuDnwQ6AEIOzAE#v=onepage&q=icmp6_filt%20example&f=false
    //struct icmp6_filter filter;
    //ICMP6_FILTER_SETBLOCKALL(&filter);
    //ICMP6_FILTER_SETPASS(ND_ROUTER_ADVERT, &filter);
    //setsockopt(sock, IPPROTO_ICMPV6, ICMP_FILTER, &filter, sizeof(&filter));
    //----

}

void DetachThreadFromVM(void) {
    javaVM->DetachCurrentThread();
}

void loadTextResource(std::string* resource, const std::string& base, const std::string& extension) {
    // Cannot share a JNIEnv between threads. Need to store the JavaVM, and use JavaVM->GetEnv to discover the thread's JNIEnv
    JNIEnv *env = NULL;
    int status = javaVM->GetEnv((void **)&env, JNI_VERSION_1_6);
    if (status < 0) { //should only happen the first time
        status = javaVM->AttachCurrentThread(&env, NULL);
        if (status < 0) { //really shouldn't happen
            LOG_ERROR("failed to attach current thread");
            *resource = "";
            return;
        }
    }

    std::string path;

    if((extension == "fsh") || (extension == "vsh")) {
        path = "shaders/";
    }
    else {
        path = "data/";
    }
    std::string final = path + base + "." + extension;

    jstring javaString = env->NewStringUTF(final.c_str());
    jclass klass = env->GetObjectClass(activity);
    jmethodID methodID = env->GetMethodID(klass, "readFileAsBytes", "(Ljava/lang/String;)[B");
    jbyteArray result = (jbyteArray)env->CallObjectMethod(activity, methodID, javaString);
    env->DeleteLocalRef(javaString);
    env->DeleteLocalRef(klass);

    //LOG("starting jni copy");
    jboolean isCopy;
    jbyte* resultChars = env->GetByteArrayElements(result, &isCopy);
    //LOG("done jni copy: %d", isCopy);
    jsize size = env->GetArrayLength(result);

    //LOG("jbytearray size: %d", size);
    resource->assign((const char*)resultChars, size);
    //LOG("stdstring size: %d", resource->length());
    env->ReleaseByteArrayElements(result, resultChars, JNI_ABORT);
    env->DeleteLocalRef(result);
}

bool deviceIsOld() {
    return false;
}

//call one of the threadsafe InternetMap methods
void callThreadsafeVoidMethod(const char *methodName) {
    JNIEnv *env = NULL;
    int status = javaVM->GetEnv((void **)&env, JNI_VERSION_1_6);
    if (status < 0) { //shouldn't happen
        LOG_ERROR("failed to get JNI environment, assuming native thread");
        status = javaVM->AttachCurrentThread(&env, NULL);
        if (status < 0) { //really shouldn't happen
            LOG_ERROR("failed to attach current thread");
            return;
        }
    }

    jclass klass = env->GetObjectClass(activity);
    jmethodID methodID = env->GetMethodID(klass, methodName, "()V");
    env->CallVoidMethod(activity, methodID);
}

//note: we can only call specifically threadsafe functions from these callbacks
void cameraMoveFinishedCallback(void) {
    callThreadsafeVoidMethod("threadsafeShowNodePopup");
}
void cameraResetFinishedCallback(void){
    callThreadsafeVoidMethod("threadsafeCameraResetCallback");
}
void loadFinishedCallback() {
    callThreadsafeVoidMethod("threadsafeLoadFinishedCallback");
}

// TODO
void lostSelectedNodeCallback(void) {
}
