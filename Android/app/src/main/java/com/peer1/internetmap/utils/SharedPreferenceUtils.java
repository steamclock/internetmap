package com.peer1.internetmap.utils;

import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.google.gson.Gson;
import com.peer1.internetmap.App;

import timber.log.Timber;

/**
 * Central manager for all data stored in SharedPreferences
 */
public class SharedPreferenceUtils {

    // Stored Preference IDs
    private final static String TOOLTIP_STATUSES = "TOOLTIP_STATUSES";

    //--------------------------------------------------------------
    // region Tooltip Status
    // * Index 0 = Help page, 1-4 = tooltips
    // * Array of booleans indicates if the tooltip has been shown for
    //   a given item.
    // * false = has not been shown, true = has been shown
    //--------------------------------------------------------------
    /**
     * @return The index of the tooltip that should be shown.
     */
    public static int getNextTooltipIndex() {
        Boolean[] tooltipStatuses = getTooltipStatuses();
        for (int i=0; i < tooltipStatuses.length; i++) {
            if (!tooltipStatuses[i]) {
                // Find first false item.
                Timber.v("getNextTooltipIndex: " + i);
                return i;
            }
        }

        return -1;
    }

    public static void markTooltipAsShown(int tooltipIndex) {
        setTooltipStatus(tooltipIndex, true);
    }

    public static void resetTooltip(int tooltipIndex) {
        setTooltipStatus(tooltipIndex, false);
    }

    /**
     * Updates array index value and saves to SharedPrefs
     */
    private static void setTooltipStatus(int tooltipIndex, boolean hasBeenSeen) {
        Boolean[] tooltipStatus = getTooltipStatuses();

        if (tooltipIndex > tooltipStatus.length) {
            Timber.e("markTooltipAsShown given invalid index");
            return;
        }

        tooltipStatus[tooltipIndex] = hasBeenSeen;
        setTooltipStatuses(tooltipStatus);
    }

    private static Boolean[] getTooltipStatuses() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        String jsonStr = prefs.getString(TOOLTIP_STATUSES, null);

        Boolean[] result;

        if (jsonStr == null) {
            // 0 = Help page, 1-4 = tooltips
            result = new Boolean[]{false, false, false, false};
        } else {
            try {
                Gson gson = new Gson();
                result = gson.fromJson(jsonStr, Boolean[].class);
            } catch (Exception e) {
                Timber.e("getTooltipStatuses failed.");
                // Failed case, assume all have been shown.
                result = new Boolean[]{true, true, true, true};
            }
        }

        return result;
    }

    private static void setTooltipStatuses(Boolean[] statuses) {
        Gson gson = new Gson();
        String jsonStr = gson.toJson(statuses, Boolean[].class);

        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(App.getAppContext());
        prefs.edit().putString(TOOLTIP_STATUSES, jsonStr).commit();
    }

    /**
     * @return True if it is the first time running the app
     */
    public static boolean getIsFirstRun() {
        return SharedPreferenceUtils.getNextTooltipIndex() == 0;
    }

    // endregion
}
