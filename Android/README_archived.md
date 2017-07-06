*Archived Android Build Instructions*

The following information is deprecated, but kept around as reference since the NDK is a finicky thing. Please see the normal README for updated instructions. 


Android Build Setup Instructions
================================

1. Install Eclipse and the Android SDK (You can get either a combined version of Eclipse and the Android SDK, or a standalone version of the SDK from here: http://developer.android.com/sdk/index.html)

2. Make sure that you have installed the correct SDK via the Android SDK Manager (run tools/android in the location the SDK was installed, make sure that the 4.2 / API 17 version is installed)

3. Note that when you create your Eclipse workspace on first startup (if you haven't used eclipse before) it doesn't need to be, and shouldn't be, anywhere near the repo location. You can just stick it in some random directory and then 'import' the project (see later), in spite of the name of the command it'll keep it in the original location.

4. Install the C/C++ Development tools for Eclipse. Go to 'Help -> Install New Software', pick the a site to download from (I used http://download.eclipse.org/releases/indigo, which looked default-ish), and then under 'Programming Languages' pick 'C/C++ Development Tools, and kick off the install.

5. Grab the Android NDK from here: http://developer.android.com/tools/sdk/ndk/index.html

6. Locally modify a broken script in the NDK

Edit this file:
```
C:\android-ndk-r8d\build\gmsl\__gmsl
```

...and change line 512 to:
```
int_encode = $(__gmsl_tr1)$(wordlist 1,$(words $1),$ (__gmsl_input_int))
```

7. Get the project into your eclipse workspace via the File->Import command (Select Existing project from under general, and point it at the Android directory in the git repo). 

8. In the preferences for Eclipse, define NDKROOT under C/C++ -> Build -> Build Variables to point to the directory that you unpacked the NDK to. Select 'Directory' from the dropdown menu in the GUI, and NOT 'Path'. Even though you'd think Path is what you'd want. Nopers.

Congratulations, you have a setup that might conceivably build the Android version of the project!

9. In Eclipse preferences, ensure that it is using spaces (not tabs) in java, c++ and other files:
    Java->Code Style->Formatter->Edit->Indentation = "Spaces Only"
    C/C++->Code Style->Formatter->Edit->Indentation = "Spaces Only"
    General->Editors->Text Editors->Insert spaces for tabs

Other Android Gotchas & Advice
==============================

- The build environment that the actual external build process runs in and the environment that Eclipse's C++ support runs it's analysis in are totally unrelated, so you can easily get a bunch of spurious errors if Eclipse is misconfigured. Check the 'Console' window to see what errors are actually coming from the build and which are just Eclipse losing the plot. For the spurious errors, you may need to tweak the include paths in some way (it might not find some of the system headers if NDKROOT is set wrong). You can always work around spurious errors by: doing a build (CMD-B), check that it did complete properly in the console, try to run (it'll give you an error), go into the Problems tab and delete the errors, then run again (it'll work this time). Having all the C++ files closed in the editor also seems to help with not getting spurious errors. If you get a persistent error about the versions not matching that won't go away, you may be able to fix it via turning it into a warning, per the instructions here: http://code.google.com/p/android/issues/detail?id=39752.

- C++ files are not automatically added to ht build, you need to edit Android.mk in the jni/ directory to add them.

- We're using shared_ptr from the standard library on iOS and from boost on Android, but there is no convenient way to typdef one into the others namespace it into the std namespace, so Types.hpp contains a 'using' to pull in either the std or boost version as appropriate. We should be including Types.hpp instead of <memory> and using 'shared_ptr' not 'std::shared_ptr'. Using std::shared_ptr or boost::shared_ptr will generally work on one platform but not the other.

- In general, you should be testing (At the very least, building) any changes made to C++ code on both platforms.

- printf doesn't output to the log window in Eclipse, I added a 'LOG' macro to Types.hpp that maps to the right log function on Android and printf on iOS.

- Using an actual android device for dev is recommended. Using the emulator is possible, see instructions below on how to set it up and make it run a bit faster.

- Some devices need to be put in developer mode or otherwise set up before they can be used. 
	Nexus 7 : http://jaymartinez.blogspot.ca/2012/11/enable-developer-mode-on-nexus-7.html
	Kindle Fire :
	  - Steps 4-6 from here: https://developer.amazon.com/sdk/fire/setup.html
	  - Plus this: https://developer.amazon.com/sdk/fire/connect-adb.html
	
- Workaround for another spurious error: http://stackoverflow.com/questions/13416142/unexpected-value-from-nativegetenabledtags-0

- If the run button does nothing: switch to a .java file

- If the built-in help docs don't work: use a web browser (developer.android.com)

- If all else fails, restart Eclipse

- If you get a crash in native code on Android, you can extract a callstack via the following (note, env variables are not defined by default, you need to either define them, or replace with actual paths):
  $(ANDROIDSDK)/platform-tools/adb logcat | $(NDKROOT)/ndk-stack -sym $(PROJECTROOT)/obj/local/armeabi 

Taking high-res screenshots
===========================

To take a print resolution screenshot on a Mac, you need to do the following:

- Create a "InternetMap" subdirectory in you Home directory (The output path is currently hardcoded)

- Open the "HighRes" project and build and run it.

- Set up the intended view.
  - Left click and drag rotates. 
  - Right click and drag zooms. 
  - You can select nodes by clicking on them.

- Hit the space bar to take a screenshot. This will write a single 4k 'master' screenshot (the whole scene in a single image), and a number of 4k 'tile' screenshots.
	- Intel HD 3000 will max out at 8k (2x2 4k)
	- Intel HD 4000 and discrete GPUs should do 16k (4x4 4k)

- If you don't have it, install Imagemagick (with homebrew, you can do 'brew install imagemagick')

- Open up a terminal and go to the ~/InternetMap directory.

- Run the following command : montage tile*.png -mode concatenate -tile 4x4 final.png
  - You may need to use '2x2' instead of '4x4' how many tiles were produced.

Note that the print resolution version may have the larger nodes appear smaller than in the the original image from the live window. There are hardware limitations on point sprite size that will get hit on some hardware. There doesn't appear to be any way to resolve this right now.

Getting the app working in the Android emulator
====================================================

Turns out the newest emulator actually does support openGL ES 2.0, you just have to do a bit of build magic to get it working: (Some of the following stuff is not actually required, but it increases the speed of the emulator)

Open the Android SDK Manager by running 'android' in a terminal in your android-sdk/tools folder. I'd recommend adding android-sdk/tools and android-sdk/platform-tools to your PATH.
Download an Android sdk with API level >= 15 (starting at 4.0.3) and make sure you also download the 'Intel x86 Atom System Image'.
Open the AVD Manager by running 'android avd'.
Create a new AVD and make sure that:

- The target API Level is >= 15
- The CPU/ABI is x86
- "Use Host GPU" is selected

Now, go to http://developer.android.com/tools/devices/emulator.html and search for 'Configuring VM Acceleration on Mac' and follow the steps there.

Now, re-run ndk-build from your IDE (in eclipse you should be able to just do a new build). This is necessary because we're now also building for a different platform (x86).

Run the application. If your IDE keeps re-starting the emulator over and over, be sure it is registered in adb: type 'adb devices', and if it doesn't show up, restart adb by typing 'adb kill-server'.

A few caveats:

- The emulator is really slow at startup. openGL performance isn't too bad though.
- The emulator doesn't support multi-touch.