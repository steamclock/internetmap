package com.peer1.internetmap;

import android.app.Application;
import android.content.Context;
import android.content.res.Configuration;

import timber.log.Timber;
import uk.co.chrisjenx.calligraphy.CalligraphyConfig;

public class App extends Application {

    private static App instance;
    private static Context appContext;
    public GlobalSettings globalSettings;

    @Override
    public void onCreate() {
        super.onCreate();

        instance = this;
        appContext = this;

        if (BuildConfig.DEBUG) {
            Timber.plant(new Timber.DebugTree());
        } else {
            // No longer using Crashlytics
            // TODO determine run time crash reporting
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

    //=====================================================================
    // Static helpers
    //=====================================================================
    public static GlobalSettings getGlobalSettings() {
       return instance.globalSettings;
    }

    public static Context getAppContext() {
        return appContext;
    }
}
