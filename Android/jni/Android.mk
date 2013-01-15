LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := internetmaprenderer
LOCAL_CFLAGS    := -Wall
LOCAL_SRC_FILES := jniapi.cpp renderer.cpp common/OpenGL.cpp common/Lines.cpp common/Nodes.cpp \
                   common/Program.cpp common/Camera.cpp common/MapDisplay.cpp
LOCAL_LDLIBS    := -llog -landroid -lEGL -lGLESv2

include $(BUILD_SHARED_LIBRARY)
