package com.peer1.internetmap;

import android.app.Application;
import android.content.res.Configuration;

import timber.log.Timber;
import uk.co.chrisjenx.calligraphy.CalligraphyConfig;

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

        CalligraphyConfig.initDefault(new CalligraphyConfig.Builder()
                        .setDefaultFontPath(getString(R.string.font_regular))
                        .setFontAttrId(R.attr.fontPath)
                        .build());

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
