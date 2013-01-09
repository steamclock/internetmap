//
//  Camera.hpp
//  InternetMap
//

#include "Types.hpp"
#include "GLKit/GLKMath.h"

class Camera {
    float _displayWidth, _displayHeight;
    GLKVector3 _target;
    bool _isMovingToTarget;
    bool _allowIdleAnimation;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    GLKMatrix4 _projectionMatrix;
    
    GLKMatrix4 _rotationMatrix;
    float _rotation;
    float _zoom;
    
    TimeInterval _targetMoveStartTime;
    GLKVector3 _targetMoveStartPosition;
    
    float _zoomStart;
    float _zoomTarget;
    TimeInterval _zoomStartTime;
    TimeInterval _zoomDuration;
    
    TimeInterval _updateTime;
    TimeInterval _idleStartTime; // For "attract" mode
    
    GLKVector2 _panVelocity;
    TimeInterval _panEndTime;
    
    float _zoomVelocity;
    TimeInterval _zoomEndTime;
    
    float _rotationVelocity;
    TimeInterval _rotationEndTime;
    
    GLKQuaternion _rotationStart;
    GLKQuaternion _rotationTarget;
    TimeInterval _rotationStartTime;
    TimeInterval _rotationDuration;
    
    void handleIdleMovement(TimeInterval delta);
    void handleMomentumPan(TimeInterval delta);
    void handleMomentumZoom(TimeInterval delta);
    void handleMomentumRotation(TimeInterval delta);
    GLKVector3 calculateMoveTarget(TimeInterval delta);
    void handleAnimatedZoom(TimeInterval delta);
    void handleAnimatedRotation(TimeInterval delta);
    
public:
    Camera();
    
    void setTarget(const GLKVector3& target);
    GLKVector3 target(void) { return _target; }
    void setDisplaySize(float width, float height) { _displayWidth = width; _displayHeight = height; }
    float displayWidth() { return _displayWidth; }
    float displayHeight() { return _displayHeight; }
    bool isMovingToTarget(void) { return _isMovingToTarget; }
    void setAllowIdleAnimation(bool b) { _allowIdleAnimation = b; }

    void rotateRadiansX(float rotate);
    void rotateRadiansY(float rotate);
    void rotateRadiansZ(float rotate);
    void rotateAnimated(GLKMatrix4 rotation, TimeInterval duration);
    void zoomAnimated(float zoom, TimeInterval duration);
    void zoomByScale(float zoom);
    void resetIdleTimer(void);
    
    void update(TimeInterval currentTime);

    GLKMatrix4 currentModelViewProjection(void);
    GLKMatrix4 currentModelView(void);
    GLKMatrix4 currentProjection(void);
    float currentZoom(void);

    GLKVector3 applyModelViewToPoint(GLKVector2 point);
    GLKVector3 cameraInObjectSpace(void);

    void startMomentumPanWithVelocity(GLKVector2 velocity);
    void stopMomentumPan();
    
    void startMomentumZoomWithVelocity(float velocity);
    void stopMomentumZoom();
    
    void startMomentumRotationWithVelocity(float velocity);
    void stopMomentumRotation();
};
