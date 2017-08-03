cmake_minimum_required(VERSION 3.4.1)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")

set(BOOST_ROOT ../Android-Boost)
set(BOOST_LIBRARYDIR ../Android-Boost)
set(BOOST_INCLUDEDIR ../Android-Boost)
set(Boost_INCLUDE_DIR ../Android-Boost)

set(Boost_USE_STATIC_LIBS   ON)
set(Boost_USE_MULTITHREADED ON)

find_package(Boost)

include_directories(.)

include_directories(${Boost_INCLUDE_DIRS})

# Specifies a library name, specifies whether the library is STATIC or
# SHARED, and provides relative paths to the source code. You can
# define multiple libraries by adding multiple add.library() commands,
# and CMake builds them for you. When you build your app, Gradle
# automatically packages shared libraries with your APK.
add_library(internetmaprenderer SHARED
            jniapi.cpp
            renderer.cpp
            ../Common/Code/OpenGL.cpp
            ../Common/Code/DisplayLines.cpp
            ../Common/Code/DisplayNodes.cpp
            ../Common/Code/Program.cpp
            ../Common/Code/VertexBuffer.cpp
            ../Common/Code/Camera.cpp
            ../Common/Code/MapDisplay.cpp
            ../Common/Code/MapUtilities.cpp
            ../Common/Code/DefaultVisualization.cpp
            ../Common/Code/TypeVisualization.cpp
            ../Common/Code/Connection.cpp
            ../Common/Code/Node.cpp
            ../Common/Code/IndexBox.cpp
            ../Common/Code/MapData.cpp
            ../Common/Code/MapController.cpp
            jsoncpp/jsoncpp.cpp
            ../Common/Code/GlobeVisualization.cpp
)

find_library( # Sets the name of the path variable.
              log-lib

              # Specifies the name of the NDK library that
              # you want CMake to locate.
              log )

target_link_libraries(internetmaprenderer
                      android
                      EGL
                      log
                      GLESv2
                      ${log-lib}
                      ${Boost_LIBRARIES})

# Android Studio 2.2.0 with CMake support does not pack stl shared libraries,
# so app needs to pack the right shared lib into APK. This sample uses solution
# from https://github.com/jomof/ndk-stl to find the right stl shared lib to use
# and copy it to the right place for Android Studio to pack
# Usage: download ndk-stl-config.cmake into app's directory hosting CMakeLists.txt
#        and just use it with the following line
#include(ndk-stl-config.cmake)