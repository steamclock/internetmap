#ifndef JNIAPI_H
#define JNIAPI_H

extern "C" {
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnCreate(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnResume(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnPause(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnStop(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeSetSurface(JNIEnv* jenv, jobject obj,
        jobject surface, float scale);

//mapcontroller
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_rotateRadiansXY(JNIEnv* jenv, jobject obj,
        float radX, float radY);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_startMomentumPanWithVelocity(JNIEnv* jenv, jobject obj,
        float vX, float vY);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_handleTouchDownAtPoint(JNIEnv* jenv, jobject obj,
        float x, float y);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_zoomByScale(JNIEnv* jenv, jobject obj,
        float scale);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_startMomentumZoomWithVelocity(JNIEnv* jenv, jobject obj,
        float velocity);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_rotateRadiansZ(JNIEnv* jenv, jobject obj,
        float radians);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_startMomentumRotationWithVelocity(JNIEnv* jenv, jobject obj,
        float velocity);
JNIEXPORT bool JNICALL Java_com_peer1_internetmap_MapControllerWrapper_selectHoveredNode(JNIEnv* jenv, jobject obj);
JNIEXPORT jobject JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nodeAtIndex(JNIEnv* jenv, jobject obj, int index);
JNIEXPORT int JNICALL Java_com_peer1_internetmap_MapControllerWrapper_targetNodeIndex(JNIEnv* jenv, jobject obj);
JNIEXPORT jobject JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nodeByAsn(JNIEnv* jenv, jobject obj, jstring asn);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_updateTargetForIndex(JNIEnv* jenv, jobject obj,
        int index);
JNIEXPORT int JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nodeCount(JNIEnv* jenv, jobject obj);

//nodewrapper
JNIEXPORT jstring JNICALL Java_com_peer1_internetmap_NodeWrapper_nativeFriendlyDescription(JNIEnv* jenv, jobject obj, int index);
};

#endif // JNIAPI_H
