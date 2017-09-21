package com.peer1.internetmap.models;

import com.google.gson.annotations.SerializedName;

/**
 * Created by shayla on 2017-05-10.
 */
public class ASNIPs {
    @SerializedName("resultsPayload")
    public String ips;

    public String getIp() {
        if (ips == null) {
            return null;
        }

        int slashIndex = ips.indexOf("/");
        return ips.substring(0 , slashIndex);
    }
}
