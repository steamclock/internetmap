#!/usr/bin/env bash
echo "Staring prebuild..."

# Merge the contents of the secure plist containing Fabric secret key into Info.plist
echo "Adding Fabric key to plist"
/usr/libexec/PlistBuddy -x -c "Merge ${BUDDYBUILD_SECURE_FILES}/info.plist" "Info.plist"
/usr/libexec/PlistBuddy -x -c "Print :Fabric" "Info.plist"

echo "Running Fabric build phase"
export BUILT_PRODUCTS_DIR=$BUDDYBUILD_PRODUCT_DIR
 ./iOS/Fabric.framework/run $Crashlytics_token

#./iOS/Crashlytics.framework/submit $Crashlytics_token $Crashlytics_private

#${XCS_PRIMARY_REPO_DIR}"/MyApp/Pods/Crashlytics/submit <API> <KEY> -ipaPath "${IPA_PATH}" -emails me@test.com

#/usr/libexec/PlistBuddy -c "Add :Fabric dict" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add :Fabric: String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"
#/usr/libexec/PlistBuddy -c "Add Fabric String $BUDDYBUILD_BRANCH" "Info.plist"

#  <key>Fabric</key>
#  <dict>
#    <key>APIKey</key>
#    <string>(redacted)</string>
#    <key>Kits</key>
#    <array>
##      <dict>
 #       <key>KitInfo</key>
#        <dict/>
#        <key>KitName</key>
#        <string>Crashlytics</string>
#      </dict>
#    </array>
#  </dict>

#<dict>
#    <key>CFBundleURLTypes</key>
#    <array>
#        <dict>
#            <key>CFBundleURLName</key>
#            <string>urlname-1</string>
#            <key>CFBundleURLSchemes</key>
#            <array>
#                <string>urlscheme-1</string>
#            </array>
#        </dict>
#    </array>
#</dict>
#/usr/libexec/PlistBuddy 
#-c "clear dict" 
#-c "add :CFBundleURLTypes array" 
#-c "add :CFBundleURLTypes:0 dict" 
#-c "add :CFBundleURLTypes:0:CFBundleURLName string 'urlname-1'" 
#-c "add :CFBundleURLTypes:0:CFBundleURLSchemes array" 
#-c "add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string urlscheme-1"  Info.plist

#echo "Checking PlistBuddy result"
#echo /usr/libexec/PlistBuddy -c "Print"

#Command: Add :BrainCells integer 5
#Command: Add ":Favourite Random Number" real 3.9234
##Command: Add :Intelligent bool false
#Command: Add :Today date "Sat Jun 27 18:51:00 AEST 2015"
#Command: Add :Person dict
#Command: Add :Person:Name string "Fotis Gimian"
#Command: Add :Person:Occupation string "Geek"
#Command: Add :Person:Likes array
#Command: Add :Person:Likes: string Potatoes
#Command: Add :Person:Likes: string Apple
#Command: Add :Person:Likes: string Bouncing
#Command: Print
#Dict {
##    Favourite Random Number = 3.923400
#    Version = 1.1
##    Person = Dict {
#        Likes = Array {
#            Potatoes
##            Apple
 #           Bouncing
#        }
#        Name = Fotis Gimian
#        Occupation = Geek
#    }
#    Intelligent = false
#    BrainCells = 5
#    Today = Sat Jun 27 18:51:00 AEST 2015
#}


