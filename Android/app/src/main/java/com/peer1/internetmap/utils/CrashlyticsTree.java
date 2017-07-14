package com.peer1.internetmap.utils;

import android.util.Log;

import com.crashlytics.android.Crashlytics;

import timber.log.Timber;

/**
 * If Throwable t not set on a Timber log, then these non-fatal exceptions will be listed under
 * com.peer1.internetmap.utils.CrashlyticsTree.log on Fabric the dashboard. If a throwable is set,
 * the non-fatal will be listed under the file that created the exception.
 *
 * If you wish to have better searchable non-fatals, it is recommended to create an exception and pass that to
 * Timber.
 * > Example: Timber.e(new Exception("InvalidJson"), "History.json failed to parse");
 */
public class CrashlyticsTree extends Timber.Tree {
    private static final String CRASHLYTICS_KEY_PRIORITY = "priority";
    private static final String CRASHLYTICS_KEY_TAG = "tag";
    private static final String CRASHLYTICS_KEY_MESSAGE = "message";


    @Override
    protected void log(int priority, String tag, String message, Throwable t) {
        if (priority == Log.VERBOSE || priority == Log.DEBUG || priority == Log.INFO) {
            return;
        }

        Crashlytics.setInt(CRASHLYTICS_KEY_PRIORITY, priority);
        Crashlytics.setString(CRASHLYTICS_KEY_TAG, tag);
        Crashlytics.setString(CRASHLYTICS_KEY_MESSAGE, message);

        if (t == null) {
            Crashlytics.logException(new Exception(message));
        } else {
            Crashlytics.logException(t);
        }
    }
}