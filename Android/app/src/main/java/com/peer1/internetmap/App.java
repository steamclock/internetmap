package com.peer1.internetmap;

import android.app.Application;
import android.content.res.Configuration;

import timber.log.Timber;

/**
 * Created by shayla on 2017-05-10.
 */

public class App extends Application {
    private static App instance;
    public GlobalSettings globalSettings;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;

        // Setup logging
        if (BuildConfig.DEBUG) {
            Timber.plant(new Timber.DebugTree());
        } else {
            // TODO production logging
        }

        globalSettings = new GlobalSettings(this);
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

    // Static helpers
    public static GlobalSettings getGlobalSettings() {
       return instance.globalSettings;
    }
}
