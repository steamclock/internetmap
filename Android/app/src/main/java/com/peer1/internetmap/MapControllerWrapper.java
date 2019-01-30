package com.peer1.internetmap;

/**
 * Methods implemented in JNI (see jniapi.cpp)
 */
public class MapControllerWrapper {
    //-------------------------------------------------
    // Singleton
    //-------------------------------------------------
    private static final MapControllerWrapper instance = new MapControllerWrapper();
    private MapControllerWrapper() { }
    public static MapControllerWrapper getInstance() { return instance; }

    //-------------------------------------------------
    // JNI interface
    //-------------------------------------------------
    public native void rotateRadiansXY(float radX, float radY);
    public native void translateYAnimated(float translateY, float seconds);
    public native void startMomentumPanWithVelocity(float vX, float vY);
    public native void handleTouchDownAtPoint(float x, float y);
    public native void zoomByScale(float scale);
    public native void startMomentumZoomWithVelocity(float velocity);
    public native void rotateRadiansZ(float radians);
    public native void startMomentumRotationWithVelocity(float velocity);
    public native boolean selectHoveredNode();
    public native NodeWrapper nodeAtIndex(int index);
    public native int targetNodeIndex();
    public native NodeWrapper nodeByAsn(String asn);
    public native void updateTargetForIndex(int index);
    public native NodeWrapper[] allNodes();
    public native void setTimelinePoint(String year);
    public native String[] visualizationNames();
    public native void setVisualization(int index);
    public native void deselectCurrentNode();
    public native void resetZoomAndRotationAnimated(boolean isPortraitMode);
    public native void setAllowIdleAnimation(boolean allow);
    public native void unhoverNode();
    public native String lastSearchIP();
    public native void setLastSearchIP(String ipAddr);
    public native void sendPacket();
    public native ProbeWrapper probeDestinationAddressWithTTL(String destAddr, int ttl);
    public native ProbeWrapper ping(String destAddr);
    public native void highlightRoute(NodeWrapper[] nodes, int length);
    public native void clearHighlightLines();
}
