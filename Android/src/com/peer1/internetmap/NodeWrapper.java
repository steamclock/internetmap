package com.peer1.internetmap;

/**
 * A readonly wrapper for node display information
 * @author chani
 *
 */
public class NodeWrapper {
    public final String asn;
    public final String friendlyDescription;
    public final String typeString;
    public final int index;
    public final float importance;
    public final int numberOfConnections;
    
    /** This constructor should ONLY be called by wrapNode() in jniapi.cpp!
     * it's really ugly and easy to mess up, but it was the least ugly option for c++/java bindings :(
     */
    NodeWrapper(int index, float importance, int numberOfConnections, String asn, String friendlyDescription, String typeString) {
        this.index = index;
        this.importance = importance;
        this.numberOfConnections = numberOfConnections;
        this.asn = asn;
        this.friendlyDescription = friendlyDescription;
        this.typeString = typeString;
    }
}
