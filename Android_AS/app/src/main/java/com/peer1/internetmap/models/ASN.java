package com.peer1.internetmap.models;

import com.google.gson.annotations.SerializedName;

/**
 * Created by shayla on 2017-05-10.
 */
public class ASN {
    @SerializedName("as_number")
    public Integer asn;

    @SerializedName("as_country_code")
    public String countryCode;

    @SerializedName("as_description")
    public String description;

    @SerializedName("first_ip")
    public String firstIP;

    @SerializedName("last_ip")
    public String lastIP;

    public String getASNString() {
        return String.valueOf(asn);
    }
}
