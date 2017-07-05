
//  Camera.cpp
//  InternetMap
//

#include "Camera.hpp"
#include "GlobeVisualization.hpp"
#include <stdlib.h>

static const float MIN_ZOOM = -10.0f;
//we need a bound on the max. zoom because on small nodes the calculated max puts the target behind the camera.
//this might be a bug in targeting...?
static const float MAX_MAX_ZOOM = -2.0f; // -0.06f;

// TODO: better way to register this
void cameraMoveFinishedCallback(void);
void cameraResetFinishedCallback(void);

Camera::Camera() :
    _displayWidth(0.0f),
    _displayHeight(0.0f),
    _target(0.0f, 0.0f, 0.0f),
    _isMovingToTarget(false),
    _allowIdleAnimation(false),
    _rotation(0.0f),
    _zoom(-3.0f),
    _maxZoom(MAX_MAX_ZOOM),
    _targetMoveStartTime(MAXFLOAT),
    _targetMoveStartPosition(0.0f, 0.0f, 0.0f),
    _zoomStart(0.0f),
    _zoomTarget(0.0f),
    _zoomStartTime(0.0f),
    _zoomDuration(0.0f),
    _translationY(0.0f),
    _translationYStart(0.0f),
    _translationYTarget(0.0f),
    _translationYStartTime(0.0f),
    _translationYDuration(0.0f),
    _updateTime(0.0f),
    _idleStartTime(0.0f),
    _panEndTime(0.0f),
    _zoomVelocity(0.0f),
    _zoomEndTime(0.0f),
    _rotationVelocity(0.0f),
    _rotationEndTime(0.0f),
    _rotationStartTime(0.0f),
    _rotationDuration(0.0f),
    _moveDuration(0.0f)
{
    _rotationMatrix = Matrix4::identity();
    _panVelocity.x = 0.0f;
    _panVelocity.y = 0.0f;
}

static const float NEAR_PLANE = 0.05f;
static const float FAR_PLANE = 100.0f;

void Camera::update(TimeInterval currentTime) {
    TimeInterval delta = currentTime - _updateTime;
    _updateTime = currentTime;
    
    handleIdleMovement(delta);
    handleMomentumPan(delta);
    handleMomentumZoom(delta);
    handleMomentumRotation(delta);
    Vector3 currentTarget = calculateMoveTarget(delta);
    handleAnimatedZoom(delta);
    handleAnimatedRotation(delta);
    handleAnimatedTranslateY(delta);
    
    float aspect = fabsf(_displayWidth / _displayHeight);
    Matrix4 model = _rotationMatrix * Matrix4::translation(Vector3(-currentTarget.getX(), -currentTarget.getY(), -currentTarget.getZ()));
    Matrix4 view = Matrix4::translation(Vector3(0.0f, 0.0f, _zoom));
    Matrix4 translation = Matrix4::translation(Vector3(0.0f, _translationY, 0.0f));

    Matrix4 modelView = view * model;
    Matrix4 projectionMatrix;
    
    projectionMatrix = translation * Matrix4::perspective(DegreesToRadians(65.0f), aspect, NEAR_PLANE, FAR_PLANE);
    
    _projectionMatrix = projectionMatrix;
    _modelViewMatrix = modelView;
    _modelViewProjectionMatrix = projectionMatrix * modelView;
}

void Camera::handleIdleMovement(TimeInterval delta) {
    // Rotate camera if idle
    TimeInterval idleTime = _updateTime - _idleStartTime;
    float idleDelay = 0.1;
    
    if (_allowIdleAnimation && (idleTime > idleDelay)) {
        // Ease in
        float spinupFactor = fminf(1.0, (idleTime - idleDelay) / 2);
        rotateRadiansX(0.0006 * spinupFactor);
        rotateRadiansY(0.0001 * spinupFactor);
    }
}

void Camera::handleMomentumPan(TimeInterval delta) {
    //momentum panning
    if (_panVelocity.x != 0 && _panVelocity.y != 0) {
        
        TimeInterval rotationTime = _updateTime-_panEndTime;
        static TimeInterval totalTime = 1.0;
        float timeT = rotationTime / totalTime;
        if(timeT > 1.0) {
            _panVelocity.x = _panVelocity.y = 0.0f;
        }
        else {
            //quadratic ease out
            float positionT = 1+(timeT*timeT-2.0f*timeT);
            
            rotateRadiansX(_panVelocity.x*delta*positionT);
            rotateRadiansY(_panVelocity.y*delta*positionT);
        }
    }
}

void Camera::handleMomentumZoom(TimeInterval delta) {
    //momentum zooming
    if (_zoomVelocity != 0) {
        static TimeInterval totalTime = 0.5;
        TimeInterval zoomTime = _updateTime-_zoomEndTime;
        float timeT = zoomTime / totalTime;
        if(timeT > 1.0) {
            _zoomVelocity = 0;
        }
        else {
            //quadratic ease out
            float positionT = 1+(timeT*timeT-2.0f*timeT);
            zoomByScale(_zoomVelocity*delta*positionT);
        }
    }
}

