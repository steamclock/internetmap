#!/usr/bin/env bash

echo "Uploading IPAs and dSYMs to Crashlytics"

export BUILT_PRODUCTS_DIR=$BUDDYBUILD_PRODUCT_DIR
./iOS/Fabric.framework/uploadDSYM -a $Crashlytics_token -p ios BUILT_PRODUCTS_DIR
./iOS/Fabric.framework/run $Crashlytics_token $Crashlytics_private
