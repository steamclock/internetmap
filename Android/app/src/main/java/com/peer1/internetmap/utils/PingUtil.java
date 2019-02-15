package com.peer1.internetmap.utils;

import android.os.AsyncTask;
import android.os.Handler;

import com.peer1.internetmap.App;
import com.peer1.internetmap.MapControllerWrapper;
import com.peer1.internetmap.ProbeWrapper;
import com.peer1.internetmap.R;

import java.util.ArrayList;

public class PingUtil {

    //=======================================================================
    // Callback interface; must be set by caller to receive ping updates
    // todo move into a ViewModel once we have upgraded the support libraries fully.
    //=======================================================================
    public interface Listener {

        void onPingResult(int index, ProbeWrapper ping);

        void onPingTimeout(int index);

        void onAverageUpdated(double averageMs);

        void onBestUpdated(double bestMs);

        void onReceivedUpdated(double receivedPercent);

        void onPingAlreadyRunning();

    }

    //=======================================================================
    // Statistics Helper classes
    //=======================================================================
    // Properties could be placed on PingUtil directly, but this allows us to
    // pass back full stats at once if we desire.
    class PingStatistics {
        int totalAttempts = 0;
        int successes = 0;
        int failures = 0;
        double totalPingMs = 0;
        double bestPingMs = Double.MAX_VALUE;
        double averagePingMs = 0;
        double receivedPercent = 0;
    }

    //=======================================================================
    // Private variables
    //=======================================================================
    private PingStatistics stats;
    private String destination;
    private boolean isRunning = false;
    private boolean forceStop = false;
    private final int maxPings = 255;

    private Handler attemptHandler = new Handler();
    private Runnable attemptRunnable = new Runnable() {
        @Override
        public void run() {
            // Run a single attempt.
            PingAttemptTask attempt = new PingAttemptTask();
            attempt.execute();
        }
    };

    private void startNextAttemptRequest(Long waitMs) {
        if (stats.totalAttempts > maxPings || forceStop) {
            // Done!
            isRunning = false;
        } else {
            // Else post the request to make a Ping attempt.
            attemptHandler.postDelayed(attemptRunnable, waitMs);
        }
    }

    //=======================================================================
    // Singleton
    //=======================================================================
    private static final PingUtil instance = new PingUtil();
    private PingUtil() { }
    public static PingUtil getInstance() { return instance; }

    //=======================================================================
    // Privates
    //=======================================================================
    private Listener callbackListener;

    //=======================================================================
    // Public
    //=======================================================================
    public void setListener(Listener listener) {
        callbackListener = listener;
    }

    public void removeListener() { callbackListener = null; }

    public boolean isRunning() {
        return isRunning;
    }

    public String getPingDescription(ProbeWrapper pingResult) {
        if (pingResult.success) {
            StringBuilder sb = new StringBuilder();
            sb.append(String.format(App.getAppContext().getString(R.string.reply_from_x), pingResult.fromAddress));
            sb.append(String.format(": %fms", pingResult.elapsedMs));
            return sb.toString();
        }

        return App.getAppContext().getString(R.string.request_timed_out);
    }

    public void startPing(final String to) {
        if (isRunning) {
            if (callbackListener != null) callbackListener.onPingAlreadyRunning();
        } else {
            isRunning = true;
            destination = to;
            stats = new PingStatistics();
            startNextAttemptRequest(0L); // No wait before first request.
        }
    }

    public void stopPing() {
        forceStop = true;
    }

    //=======================================================================
    // AsyncTask that runs a single Ping attempt (background) and updates the
    // statistics object (main UI) and calls startNextAttemptRequest when complete.
    //
    // Having a single task per attempt allows us to add a small delay between each
    // attempt to create a nicer UI experience.
    //=======================================================================
    private class PingAttemptTask extends AsyncTask<Void, Void, ProbeWrapper> {
        @Override
        protected ProbeWrapper doInBackground(Void... params) {
            return MapControllerWrapper.getInstance().ping(destination);
        }

        @Override
        protected void onPostExecute(ProbeWrapper probeWrapper) {
            super.onPostExecute(probeWrapper);

            // Generate stats
            if (stats == null) {
                stats = new PingStatistics();
            }

            stats.totalAttempts += 1;
            if (probeWrapper.success) {
                stats.successes += 1;
                if (callbackListener != null) callbackListener.onPingResult(stats.totalAttempts, probeWrapper);
            } else {
                stats.failures += 1;
                if (callbackListener != null) callbackListener.onPingTimeout(stats.totalAttempts);
            }

            double pingMs = probeWrapper.elapsedMs;

            // Calculate ping run properties
            if (stats.bestPingMs > pingMs) {
                stats.bestPingMs = pingMs;
                if (callbackListener != null) callbackListener.onBestUpdated(stats.bestPingMs);
            }

            stats.totalPingMs = stats.totalPingMs + pingMs;
            stats.averagePingMs = stats.totalPingMs / stats.totalAttempts;
            if (callbackListener != null) callbackListener.onAverageUpdated(stats.averagePingMs);

            stats.receivedPercent = stats.successes / stats.totalAttempts;
            if (callbackListener != null) callbackListener.onReceivedUpdated(stats.receivedPercent);

            startNextAttemptRequest(1000L);
        }

    }
}
