LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := internetmaprenderer
LOCAL_CFLAGS    := -Wall
LOCAL_SRC_FILES := jniapi.cpp renderer.cpp common/OpenGL.cpp common/DisplayLines.cpp common/DisplayNodes.cpp \
                   common/Program.cpp common/VertexBuffer.cpp common/Camera.cpp common/MapDisplay.cpp common/MapUtilities.cpp \
                   common/DefaultVisualization.cpp common/Connection.cpp common/Node.cpp \
                   common/IndexBox.cpp common/MapData.cpp common/MapController.cpp jsoncpp/jsoncpp.cpp
LOCAL_LDLIBS    := -llog -landroid -lEGL -lGLESv2
LOCAL_CPP_FEATURES += exceptions

include $(BUILD_SHARED_LIBRARY)
