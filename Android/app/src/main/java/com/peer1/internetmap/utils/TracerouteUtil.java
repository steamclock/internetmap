package com.peer1.internetmap.utils;

import android.os.AsyncTask;
import android.util.Log;

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
    }

    //=======================================================================
    // Privates
    //=======================================================================
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
    };

    //=======================================================================
    // Constructors
    //=======================================================================
    public TracerouteUtil(MapControllerWrapper mapControllerWrapper) {
        this.tracerouteTask = new TracerouteTask();
        this.tracerouteTask.mapControllerWrapper = mapControllerWrapper;
        this.tracerouteTask.listener = emptyListener;
    }

    //=======================================================================
    // Public methods
    //=======================================================================
    public void setListener(Listener listener) {
        this.tracerouteTask.listener = listener;
    }

    public void startTrace(final String to) {
        this.tracerouteTask.traceDestination = to; //"172.217.3.164";
        tracerouteTask.execute();
    }

    public void stopTrace() {
        this.tracerouteTask.stopTrace = true;
    }

    //=======================================================================
    // TracerouteTask, allows us to run traceroute in a background async task
    //=======================================================================
    static private class TracerouteTask extends AsyncTask<Void, Void, Void> {
        String traceDestination;
        Listener listener;
        MapControllerWrapper mapControllerWrapper;

        private boolean stopTrace = false;

        private final int maxHops = 255;
        private final int maxConsecutiveTimeouts = 3;
        private int consecutiveTimeouts = 0;
        private HashSet<String> hopIPs = new HashSet<>();
        private ProbeWrapper probeWrapper;

        @Override
        protected Void doInBackground(Void... params) {
            Log.v("Trace", String.format("Trace to " + traceDestination));
            hopIPs.clear();
            consecutiveTimeouts = 0;

            for (int ttl = 1; ttl < maxHops; ttl++) {
                if (stopTrace) {
                    break;
                }

                // Given ICMP protocol limitations in Java, we rely on C++ code give us probed trace information.
                probeWrapper = mapControllerWrapper.probeDestinationAddressWithTTL(traceDestination, ttl);

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
                    Log.v("Trace", String.format("HOP %d: %s", ttl, probeWrapper.fromAddress));
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
            return null;
        }
    }


//    +(BOOL)isInvalidOrPrivate:(NSString*)ipAddress {
//        // This checks if our IP is in a reserved address space (eg. 192.168.1.1)
//        NSArray* components = [ipAddress componentsSeparatedByString:@"."];
//
//        if(components.count != 4) {
//            return TRUE;
//        }
//
//        int a = [components[0] intValue];
//        int b = [components[1] intValue];
//
//        if (a == 10) {
//            return TRUE;
//        }
//
//        if((a == 172) && ((b >= 16) && (b <= 31))) {
//            return TRUE;
//        }
//
//        if((a == 192) && (b == 168)) {
//            return TRUE;
//        }
//
//        // Probably loopback, we should ignore
//        if ([ipAddress isEqualToString:@"127.255.255.255"]) {
//            return TRUE;
//        }
//
//        return FALSE;
//    }

}
