The Cogeco Peer 1 Map of the Internet
===========

This is a 3D interactive map of the infrastructure of the internet.

In 2013, the teams at Cogeco Peer 1 and Steamclock Software designed and developed this map for iOS and Android. It uses data from CAIDa, the Center for Applied Internet Data Analysis, which maps the key ISPs, exchange points, universities, and other organizations that run the Autonomous Systems that route traffic online.

In 2017, we teamed up again to bring the apps back online with new data from CAIDA, and to release the code as an open source project for the benefit of the community. We expect to have an updated release available on the App Store and Play Store very soon.

Project Structure
=================

This project has three key parts:

1. The C++ core: This is the OpenGL visualization code and the model layer that is shared between projects. These files are found in the Common folder.
2. The iOS app: This is an Objective-C++ project that provides native UI on iPhone and iPad. It is live on the [App Store](https://itunes.apple.com/us/app/map-internet-by-peer-1-hosting/id605924222).
3. [The Android app](Android/README.md): This is a Java NDK project that does the native UI on Android phones and tablets. It is live on the [Play Store](https://play.google.com/store/apps/details?id=com.peer1.internetmap&hl=en).
