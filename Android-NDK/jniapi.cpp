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
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <arpa/inet.h>
#include <sys/select.h>

static ANativeWindow *window = 0;
static Renderer *renderer = 0;

static jobject activity = 0;
static JavaVM* javaVM;

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
    LOG("%s: type=0x%x, id=0x%x, sequence =  0x%x\n",
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

    int sequence = 0;
    int sock = socket(AF_INET,SOCK_DGRAM,IPPROTO_ICMP);
    if (sock < 0) {
        perror("socket");
        return ;
    }

    memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_addr = *dst;

    memset(&icmp_hdr, 0, sizeof icmp_hdr);
    icmp_hdr.icmp_type = ICMP_ECHO;
    //icmp_hdr.un.echo.id = 1234;//arbitrary id

    for (;;) {
        unsigned char data[2048];
        int rc;
        struct timeval timeout = {3, 0}; //wait max 3 seconds for a reply
        fd_set read_set;
        socklen_t slen;
        struct icmp rcv_hdr;

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

        //we don't care about the sender address in this example..
        slen = 0;
        rc = recvfrom(sock, data, sizeof data, 0, NULL, &slen);

        LOG("Receive length, %d bytes\n", slen);

        if (rc <= 0) {
            LOG("recvfrom");
            break;
        } else if (rc < sizeof rcv_hdr) {
            LOG("Error, got short ICMP packet, %d bytes\n", rc);
            break;
        }

        memcpy(&rcv_hdr, data, sizeof rcv_hdr);
        if (rcv_hdr.icmp_type == ICMP_ECHOREPLY) {
            printIcmpHdr("Receive", rcv_hdr);
        } else {
            LOG("Got ICMP packet with type 0x%x ?!?\n", rcv_hdr.icmp_type);
        }
    }
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_sendPacket(JNIEnv* jenv, jobject obj) {

    LOG("traceroute start");

    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);

    if (sock < 0) {
        LOG("Failed to create socket");
        return;
    }

    struct in_addr testaddr;
    inet_aton("13.32.253.9", &testaddr);

    ping_it(&testaddr);

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
