#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

$BUDDYBUILD_WORKSPACE/Fabric.framework/uploadDSYM -a $CRASHLYTICS_TOKEN -p ios $BUDDYBUILD_PRODUCT_DIR

echo $BUDDYBUILD_WORKSPACE

./Fabric.framework/run $Crashlytics_token
