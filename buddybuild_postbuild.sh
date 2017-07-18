#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

echo "TOKEN THEN PRIVATE"
echo $Crashlytics_token
echo $Crashlytics_private
echo $BUDDYBUILD_PRODUCT_DIR
echo "____"

export BUILT_PRODUCTS_DIR=$BUDDYBUILD_PRODUCT_DIR
./iOS/Fabric.framework/uploadDSYM -a $CRASHLYTICS_API_KEY -p ios BUILT_PRODUCTS_DIR
