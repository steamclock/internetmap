package com.peer1.internetmap;

/**
 * A readonly wrapper for node display information
 * @author chani
 *
 */
public class NodeWrapper {
    public final String asn;
    public final String textDescription;
    public final String typeString;
    public final int index;
    public final float importance;
    public final int numberOfConnections;
    
    NodeWrapper(int index, float importance, int numberOfConnections, String asn, String textDescription, String typeString) {
        this.index = index;
        this.importance = importance;
        this.numberOfConnections = numberOfConnections;
        this.asn = asn;
        this.textDescription = textDescription;
        this.typeString = typeString;
    }
}
