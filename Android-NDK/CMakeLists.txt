# This ensures that a certain set of CMake features is available to
# your build.

cmake_minimum_required(VERSION 3.4.1)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")

#set(LIBRARY_DEPS llog landroid lEGL lGLESv2)

include_directories(.)

# Specifies a library name, specifies whether the library is STATIC or
# SHARED, and provides relative paths to the source code. You can
# define multiple libraries by adding multiple add.library() commands,
# and CMake builds them for you. When you build your app, Gradle
# automatically packages shared libraries with your APK.

add_library( # Specifies the name of the library.
             internetmaprenderer

             # Sets the library as a shared library.
             SHARED

             # Provides a relative path to your source file(s).
             jniapi.cpp renderer.cpp ../Common/Code/OpenGL.cpp ../Common/Code/DisplayLines.cpp ../Common/Code/DisplayNodes.cpp ../Common/Code/Program.cpp ../Common/Code/VertexBuffer.cpp ../Common/Code/Camera.cpp ../Common/Code/MapDisplay.cpp ../Common/Code/MapUtilities.cpp ../Common/Code/DefaultVisualization.cpp ../Common/Code/TypeVisualization.cpp ../Common/Code/Connection.cpp ../Common/Code/Node.cpp ../Common/Code/IndexBox.cpp ../Common/Code/MapData.cpp ../Common/Code/MapController.cpp jsoncpp/jsoncpp.cpp ../Common/Code/GlobeVisualization.cpp
          	)

# add lib dependencies
target_link_libraries(android
                      log 
                      EGL
                      GLESv2)