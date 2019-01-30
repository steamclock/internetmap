package com.peer1.internetmap.utils;

import android.os.AsyncTask;

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
    // Singleton
    //=======================================================================
    private static final PingUtil instance = new PingUtil();
    private PingUtil() {
        pingTask = null;
    }
    public static PingUtil getInstance() { return instance; }

    //=======================================================================
    // Privates
    //=======================================================================
    private Listener callbackListener;
    private PingTask pingTask;

    //=======================================================================
    // Public
    //=======================================================================
    public void setListener(Listener listener) {
        callbackListener = listener;
    }

    public void removeListener() { callbackListener = null; }

    public void startPing(final String to) {
        if (pingTask != null && pingTask.isRunning) {
            if (callbackListener != null) callbackListener.onPingAlreadyRunning();
        } else {
            // Cannot use instance of AsyncTask multiple times; create a new one with each ping.
            pingTask = new PingTask();
            pingTask.listener = callbackListener;
            pingTask.pingDestination = to; //"172.217.3.164";
            pingTask.execute();
        }
    }

    public void stopPing() {
        if (pingTask != null) {
            pingTask.stopPing = true;
        }
    }

    public boolean isRunning() {
        return pingTask != null && pingTask.isRunning;
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

    //=======================================================================
    // PingTask, allows us to run a ping as a background async task
    //=======================================================================
    static private class PingTask extends AsyncTask<Void, Void, Void> {
        String pingDestination;
        Listener listener;
        Boolean isRunning = false;

        private ArrayList<ProbeWrapper> cachedPings;
        private boolean stopPing = false;
        private final int maxPings = 255;

        private ProbeWrapper probeWrapper;

        @Override
        protected Void doInBackground(Void... params) {
            cachedPings = new ArrayList<>();
            isRunning = true;

            // Run statistics
            int successfulPings = 0;
            int failedPings = 0;
            double totalPingMs = 0;

            double bestPingMs = Double.MAX_VALUE;
            double averagePingMs = 0;
            double receivedPercent = 0;

            for (int pingNumber = 1; pingNumber <= maxPings; pingNumber++) {
                probeWrapper = MapControllerWrapper.getInstance().ping(pingDestination);

                if (stopPing) {
                    break;
                }

                if (probeWrapper.success) {
                    successfulPings = successfulPings + 1;
                    if (listener != null) listener.onPingResult(pingNumber, probeWrapper);
                } else {
                    failedPings = failedPings + 1;
                    if (listener != null) listener.onPingTimeout(pingNumber);
                }

                double pingMs = probeWrapper.elapsedMs;

                // Calculate ping run properties
                if (bestPingMs > pingMs) {
                    bestPingMs = pingMs;
                    if (listener != null) listener.onBestUpdated(bestPingMs);
                }

                totalPingMs = totalPingMs + pingMs;
                averagePingMs = totalPingMs / pingNumber;
                if (listener != null) listener.onAverageUpdated(averagePingMs);

                receivedPercent = successfulPings / pingNumber;
                if (listener != null) listener.onReceivedUpdated(receivedPercent);
            }

            isRunning = false;
            return null;
        }
    }
}
