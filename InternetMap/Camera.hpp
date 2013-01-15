//
//  Camera.hpp
//  InternetMap
//

#ifndef InternetMap_Camera_hpp
#define InternetMap_Camera_hpp

#include "Types.hpp"

class Camera {
    float _displayWidth, _displayHeight;
    Vector3 _target;
    bool _isMovingToTarget;
    bool _allowIdleAnimation;
    
    Matrix4 _modelViewProjectionMatrix;
    Matrix4 _modelViewMatrix;
    Matrix4 _projectionMatrix;
    
    Matrix4 _rotationMatrix;
    float _rotation;
    float _zoom;
    
    TimeInterval _targetMoveStartTime;
    Vector3 _targetMoveStartPosition;
    
    float _zoomStart;
    float _zoomTarget;
    TimeInterval _zoomStartTime;
    TimeInterval _zoomDuration;
    
    TimeInterval _updateTime;
    TimeInterval _idleStartTime; // For "attract" mode
    
    Vector2 _panVelocity;
    TimeInterval _panEndTime;
    
    float _zoomVelocity;
    TimeInterval _zoomEndTime;
    
    float _rotationVelocity;
    TimeInterval _rotationEndTime;
    
    Quaternion _rotationStart;
    Quaternion _rotationTarget;
    TimeInterval _rotationStartTime;
    TimeInterval _rotationDuration;
    
    void handleIdleMovement(TimeInterval delta);
    void handleMomentumPan(TimeInterval delta);
    void handleMomentumZoom(TimeInterval delta);
    void handleMomentumRotation(TimeInterval delta);
    Vector3 calculateMoveTarget(TimeInterval delta);
    void handleAnimatedZoom(TimeInterval delta);
    void handleAnimatedRotation(TimeInterval delta);
    
public:
    Camera();
    
    void setTarget(const Vector3& target, float zoom);
    Vector3 target(void) { return _target; }
    void setDisplaySize(float width, float height) { _displayWidth = width; _displayHeight = height; }
    float displayWidth() { return _displayWidth; }
    float displayHeight() { return _displayHeight; }
    bool isMovingToTarget(void) { return _isMovingToTarget; }
    void setAllowIdleAnimation(bool b) { _allowIdleAnimation = b; }

    void rotateRadiansX(float rotate);
    void rotateRadiansY(float rotate);
    void rotateRadiansZ(float rotate);
    void rotateAnimated(Matrix4 rotation, TimeInterval duration);
    void zoomAnimated(float zoom, TimeInterval duration);
    void zoomByScale(float zoom);
    void resetIdleTimer(void);
    
    void update(TimeInterval currentTime);

    Matrix4 currentModelViewProjection(void);
    Matrix4 currentModelView(void);
    Matrix4 currentProjection(void);
    float currentZoom(void);

    Vector3 applyModelViewToPoint(Vector2 point);
    Vector3 cameraInObjectSpace(void);

    void startMomentumPanWithVelocity(Vector2 velocity);
    void stopMomentumPan();
    
    void startMomentumZoomWithVelocity(float velocity);
    void stopMomentumZoom();
    
    void startMomentumRotationWithVelocity(float velocity);
    void stopMomentumRotation();
};

#endif
