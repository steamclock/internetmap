#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

CRASHLYTICS_API_KEY=c09d52199d3485c91714d2884df0de38db71f239
echo "Uploading to Fabric via command line"
$BUDDYBUILD_WORKSPACE/Pods/Fabric/upload-symbols -a $CRASHLYTICS_API_KEY -p ios $BUDDYBUILD_PRODUCT_DIR

./Fabric.framework/run $Crashlytics_token
