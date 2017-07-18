#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

echo "TOKEN THEN PRIVATE"
echo $Crashlytics_token
echo $Crashlytics_private
echo "____"

$BUDDYBUILD_WORKSPACE/Fabric.framework/uploadDSYM -a $Crashlytics_token -p ios $BUDDYBUILD_PRODUCT_DIR
./Fabric.framework/run $Crashlytics_token $Crashlytics_private
