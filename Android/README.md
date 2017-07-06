# Android Project Environment and Build Setup

## Environment Setup Suggestions

The Android project was converted to use the gradle build system via Android Studio. While I suggest you build through Android Studio, it is not required. Since it has already been converted you should be able to open it up via the *Open Exsiting Android Studio Project" option.

## Setting up the NDK

This project makes use of common C++ code which is built via the NDK. 
Please see [the Android Developer docs on getting started with the NDK](https://developer.android.com/ndk/guides/index.html) for the most up to date information on setting up the NDK on your machine.

To allow us to more easily use the C++ code found in the Common folder, the `Android-NDK` folder which contains the relevant NDK make and wrapper files has been placed as a top level folder in this repo. 

### Building the APK

Gradle is used to build all components for the project. Before building any application files, the gradle script will copy over shared assets from the Common/Data folder and the C++ code should be automatically compiled (via the `Android-NDK/Android.mk` file). If there is an issue generating the C++ component of the project, you may need to manually select `Build -> Refresh Linked C++ Projects" and then run your gradle assemble again.