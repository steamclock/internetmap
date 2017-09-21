package com.peer1.internetmap.utils;

import android.util.Log;

import com.peer1.internetmap.MapControllerWrapper;
import com.peer1.internetmap.NodeWrapper;
import com.peer1.internetmap.ProbeWrapper;

import java.util.ArrayList;

/**
 * Created by shayla on 2017-09-20.
 */

public class TracerouteUtil {

    public interface Listener {
        void onHopFound(int ttl, String ip);
        void onTimeout(int ttl);
    }

    private MapControllerWrapper mapControllerWrapper;
    private ArrayList<String> result;
    private String traceDestination;
    private Listener listener;

    public TracerouteUtil(MapControllerWrapper mapControllerWrapper) {
        this.mapControllerWrapper = mapControllerWrapper;
        this.listener = new Listener() {
            @Override
            public void onHopFound(int ttl, String ip) {

            }

            @Override
            public void onTimeout(int ttl) {

            }
        };
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public void startTrace() {
        int maxHops = 255;
        traceDestination = "172.217.3.164";

        for (int ttl = 1; ttl < maxHops; ttl++) {

            ProbeWrapper probeWrapper = mapControllerWrapper.probeDestinationAddressWithTTL(traceDestination, ttl);

            if (probeWrapper.fromAddress != null) {
                Log.v("Trace HUZZAH", "WOOP " + probeWrapper.fromAddress);
                listener.onHopFound(ttl, probeWrapper.fromAddress);
            } else {
                listener.onTimeout(ttl);
            }
        }
    }
}
