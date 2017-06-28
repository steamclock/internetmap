package com.peer1.internetmap.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.peer1.internetmap.App;

/**
 * Created by shayla on 2017-06-28.
 */

public class SharedPreferenceUtils {
    private final static String FIRST_RUN = "firstrun";
    public static boolean getIsFirstRun() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        return prefs.getBoolean(FIRST_RUN, true);
    }

    public static void setIsFirstRun(boolean isFirstRun) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        prefs.edit().putBoolean(FIRST_RUN, isFirstRun).commit();
    }

}
