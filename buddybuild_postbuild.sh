#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

echo "TOKEN THEN PRIVATE"
echo $Crashlytics_token
echo $Crashlytics_private
echo $BUDDYBUILD_PRODUCT_DIR
echo "____"

./iOS/Fabric.framework/uploadDSYM -a $CRASHLYTICS_API_KEY -p ios
./iOS/Fabric.framework/run $Crashlytics_token $Crashlytics_private
