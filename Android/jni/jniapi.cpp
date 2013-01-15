#include <stdint.h>
#include <jni.h>
#include <android/native_window.h> // requires ndk r5 or newer
#include <android/native_window_jni.h> // requires ndk r5 or newer
#include <string>
#include "jniapi.h"
#include "renderer.h"

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

JNIEXPORT void JNICALL Java_com_peer1_internetmap_InternetMap_nativeOnCreate(JNIEnv* jenv, jobject obj)
{
	LOG("OnCreate");

    renderer = new Renderer();
    activity = jenv->NewGlobalRef(obj);
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

std::string loadTextResource(std::string base, std::string extension) {
    // Cannot share a JNIEnv between threads. Need to store the JavaVM, and use JavaVM->GetEnv to discover the thread's JNIEnv
    JNIEnv *env = NULL;
    int status = javaVM->GetEnv((void **)&env, JNI_VERSION_1_6);
    if(status < 0)
    {
        LOG_ERROR("failed to get JNI environment, assuming native thread");
        status = javaVM->AttachCurrentThread(&env, NULL);
        if(status < 0)
        {
            LOG_ERROR("failed to attach current thread");
            return "";
        }
    }

	std::string final = std::string("shaders/") + base + "." + extension;

	jstring javaString = env->NewStringUTF(final.c_str());
	jclass klass = env->GetObjectClass(activity);
	jmethodID methodID = env->GetMethodID(klass, "readFileAsString", "(Ljava/lang/String;)Ljava/lang/String;");
	jstring result = (jstring)env->CallObjectMethod(activity, methodID, javaString);
	env->DeleteLocalRef(javaString);

	const char* resultChars = env->GetStringUTFChars(result,0);

	std::string resultObj(resultChars);
	env->ReleaseStringUTFChars(result,resultChars);
	env->DeleteLocalRef(result);
	return resultObj;
}
