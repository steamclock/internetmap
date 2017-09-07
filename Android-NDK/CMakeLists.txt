cmake_minimum_required(VERSION 3.4.1)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")
# May also need CMAKE_C_FLAGS?

# Boost C++ lib setup
set(BOOST_ROOT ../Android-Boost)
set(BOOST_LIBRARYDIR ../Android-Boost)
set(BOOST_INCLUDEDIR ../Android-Boost)
set(Boost_INCLUDE_DIR ../Android-Boost)
set(Boost_USE_STATIC_LIBS   ON)
set(Boost_USE_MULTITHREADED ON)
find_package(Boost)

# Android-NDK cpp files
include_directories(.)
include_directories(${ANDROID_NDK}/platforms/${ANDROID_PLATFORM}/arch-${ANDROID_ABI}/usr/include)

# Android-Boost header files, kept separate to remove them from 
# Android Studio's auto symbol generation (was taking ~20 mins to build symbols)
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

# Unsure if needed, may be able to remove
find_library(log-lib log)

target_link_libraries(internetmaprenderer
                      android
                      EGL
                      log
                      GLESv2
                      ${log-lib}
                      ${Boost_LIBRARIES})