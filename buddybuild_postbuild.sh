#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

echo "TOKEN THEN PRIVATE"
echo $CRASHLYTICS_TOKEN
echo $CRASHLYTICS_PRIVATE
echo "____"

$BUDDYBUILD_WORKSPACE/Fabric.framework/uploadDSYM -a $CRASHLYTICS_TOKEN -p ios $BUDDYBUILD_PRODUCT_DIR
./Fabric.framework/run $CRASHLYTICS_TOKEN $CRASHLYTICS_PRIVATE
