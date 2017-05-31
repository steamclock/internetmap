LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := internetmaprenderer
LOCAL_CFLAGS    := -Wall
LOCAL_SRC_FILES := jniapi.cpp renderer.cpp ../Common/Code/OpenGL.cpp ../Common/Code/DisplayLines.cpp ../Common/Code/DisplayNodes.cpp \
                   ../Common/Code/Program.cpp ../Common/Code/VertexBuffer.cpp ../Common/Code/Camera.cpp ../Common/Code/MapDisplay.cpp ../Common/Code/MapUtilities.cpp \
                   ../Common/Code/DefaultVisualization.cpp ../Common/Code/TypeVisualization.cpp ../Common/Code/Connection.cpp ../Common/Code/Node.cpp \
                   ../Common/Code/IndexBox.cpp ../Common/Code/MapData.cpp ../Common/Code/MapController.cpp jsoncpp/jsoncpp.cpp ../Common/Code/GlobeVisualization.cpp
LOCAL_LDLIBS    := -llog -landroid -lEGL -lGLESv2
LOCAL_CPP_FEATURES += exceptions

include $(BUILD_SHARED_LIBRARY)
