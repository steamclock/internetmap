package com.peer1.internetmap;

public class MapControllerWrapper {
    public native void nativeRotateRadiansXY(float radX, float radY);
    public native void nativeStartMomentumPanWithVelocity(float vX, float vY);
    public native void nativeHandleTouchDownAtPoint(float x, float y);
    public native void nativeZoomByScale(float scale);
    public native void nativeStartMomentumZoomWithVelocity(float velocity);
    public native void nativeRotateRadiansZ(float radians);
    public native void nativeStartMomentumRotationWithVelocity(float velocity);
    public native boolean nativeSelectHoveredNode();
    public native NodeWrapper nativeNodeAtIndex(int index);
    public native int nativeTargetNodeIndex();
    public native NodeWrapper nativeNodeByAsn(String asn);
}
