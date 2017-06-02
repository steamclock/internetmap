package com.peer1.internetmap;

import android.content.Context;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;

/**
 * Created by shayla on 2017-06-02.
 */

public class GlobalSettings {

    private String defaultYear = "2017";

    private Set<String> simulatedYears = new HashSet<String>(); // Default to empty

    public GlobalSettings(Context context) {

        JSONObject settingsJson = null;
        // Attempt to parse from data/globalSettings.json
        try {
            settingsJson = new JSONObject(new String(Helper.readFileAsBytes(context, "data/globalSettings.json")));
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
