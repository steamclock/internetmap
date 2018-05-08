package com.peer1.internetmap.utils;

import android.os.AsyncTask;
import android.os.Trace;
import android.util.Log;

import com.peer1.internetmap.MapControllerWrapper;
import com.peer1.internetmap.ProbeWrapper;

import java.util.ArrayList;
import java.util.Date;

/**
 * Created by shayla on 2017-09-20.
 */

public class TracerouteUtil {

    public interface Listener {
        void onHopFound(int ttl, ProbeWrapper hop);
        void onHopTimeout(int ttl);
        void onComplete();
        void onTraceTimeout();
    }

    private MapControllerWrapper mapControllerWrapper;
    private ArrayList<String> result;
    private String traceDestination;
    private Listener listener;
    private boolean stopTrace = false;
    private final int maxconsecutiveTimeouts = 3;
    private int consecutiveTimeouts = 0;


    public TracerouteUtil(MapControllerWrapper mapControllerWrapper) {
        this.mapControllerWrapper = mapControllerWrapper;
        this.listener = new Listener() {
            @Override
            public void onHopFound(int ttl, ProbeWrapper ip) {

            }

            @Override
            public void onHopTimeout(int ttl) {

            }

            @Override
            public void onComplete() {

            }

            @Override
            public void onTraceTimeout() {

            }
        };
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public void startTrace(final String to) {
        traceDestination = to; //"172.217.3.164";

        // todo fix async task leak
        //https://stackoverflow.com/questions/44309241/warning-this-asynctask-class-should-be-static-or-leaks-might-occur
        AsyncTask<Void, Void, Void> tracerouteTask = new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {

                Log.v("Trace", String.format("Trace to " + traceDestination));

                int maxHops = 255;
                consecutiveTimeouts = 0;
                for (int ttl = 1; ttl < maxHops; ttl++) {

                    if (stopTrace) {
                        break;
                    }

                    ProbeWrapper probeWrapper = mapControllerWrapper.probeDestinationAddressWithTTL(traceDestination, ttl);

                    if (probeWrapper.fromAddress == null || probeWrapper.fromAddress.isEmpty()) {
                        consecutiveTimeouts++;
                        listener.onHopTimeout(ttl);

                        if (consecutiveTimeouts >= maxconsecutiveTimeouts) {
                            listener.onTraceTimeout();
                            break;
                        }
                    } else {
                        Log.v("Trace", String.format("HOP %d: %s", ttl, probeWrapper.fromAddress));
                        consecutiveTimeouts = 0;
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

                return null;
            }

        };

        tracerouteTask.execute();
    }

    public void stopTrace() {
        stopTrace = true;
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
