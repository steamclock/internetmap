package com.peer1.internetmap.utils;

import android.os.AsyncTask;
import android.util.Log;

import com.peer1.internetmap.MapControllerWrapper;
import com.peer1.internetmap.ProbeWrapper;

import java.util.ArrayList;

/**
 * Created by shayla on 2017-09-20.
 */

public class TracerouteUtil {

    public interface Listener {
        void onHopFound(int ttl, String ip);
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
            public void onHopFound(int ttl, String ip) {

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

        AsyncTask<Void, Void, Void> tracerouteTask = new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... params) {

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
                        Log.v("Trace HUZZAH", String.format("WOOP %d: %s", ttl, probeWrapper.fromAddress));
                        consecutiveTimeouts = 0;
                        listener.onHopFound(ttl, probeWrapper.fromAddress);

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

}
