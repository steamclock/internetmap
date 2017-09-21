package com.peer1.internetmap.models;

import com.google.gson.annotations.SerializedName;

/**
 * Created by shayla on 2017-05-10.
 */
public class ASN {
    @SerializedName("resultsPayload")
    public Integer asn;

    public String getASNString() {
        return String.valueOf(asn);
    }
}
