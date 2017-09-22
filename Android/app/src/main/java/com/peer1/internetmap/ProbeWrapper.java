package com.peer1.internetmap;

/**
 * Created by shayla on 2017-09-20.
 */

public class ProbeWrapper {
    public final boolean success;
    public final String fromAddress;
    public final double elapsedMs;

    /** This constructor should ONLY be called by wrapNode() in jniapi.cpp!
     * it's really ugly and easy to mess up, but it was the least ugly option for c++/java bindings :(
     * if you change this code, triple-check that the argument order matches wrapNode.
     */
    ProbeWrapper(boolean success, String fromAddress, double elapsedMs) {
        this.success = success;
        this.fromAddress = fromAddress;
        this.elapsedMs = elapsedMs;
    }
}
