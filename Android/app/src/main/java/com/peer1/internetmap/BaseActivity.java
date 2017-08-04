package com.peer1.internetmap;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.support.annotation.Nullable;

import com.peer1.internetmap.utils.AppUtils;

import uk.co.chrisjenx.calligraphy.CalligraphyContextWrapper;

/**
 * Extends Activity; overrides attachBaseContext which sets a default font for the entire app.
 */
public class BaseActivity extends Activity {
    @Override
    protected void attachBaseContext(Context newBase) {
        super.attachBaseContext(CalligraphyContextWrapper.wrap(newBase));
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Attempt to determine the best orientation
        AppUtils.forceOrientation(this);
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        // Force again in case the user was playing with an orientation app
        AppUtils.forceOrientation(this);
    }
}
