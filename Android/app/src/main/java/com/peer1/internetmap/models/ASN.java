package com.peer1.internetmap.models;

import com.google.gson.annotations.SerializedName;

/**
 * Created by shayla on 2017-05-10.
 */
public class ASN {

    private final String none = "none";

    @SerializedName("resultsPayload")
    public String asn;

    /**
     * Note API returns "none" in cases where no asn can be found.
     * @return null if no asn found, else the asn found
     */
    public String getASNString() {
        if (asn.isEmpty() || asn.equals(none)) {
            return null;
        }

        return asn;
    }
}
