package com.peer1.internetmap.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.peer1.internetmap.App;

/**
 * Created by shayla on 2017-06-28.
 */

public class SharedPreferenceUtils {

//    public static void setIsFirstRun(boolean isFirstRun) {
//        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
//        prefs.edit().putBoolean(FIRST_RUN, isFirstRun).commit();
//    }

    private final static String SHOWING_TOOLTIP_INDEX = "showingTooltipIndex";
    public static int getShowingTooltipIndex() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        return prefs.getInt(SHOWING_TOOLTIP_INDEX, 0);
    }

    public static void setShowingTooltipIndex(int showingIndex) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        prefs.edit().putInt(SHOWING_TOOLTIP_INDEX, showingIndex).commit();
    }

    //private final static String FIRST_RUN = "firstrun";
    public static boolean getIsFirstRun() {
        return SharedPreferenceUtils.getShowingTooltipIndex() == 0;
        //SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        //return prefs.getBoolean(FIRST_RUN, true);
    }
}
