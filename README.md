internetmap
===========

Peer1 Map of the Internet


Android Build Setup Instructions
================================

1. Install Eclipse and the Android SDK (You can get either a combined version of Eclipse and the Android SDK, or a standalone version of the SDK from here: http://developer.android.com/sdk/index.html)

2. Make sure that you have installed the correct SDK via the Android SDK Manager (run tools/android in the location the SDK was installed, make sure that the 4.2 / API 17 version is installed)

3. Note that when you create your Eclipse workspace on first startup (if you haven't used eclipse before) it doesn't need to be, and shouldn't be, anywhere near the repo location. You can just stick it in some random directory and then 'import' the project (see later), in spite of the name of the command it'll keep it in the original location.

4. Install the C/C++ Development tools for Eclipse. Go to 'Help -> Install New Software', pick the a site to download from (I used http://download.eclipse.org/releases/indigo, which looked default-ish), and then under 'Programming Languages' pick 'C/C++ Development Tools, and kick off the install.

5. Grab the Android NDK from here: http://developer.android.com/tools/sdk/ndk/index.html

6. Locally modify a broken script in the NDK

Edit this file:
  C:\android-ndk-r8d\build\gmsl\__gmsl

...and change line 512 to:
  int_encode = $(__gmsl_tr1)$(wordlist 1,$(words $1),$ (__gmsl_input_int))

7. Get the project into your eclipse workspace via the File->Import command (Select Existing project from under general, and point it at the Android directory in the git repo). 

8. In the preferences for Eclipse, define NDKROOT under C/C++ -> Build -> Build Variables to point to the directory that you unpacked the NDK to. Select 'Directory' from the dropdown menu in the GUI, and NOT 'Path'. Even though you'd think Path is what you'd want. Nopers.

Congratulations, you have a setup that might conceivably build the Android version of the project!

Other Android Gotchas & Advice
==============================

- The build environment that the actual external build process runs in and the environment that Eclipse's C++ support runs it's analysis in are totally unrelated, so you can easily get a bunch of spurious errors if Eclipse is misconfigured. Check the 'Console' window to see what errors are actually coming from the build and which are just Eclipse losing the plot. For the spurious errors, you may need to tweak the include paths in some way (it might not find some of the system headers if NDKROOT is set wrong). You can always work around spurious errors by: doing a build (CMD-B), check that it did complete properly in the console, try to run (it'll give you an error), go into the Problems tab and delete the errors, then run again (it'll work this time). Having all the C++ files closed in the editor also seems to help with not getting spurious errors. If you get a persistent error about the versions not matching that won't go away, you may be able to fix it via turning it into a warning, per the instructions here: http://code.google.com/p/android/issues/detail?id=39752.

- C++ files are not automatically added to ht build, you need to edit Android.mk in the jni/ directory to add them.

- We're using shared_ptr from the standard library on iOS and from boost on Android, but there is no convenient way to typdef one into the others namespace it into the std namespace, so Types.hpp contains a 'using' to pull in either the std or boost version as appropriate. We should be including Types.hpp instead of <memory> and using 'shared_ptr' not 'std::shared_ptr'. Using std::shared_ptr or boost::shared_ptr will generally work on one platform but not the other.

- In general, you should be testing (At the very least, building) any changes made to C++ code on both platforms.

- printf doesn't output to the log window in Eclipse, I added a 'LOG' macro to Types.hpp that maps to the right log function on Android and printf on iOS.

- You need an actual android device set up for dev (OpenGL ES 2 doesn't work in the simulator)

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

To take a print resolution screenshot, you need to do the following:

- Turn the screenshot button on locally by commenting out the line "self.screenshotButton.hidden = YES;" in ViewController.m

- If necessary modify the number of subdivisions to do by changing AXIS_DIVISIONS in ViewController.m (the default is 8, whihc will produce a 16k shot on a retina iPad, different values may be needed for other devices to get the desired resolutions).

- Run the application, set up the intended view, and hit the screenshot button in the upper right hand corner.

- Download the data from the app
  - Open the Organizer window in XCode 
  - Go to the devices tab
  - Find the current device
  - Click on the "Applications" section
  - Hit download at the bottom of the window and pick a location

- If you don't have it install Imagemagick (with homebrew, you can do 'brew install imagemagick')

- Open up a terminal and go to the AppData/Documetn directory inside the bundle you downloaded 

- Run the following command : montage screenshot*.png -mode concatenate -tile 8x8 final.png
  - You may need to change "8x8" if you changed AXIS_DIVISIONS earlier


