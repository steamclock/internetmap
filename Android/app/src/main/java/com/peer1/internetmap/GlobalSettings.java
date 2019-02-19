package com.peer1.internetmap;

import android.content.Context;

import com.peer1.internetmap.utils.AppUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

/**
 * GlobalSettings loaded from globalSettings.json (generated in the Data-Pipeline)
 * Currently these settings do not change at run time, they are always loaded from the asset.
 * <p>
 * Note, do not manually update globalSettings.json, this file is generated in the Data-Pipeline
 */
public class GlobalSettings {

    // App should default to show this as the default year.
    private String defaultYear = "2018";

    // List of years which have simulated data sets.
    private Set<String> simulatedYears = new HashSet<String>(); // Default to empty

    public GlobalSettings(Context context) {

        JSONObject settingsJson = null;
        try {
            settingsJson = new JSONObject(new String(AppUtils.readFileAsBytes(context, "data/globalSettings.json")));
        } catch (JSONException e) {
            e.printStackTrace();
            return;
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }

        if (settingsJson.has("defaultYear")) {
            try {
                defaultYear = settingsJson.getString("defaultYear");
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if (settingsJson.has("simulatedYears")) {
            try {
                JSONArray years = settingsJson.getJSONArray("simulatedYears");
                for (int i = 0; i < years.length(); i++) {
                    simulatedYears.add(years.getString(i));
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }

    public String getDefaultYear() {
        return defaultYear;
    }

    public Set<String> getSimulatedYears() {
        return simulatedYears;
    }
}
