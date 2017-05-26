package com.peer1.internetmap;

import android.app.Application;
import android.content.res.Configuration;

import timber.log.Timber;

/**
 * Created by shayla on 2017-05-10.
 */

public class App extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

        // Setup logging
        if (BuildConfig.DEBUG) {
            Timber.plant(new Timber.DebugTree());
        } else {
            // TODO production logging
        }
    }

    @Override
    public void onTerminate() {
        super.onTerminate();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
    }

    @Override
    public void onLowMemory() {
        super.onLowMemory();
    }
}
