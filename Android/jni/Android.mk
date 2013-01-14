LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := internetmaprenderer
LOCAL_CFLAGS    := -Wall
LOCAL_SRC_FILES := jniapi.cpp renderer.cpp ../../InternetMap/OpenGL.cpp ../../InternetMap/Lines.cpp ../../InternetMap/Nodes.cpp \
                   ../../InternetMap/Program.cpp ../../InternetMap/Camera.cpp ../../InternetMap/MapDisplay.cpp
LOCAL_LDLIBS    := -llog -landroid -lEGL -lGLESv1_CM -lGLESv2

include $(BUILD_SHARED_LIBRARY)
