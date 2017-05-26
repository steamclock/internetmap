package com.peer1.internetmap.models;

import com.google.gson.annotations.SerializedName;

import java.util.ArrayList;

/**
 * Created by shayla on 2017-05-15.
 */
public class MxASNInfo {

    public class Information {
        @SerializedName("As Number")
        public String asn;

        @SerializedName("As Name")
        public String name;

        @SerializedName("CIDR Range")
        public String CIDRRange;
    }

    @SerializedName("Information")
    public ArrayList<Information> information;
}
