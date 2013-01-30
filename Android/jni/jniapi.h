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
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeRotateRadiansXY(JNIEnv* jenv, jobject obj,
        float radX, float radY);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeStartMomentumPanWithVelocity(JNIEnv* jenv, jobject obj,
        float vX, float vY);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeHandleTouchDownAtPoint(JNIEnv* jenv, jobject obj,
        float x, float y);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeZoomByScale(JNIEnv* jenv, jobject obj,
        float scale);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeStartMomentumZoomWithVelocity(JNIEnv* jenv, jobject obj,
        float velocity);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeRotateRadiansZ(JNIEnv* jenv, jobject obj,
        float radians);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeStartMomentumRotationWithVelocity(JNIEnv* jenv, jobject obj,
        float velocity);
JNIEXPORT bool JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeSelectHoveredNode(JNIEnv* jenv, jobject obj);
JNIEXPORT jobject JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeNodeAtIndex(JNIEnv* jenv, jobject obj, int index);
JNIEXPORT int JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeTargetNodeIndex(JNIEnv* jenv, jobject obj);
JNIEXPORT jobject JNICALL Java_com_peer1_internetmap_MapControllerWrapper_nativeNodeByAsn(JNIEnv* jenv, jobject obj, jstring asn);
};

#endif // JNIAPI_H
