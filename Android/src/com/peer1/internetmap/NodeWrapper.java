package com.peer1.internetmap;

/**
 * A readonly wrapper for node display information
 * @author chani
 *
 */
public class NodeWrapper {
    public final String asn;
    public final String rawTextDescription;
    public final String typeString;
    public final int index;
    public final float importance;
    public final int numberOfConnections;
    
    /** This constructor should ONLY be called by wrapNode() in jniapi.cpp!
     * it's really ugly and easy to mess up, but it was the least ugly option for c++/java bindings :(
     * if you change this code, triple-check that the argument order matches wrapNode.
     */
    NodeWrapper(int index, float importance, int numberOfConnections, String asn, String rawTextDescription, String typeString) {
        this.index = index;
        this.importance = importance;
        this.numberOfConnections = numberOfConnections;
        this.asn = asn;
        this.rawTextDescription = rawTextDescription;
        this.typeString = typeString;
    }
    
    public String friendlyDescription() {
        //for performance reasons we only load this on demand
        return nativeFriendlyDescription(index);
    }
    
    private native String nativeFriendlyDescription(int index);
}
