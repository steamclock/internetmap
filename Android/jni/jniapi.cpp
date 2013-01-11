#include <stdint.h>
#include <jni.h>
#include <android/native_window.h> // requires ndk r5 or newer
#include <android/native_window_jni.h> // requires ndk r5 or newer

#include "jniapi.h"
#include "renderer.h"

static ANativeWindow *window = 0;
static Renderer *renderer = 0;

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnCreate(JNIEnv* jenv, jobject obj)
{
    renderer = new Renderer();
    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnResume(JNIEnv* jenv, jobject obj)
{
    renderer->start();
    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnPause(JNIEnv* jenv, jobject obj)
{
    renderer->stop();
    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnStop(JNIEnv* jenv, jobject obj)
{
    delete renderer;
    renderer = 0;
    return;
}

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeSetSurface(JNIEnv* jenv, jobject obj, jobject surface)
{
    if (surface != 0) {
        window = ANativeWindow_fromSurface(jenv, surface);
        renderer->setWindow(window);
    } else {
        ANativeWindow_release(window);
    }

    return;
}

