package com.peer1.internetmap.utils;

import android.util.Log;

import com.peer1.internetmap.MapControllerWrapper;
import com.peer1.internetmap.ProbeWrapper;

import java.util.ArrayList;

/**
 * Created by shayla on 2017-09-20.
 */

public class TracerouteUtil {

    private MapControllerWrapper mapControllerWrapper;
    private ArrayList<String> result;
    private String traceDestination;

    public TracerouteUtil(MapControllerWrapper mapControllerWrapper) {
        this.mapControllerWrapper = mapControllerWrapper;
    }

    public void startTrace() {
        int maxHops = 255;
        traceDestination = "172.217.3.164";

        for (int ttl = 1; ttl < maxHops; ttl++) {

            ProbeWrapper probeWrapper = mapControllerWrapper.probeDestinationAddressWithTTL(traceDestination, ttl);

            if (probeWrapper.fromAddress != null) {
                Log.v("Trace HUZZAH", "WOOP " + probeWrapper.fromAddress);
                if (probeWrapper.fromAddress.equals(traceDestination)) {
                    // SHTAP
                    break;
                }
            }
        }
    }

}
