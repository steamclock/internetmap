LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := internetmaprenderer
LOCAL_CFLAGS    := -Wall
LOCAL_SRC_FILES := jniapi.cpp renderer.cpp
LOCAL_LDLIBS    := -llog -landroid -lEGL -lGLESv1_CM 

include $(BUILD_SHARED_LIBRARY)
