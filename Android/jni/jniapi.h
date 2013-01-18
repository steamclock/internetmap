#ifndef JNIAPI_H
#define JNIAPI_H

extern "C" {
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnCreate(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnResume(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnPause(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnStop(JNIEnv* jenv, jobject obj);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeSetSurface(JNIEnv* jenv, jobject obj,
        jobject surface, float scale);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeRotateRadiansXY(JNIEnv* jenv, jobject obj,
        float radX, float radY);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeStartMomentumPanWithVelocity(JNIEnv* jenv, jobject obj,
        float vX, float vY);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeHandleTouchDownAtPoint(JNIEnv* jenv, jobject obj,
        float x, float y);
JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeZoomByScale(JNIEnv* jenv, jobject obj,
        float scale);
};

#endif // JNIAPI_H
