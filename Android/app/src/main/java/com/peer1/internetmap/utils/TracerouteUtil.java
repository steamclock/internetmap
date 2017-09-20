package com.peer1.internetmap.utils;

import android.util.Log;

import com.peer1.internetmap.MapControllerWrapper;

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
            String resultStr = null;
            int error = mapControllerWrapper.probeDestinationAddressWithTTL(traceDestination, ttl, resultStr);

            if (resultStr != null) {
                result.add(resultStr);
                Log.v("Trace", resultStr);

                if (resultStr.equals(traceDestination)) {
                    // SHTAP
                    break;
                }
            }
        }

    }

}
