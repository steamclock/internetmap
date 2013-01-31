#include <stdint.h>
#include <jni.h>
#include <android/native_window.h> // requires ndk r5 or newer
#include <android/native_window_jni.h> // requires ndk r5 or newer
#include <string>
#include "jniapi.h"
#include "renderer.h"

#include <common/MapController.hpp>
#include <common/MapDisplay.hpp>
#include <common/Camera.hpp>

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

    jclass nodeWrapperClass = jenv->FindClass("com/peer1/internetmap/NodeWrapper");
    jmethodID constructor = jenv->GetMethodID(nodeWrapperClass, "<init>",
            "(IFILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
    //note: if you change this code, triple-check that the argument order matches NodeWrapper.
    jobject wrapper = jenv->NewObject(nodeWrapperClass, constructor, node->index, node->importance,
            node->connections.size(), jenv->NewStringUTF(node->asn.c_str()),
            jenv->NewStringUTF(node->friendlyDescription().c_str()), jenv->NewStringUTF(node->typeString.c_str()));
    return wrapper;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnCreate(JNIEnv* jenv, jobject obj)
{
    LOG("OnCreate");

    if(!renderer) {
        renderer = new Renderer();
    }
    activity = jenv->NewGlobalRef(obj);
    return;
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

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnStop(JNIEnv* jenv, jobject obj)
{
//    delete renderer;
//    renderer = NULL;

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
    LOG("zoom");
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
    jobject wrapper = wrapNode(jenv, node);

    renderer->endControllerModification();
    return wrapper;
}

JNIEXPORT int JNICALL Java_com_peer1_internetmap_MapControllerWrapper_targetNodeIndex(JNIEnv* jenv, jobject obj) {
    MapController* controller = renderer->beginControllerModification();
    //not actually modifying anything here... TODO can I have a readonly accessor instead?
    int ret = controller->targetNode;
    renderer->endControllerModification();
    return ret;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_updateTargetForIndex(JNIEnv* jenv, jobject obj, int index) {
    MapController* controller = renderer->beginControllerModification();
    controller->updateTargetForIndex(index);
    renderer->endControllerModification();
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
    jmethodID methodID = env->GetMethodID(klass, "readFileAsString", "(Ljava/lang/String;)Ljava/lang/String;");
    jstring result = (jstring)env->CallObjectMethod(activity, methodID, javaString);
    env->DeleteLocalRef(javaString);

    const char* resultChars = env->GetStringUTFChars(result,0);

    *resource = resultChars;
    env->ReleaseStringUTFChars(result,resultChars);
    env->DeleteLocalRef(result);
}

bool deviceIsOld() {
    return false;
}

//note: we can only call specifically threadsafe functions here
void cameraMoveFinishedCallback(void) {
    LOG("cameraMoveFinishedCallback");
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
    jmethodID methodID = env->GetMethodID(klass, "threadsafeShowNodePopup", "()V");
    env->CallObjectMethod(activity, methodID);
}

// TODO
void lostSelectedNodeCallback(void) {
}
