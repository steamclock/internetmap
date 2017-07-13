package com.peer1.internetmap.utils;

import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.peer1.internetmap.App;

/**
 * Central manager for all data stored in SharedPreferences
 */
public class SharedPreferenceUtils {

    // Stored Preference IDs
    private final static String SHOWING_TOOLTIP_INDEX = "showingTooltipIndex";

    /**
     * @return The index of the tooltip that should be shown.
     */
    public static int getShowingTooltipIndex() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        return prefs.getInt(SHOWING_TOOLTIP_INDEX, 0);
    }

    /**
     * Sets the index of the tooltip that is being shown.
     * @param showingIndex The index of the tooltip to be shown; 0 = Help page, 1-4 = tooltips
     */
    public static void setShowingTooltipIndex(int showingIndex) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        prefs.edit().putInt(SHOWING_TOOLTIP_INDEX, showingIndex).commit();
    }

    /**
     * @return True if it is the first time running the app
     */
    public static boolean getIsFirstRun() {
        return SharedPreferenceUtils.getShowingTooltipIndex() == 0;
    }
}
