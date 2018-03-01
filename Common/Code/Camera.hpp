//
//  Camera.hpp
//  InternetMap
//

#ifndef InternetMap_Camera_hpp
#define InternetMap_Camera_hpp

#include "Types.hpp"

#define DEFAULT_MOVE_TIME 1.0f

/**
 a target contains all the data needed for the camera to sensibly focus on a node.
 */
struct Target {
    Vector3 vector; //where to aim the camera
    float zoom; //default zoom level
    float maxZoom; //max. user zoom level
    Target():vector(0, 0, 0), zoom(0.0f), maxZoom(0.0f) {}
};

const float NEAR_PLANE = 0.05f;
const float FAR_PLANE = 100.0f;

/**
 the opengl camera for the view.
 has nice functions for targeting, animated zoom, rotation, etc.
 */
class Camera {
    
    int _mode;
    
    float _displayWidth, _displayHeight;
    //TODO maybe target should be a Target?
    Vector3 _target;
    bool _isMovingToTarget;
    bool _allowIdleAnimation;
    
    Matrix4 _modelViewProjectionMatrix;
    Matrix4 _modelViewMatrix;
    Matrix4 _projectionMatrix;
    
    Matrix4 _viewMatrix;
    Matrix4 _rotationMatrix;
    
    float _rotation;
    float _zoom;
    float _maxZoom; //based on target node, because big nodes look ugly close up.

    Vector3 _modelPos;
    
    TimeInterval _targetMoveStartTime;
    Vector3 _targetMoveStartPosition;
    TimeInterval _moveDuration;
    
    float _zoomStart;
    float _zoomTarget;
    TimeInterval _zoomStartTime;
    TimeInterval _zoomDuration;
    
    float _translationY;
    float _translationYStart;
    float _translationYTarget;
    TimeInterval _translationYStartTime;
    TimeInterval _translationYDuration;
    
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

    bool overrideCamera = false;
    
    void handleAnimatedTranslateY(TimeInterval delta);
    void handleIdleMovement(TimeInterval delta);
    void handleMomentumPan(TimeInterval delta);
    void handleMomentumZoom(TimeInterval delta);
    void handleMomentumRotation(TimeInterval delta);
    Vector3 calculateMoveTarget(TimeInterval delta);
    void handleAnimatedZoom(TimeInterval delta);
    void handleAnimatedRotation(TimeInterval delta);
    void setRotationAndRenormalize(const Matrix4& matrix);

    bool checkIfAnglePastLimit();

public:
    Camera();
    
    static const int MODE_UNKNOWN = 0;
    static const int MODE_GLOBE = 1;
    static const int MODE_NETWORK = 2;
    
    void setMode(int mode);
    void setTarget(const Target& target, TimeInterval duration = DEFAULT_MOVE_TIME);
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
    void translateYAnimated(float translateY, TimeInterval duration);
    void resetIdleTimer(void);

    void setOverride(Matrix4* transform, Matrix4* projection, Vector3 modelPos);

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
    
    void resetZoomAndRotationAnimated(bool isPortraitMode);
    
    
    void print_matrix4(const Matrix4 &mat4);
};

#endif
