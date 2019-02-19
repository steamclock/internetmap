package com.peer1.internetmap.utils;

import android.os.AsyncTask;

import com.peer1.internetmap.MapControllerWrapper;
import com.peer1.internetmap.ProbeWrapper;

import java.util.HashSet;

/**
 * Created by shayla on 2017-09-20.
 *
 * Simulates a traceroute by requesting probes be sent to a given destination IP with incrementing
 * time-to-live values. Reports back via the Listener interface.
 */

public class TracerouteUtil {

    //=======================================================================
    // Callback interface; must be set by caller to receive traceroute updates
    //=======================================================================
    public interface Listener {
        /**
         * Successful probe of a given time-to-live hop
         */
        void onHopFound(int ttl, ProbeWrapper hop);

        /**
         * Unsuccessful probe of a given time-to-live hop
         */
        void onHopTimeout(int ttl);

        /**
         * Traceroute completed successfully
         */
        void onComplete();

        /**
         * Traceroute exited early due to a loop being found in the trace (ie. duplicate IPs)
         */
        void onLoopDiscovered();

        /**
         * Traceroute timed out (usually due to consecutive hop timeouts)
         */
        void onTraceTimeout();

        /**
         * Traceroute already running; may want to make this a more general error instead.
         */
        void onTraceAlreadyRunning();

    }

    //=======================================================================
    // Singleton
    //=======================================================================
    private static final TracerouteUtil instance = new TracerouteUtil();
    private TracerouteUtil() {
        tracerouteTask = null;
        callbackListener = emptyListener;
    }
    public static TracerouteUtil getInstance() { return instance; }

    //=======================================================================
    // Privates
    //=======================================================================
    private Listener callbackListener;
    private TracerouteTask tracerouteTask;
    private Listener emptyListener = new Listener() {
        @Override
        public void onHopFound(int ttl, ProbeWrapper ip) { }

        @Override
        public void onHopTimeout(int ttl) { }

        @Override
        public void onComplete() { }

        @Override
        public void onTraceTimeout() { }

        @Override
        public void onLoopDiscovered() { }

        @Override
        public void onTraceAlreadyRunning() { }
    };

    //=======================================================================
    // Public methods
    //=======================================================================
    public void setListener(Listener listener) {
        callbackListener = listener;
    }
    public void removeListener() { callbackListener = emptyListener; }

    public void startTrace(final String to) {
        if (tracerouteTask != null && tracerouteTask.isRunning) {
            callbackListener.onTraceAlreadyRunning();
        } else {
            // Cannot use instance of AsyncTask multiple times; create a new one with each trace.
            tracerouteTask = new TracerouteTask();
            tracerouteTask.listener = callbackListener;
            tracerouteTask.traceDestination = to; //"172.217.3.164";
            tracerouteTask.execute();
        }
    }

    public void stopTrace() {
        if (tracerouteTask != null) {
            tracerouteTask.stopTrace = true;
        }
    }

    public boolean isRunning() {
        return tracerouteTask != null && tracerouteTask.isRunning;
    }

    //=======================================================================
    // TracerouteTask, allows us to run traceroute in a background async task
    //=======================================================================
    static private class TracerouteTask extends AsyncTask<Void, Void, Void> {
        String traceDestination;
        Listener listener;
        Boolean isRunning = false;

        private boolean stopTrace = false;

        private final int maxHops = 255;
        private final int maxConsecutiveTimeouts = 3;
        private int consecutiveTimeouts = 0;
        private HashSet<String> hopIPs = new HashSet<>();
        private ProbeWrapper probeWrapper;

        @Override
        protected Void doInBackground(Void... params) {
            hopIPs.clear();
            consecutiveTimeouts = 0;
            isRunning = true;

            for (int ttl = 1; ttl < maxHops; ttl++) {
                // Given ICMP protocol limitations in Java, we rely on C++ code give us probed trace information.
                probeWrapper = MapControllerWrapper.getInstance().probeDestinationAddressWithTTL(traceDestination, ttl);

                if (stopTrace) {
                    break;
                }

                if (probeWrapper == null) {
                    listener.onHopTimeout(ttl);
                }
                else if (probeWrapper.fromAddress == null || probeWrapper.fromAddress.isEmpty()) {
                    consecutiveTimeouts++;
                    listener.onHopTimeout(ttl);

                    if (consecutiveTimeouts >= maxConsecutiveTimeouts) {
                        listener.onTraceTimeout();
                        break;
                    }
                } else {
                    consecutiveTimeouts = 0;

                    if (hopIPs.contains(probeWrapper.fromAddress)) {
                        // About to hit a loop. Need to break.
                        listener.onLoopDiscovered();
                        break;
                    } else {
                        // Hop is a-ok, carry on!
                        hopIPs.add(probeWrapper.fromAddress);
                        listener.onHopFound(ttl, probeWrapper);

                        // TODO When tracing to an ASN node, there is a good chance we will not actually
                        // be able to trace to the exact IP. Should we change our "stopping" case from
                        // being the destination IP to the hitting the destination ASN?
                        // If Yes, then I need to move the code to determine the ASN for each hop into TracerouteUtil.
                        if (probeWrapper.fromAddress.equals(traceDestination)) {
                            listener.onComplete();
                            break;
                        }
                    }
                }
            }

            isRunning = false;
            return null;
        }
    }

    static public boolean isInvalidOrPrivate(String ipAddress) {
        // This checks if our IP is in a reserved address space (eg. 192.168.1.1)
        String[] components = ipAddress.split("\\.");

        if (components.length != 4) {
            return true;
        }

        try {
            int a = Integer.valueOf(components[0]);
            int b = Integer.valueOf(components[1]);

            if (a == 10) {
                return true;
            }

            if ((a == 172) && ((b >= 16) && (b <= 31))) {
                return true;
            }

            if ((a == 192) && (b == 168)) {
                return true;
            }

            // Probably loopback, we should ignore
            if (ipAddress.equals("127.255.255.255")) {
                return true;
            }

        } catch (Exception e) {
            // Failed to parse, don't assume anything, return false
        }

        return false;
    }
}