void Camera::handleMomentumRotation(TimeInterval delta) {
    //momentum rotation
    if (_rotationVelocity != 0) {
        TimeInterval rotationTime = _updateTime-_rotationEndTime;
        static TimeInterval totalTime = 1.0;
        float timeT = rotationTime / totalTime;
        if(timeT > 1.0) {
            _rotationVelocity = 0;
        }
        else {
            //quadratic ease out
            float positionT = 1+(timeT*timeT-2.0f*timeT);
            
            rotateRadiansZ(_rotationVelocity*delta*positionT);
        }
    }
}

void Camera::handleAnimatedTranslateY(TimeInterval delta) {
    // Use same easing function as zoom method, since they will usually be called together.
    // resetZoomAndRotationAnimated reset translateY to 0.0
    
    if(_translationYStartTime < _updateTime) {
        float timeT = (_updateTime - _translationYStartTime) / _translationYDuration;
        if(timeT > 1.0f) {
            _translationYStartTime = MAXFLOAT;
            _translationY = _translationYTarget;
        }
        else {
            float positionT;
            
            // Quadratic ease-in / ease-out
            if (timeT < 0.5f)
            {
                positionT = timeT * timeT * 2;
            }
            else {
                positionT = 1.0f - ((timeT - 1.0f) * (timeT - 1.0f) * 2.0f);
            }
            _translationY = _translationYStart + (_translationYTarget - _translationYStart) * positionT;
        }
    }
}

void Camera::handleAnimatedZoom(TimeInterval delta) {
    //animated zoom
    if(_zoomStartTime < _updateTime) {
        float timeT = (_updateTime - _zoomStartTime) / _zoomDuration;
        if(timeT > 1.0f) {
            _zoomStartTime = MAXFLOAT;
        }
        else {
            float positionT;
            
            // Quadratic ease-in / ease-out
            if (timeT < 0.5f)
            {
                positionT = timeT * timeT * 2;
            }
            else {
                positionT = 1.0f - ((timeT - 1.0f) * (timeT - 1.0f) * 2.0f);
            }
            _zoom = _zoomStart + (_zoomTarget-_zoomStart)*positionT;
        }
    }
}

void Camera::handleAnimatedRotation(TimeInterval delta) {
    //animated rotation
    if (_rotationStartTime < _updateTime) {
        float timeT = (_updateTime - _rotationStartTime) / _rotationDuration;
        if(timeT > 1.0f) {
            _rotationStartTime = MAXFLOAT;
            cameraResetFinishedCallback();
        }
        else {
            float positionT;
            
            // Quadratic ease-in / ease-out
            if (timeT < 0.5f)
            {
                positionT = timeT * timeT * 2;
            }
            else {
                positionT = 1.0f - ((timeT - 1.0f) * (timeT - 1.0f) * 2.0f);
            }
            _rotationMatrix = Matrix4(Vectormath::Aos::slerp(positionT, _rotationStart , _rotationTarget), Vector3(0.0f, 0.0f, 0.0f));
        }
    }
}
Vector3 Camera::calculateMoveTarget(TimeInterval delta) {
    Vector3 currentTarget;
    
    //animated move to target
    if(_targetMoveStartTime < _updateTime) {
        float timeT = (_updateTime - _targetMoveStartTime) / _moveDuration;
        if(timeT > 1.0f) {
            currentTarget = _target;
            _targetMoveStartTime = MAXFLOAT;
            _isMovingToTarget = false;
            cameraMoveFinishedCallback();
        }
        else {
            float positionT;
            
            // Quadratic ease-in / ease-out
            if (timeT < 0.5f)
            {
                positionT = timeT * timeT * 2;
            }
            else {
                positionT = 1.0f - ((timeT - 1.0f) * (timeT - 1.0f) * 2.0f);
            }
            
            currentTarget = _targetMoveStartPosition + ((_target - _targetMoveStartPosition) * positionT);
        }
    }
    else {
        currentTarget = _target;
    }
    
    return currentTarget;
}

void Camera::setRotationAndRenormalize(const Matrix4& matrix) {
    _rotationMatrix = matrix;
    
    // Becasue we are doing sucessive modification of the rotation matrix, error can accumulate
    // Here we renormalize the matrix to make sure that the error doesn't grow
    Vector3 zAxis = Vectormath::Aos::normalize(_rotationMatrix.getCol2().getXYZ());
    _rotationMatrix.setCol0(Vector4(Vectormath::Aos::normalize(Vectormath::Aos::cross(_rotationMatrix.getCol1().getXYZ(), zAxis)), 0.0f));
    _rotationMatrix.setCol1(Vector4(Vectormath::Aos::normalize(Vectormath::Aos::cross(zAxis, _rotationMatrix.getCol0().getXYZ())), 0.0f));
    _rotationMatrix.setCol2(Vector4(zAxis, 0.0f));
}

float Camera::currentZoom(void) {
    return _zoom;
}

Matrix4 Camera::currentModelViewProjection(void) {
    return _modelViewProjectionMatrix;
}

Matrix4 Camera::currentModelView(void) {
    return _modelViewMatrix;
}

Matrix4 Camera::currentProjection(void) {
    return _projectionMatrix;
}

