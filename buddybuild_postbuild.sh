#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

echo "TOKEN THEN PRIVATE"
echo $Crashlytics_token
echo $Crashlytics_private
echo $BUDDYBUILD_PRODUCT_DIR
echo "____"

./iOS/Fabric.framework/uploadDSYM -a $Crashlytics_token -p ios $BUDDYBUILD_PRODUCT_DIR
./iOS/Fabric.framework/run $Crashlytics_token $Crashlytics_private