Vector3 Camera::cameraInObjectSpace(void) {
    Matrix4 invertedModelViewMatrix = Vectormath::Aos::inverse(_modelViewMatrix);
    return invertedModelViewMatrix.getTranslation();
}

Vector3 Camera::applyModelViewToPoint(Vector2 point) {
    Vector4 vec4FromPoint(point.x, point.y, -0.1, 1);
    Matrix4 invertedModelViewProjectionMatrix = Vectormath::Aos::inverse(_modelViewProjectionMatrix);
    vec4FromPoint = invertedModelViewProjectionMatrix * vec4FromPoint;
    vec4FromPoint = vec4FromPoint / vec4FromPoint.getW();
    
    return Vector3(vec4FromPoint.getX(), vec4FromPoint.getY(), vec4FromPoint.getZ());
}

void Camera::rotateRadiansX(float rotate) {
    setRotationAndRenormalize(Matrix4::rotation(rotate, Vector3(0.0f, 1.0f, 0.0f)) * _rotationMatrix);
}

void Camera::rotateRadiansY(float rotate) {
    setRotationAndRenormalize(Matrix4::rotation(rotate, Vector3(1.0f, 0.0f, 0.0f)) * _rotationMatrix);
}

void Camera::rotateRadiansZ(float rotate) {
    setRotationAndRenormalize(_rotationMatrix = Matrix4::rotation(rotate, Vector3(0.0f, 0.0f, 1.0f)) * _rotationMatrix);
}

void Camera::rotateAnimated(Matrix4 rotation, TimeInterval duration) {
    _rotationStart = Quaternion(_rotationMatrix.getUpper3x3());
    _rotationTarget = Quaternion(rotation.getUpper3x3());
    _rotationStartTime = _updateTime;
    _rotationDuration = duration;
}

void Camera::zoomByScale(float zoom) {
    _zoom += zoom * -_zoom;
    if(_zoom > _maxZoom) {
        _zoom = _maxZoom;
    }
    
    if(_zoom < MIN_ZOOM) {
        _zoom = MIN_ZOOM;
    }
}

void Camera::resetZoomAndRotationAnimated(bool isPortraitMode) {
    // TODO: should have better way of distributing this flag
    GlobeVisualization::setPortrait(isPortraitMode);
    
    float targetZoom;
    Matrix4 targetRotation;
    
    if (isPortraitMode) {
        targetZoom = -4.5;
        targetRotation = Matrix4::rotation(M_PI_2, Vector3(0, 0, 1));
    } else {
        targetZoom = -3;
        targetRotation = Matrix4::identity();
    }
    
    float zoomDistance = _zoom - targetZoom;
    
    // Always perform the zoom, this will reset the center target if it has been changed elsewhere.
    //LOG("zooming from %f to %f", _zoom, targetZoom);
    TimeInterval duration = fabs(zoomDistance) / 2;
    //zoom via setTarget so that we also reset translation.
    Target target;
    target.zoom = targetZoom;
    target.maxZoom = MAX_MAX_ZOOM;
    setTarget(target, duration);
    rotateAnimated(targetRotation, duration);
    translateYAnimated(0.0f, duration);
}

void Camera::zoomAnimated(float zoom, TimeInterval duration) {
    if(zoom > _maxZoom) {
        zoom = _maxZoom;
    }
    
    if(zoom < MIN_ZOOM) {
        zoom = MIN_ZOOM;
    }
    
    _zoomStart = _zoom;
    _zoomTarget = zoom;
    _zoomStartTime = _updateTime;
    _zoomDuration = duration;
}

void Camera::setTarget(const Target& target, TimeInterval duration) {
    _targetMoveStartPosition = _target;
    _target = target.vector;
    _moveDuration = duration;
    _targetMoveStartTime = _updateTime;
    _isMovingToTarget = true;
    _maxZoom = target.maxZoom;
    if (_maxZoom > MAX_MAX_ZOOM) {
        _maxZoom = MAX_MAX_ZOOM;
    }
    zoomAnimated(target.zoom, duration);
}

void Camera::startMomentumPanWithVelocity(Vector2 velocity) {
    _panEndTime = _updateTime;
    _panVelocity = velocity;
}

void Camera::stopMomentumPan(void) {
    _panVelocity.x = _panVelocity.y = 0.0f;
}

void Camera::startMomentumZoomWithVelocity(float velocity) {
    _zoomEndTime = _updateTime;
    _zoomVelocity = velocity*0.5;
}

void Camera::stopMomentumZoom(void) {
    _zoomVelocity = 0;
}

void Camera::startMomentumRotationWithVelocity(float velocity) {
    _rotationVelocity = velocity;
    _rotationEndTime = _updateTime;
}

void Camera::stopMomentumRotation(void) {
    _rotationVelocity = 0;
}

void Camera::resetIdleTimer() {
    _idleStartTime = _updateTime;
}

void Camera::translateYAnimated(float translateY, TimeInterval duration) {
    _translationYStart = _translationY;
    _translationYTarget = translateY;
    _translationYStartTime = _updateTime;
    _translationYDuration = duration;
}

