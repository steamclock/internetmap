
//  Camera.cpp
//  InternetMap
//

#import "Camera.hpp"

static const float MOVE_TIME = 1.0f;
static const float FINAL_ZOOM_ON_SELECTION = -0.4;

// TODO: better way to register this
void cameraMoveFinishedCallback(void);

Camera::Camera() :
    _displayWidth(0.0f),
    _displayHeight(0.0f),
    //_target(0.0f, 0.0f, 0.0f),
    _isMovingToTarget(false),
    _allowIdleAnimation(false),
    _rotation(0.0f),
    _zoom(-3.0f),
    _targetMoveStartTime(MAXFLOAT),
    //_targetMoveStartPosition()
    _zoomStart(0.0f),
    _zoomTarget(0.0f),
    _zoomStartTime(0.0f),
    _zoomDuration(0.0f),
    _updateTime(0.0f),
    _idleStartTime(0.0f),
    _panEndTime(0.0f),
    _zoomVelocity(0.0f),
    _zoomEndTime(0.0f),
    _rotationVelocity(0.0f),
    _rotationEndTime(0.0f),
    _rotationStartTime(0.0f),
    _rotationDuration(0.0f)
{
    _rotationMatrix = GLKMatrix4Identity;
    _zoom = -3.0f;
    _target = GLKVector3Make(0.0f, 0.0f, 0.0f);
    _targetMoveStartPosition = GLKVector3Make(0.0f, 0.0f, 0.0f);
    _isMovingToTarget = false;
    _panVelocity.x = 0.0f;
    _panVelocity.y = 0.0f;
}

#pragma mark - Main update loop

void Camera::update(TimeInterval currentTime) {
    TimeInterval delta = currentTime - _updateTime;
    _updateTime = currentTime;
    
    handleIdleMovement(delta);
    handleMomentumPan(delta);
    handleMomentumZoom(delta);
    handleMomentumRotation(delta);
    GLKVector3 currentTarget = calculateMoveTarget(delta);
    handleAnimatedZoom(delta);
    handleAnimatedRotation(delta);
    
    float aspect = fabsf(_displayWidth / _displayHeight);
    GLKMatrix4 model = GLKMatrix4Multiply(_rotationMatrix, GLKMatrix4MakeTranslation(-currentTarget.x, -currentTarget.y, -currentTarget.z));
    GLKMatrix4 view = GLKMatrix4MakeTranslation(0.0f, 0.0f, _zoom);
    GLKMatrix4 modelView = GLKMatrix4Multiply(view, model);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    _projectionMatrix = projectionMatrix;
    _modelViewMatrix = modelView;
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelView);
}

#pragma mark - Update loop helpers

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
            _rotationMatrix = GLKMatrix4MakeWithQuaternion(GLKQuaternionSlerp(_rotationStart, _rotationTarget, positionT));
        }
    }
}
GLKVector3 Camera::calculateMoveTarget(TimeInterval delta) {
    GLKVector3 currentTarget;
    
    //animated move to target
    if(_targetMoveStartTime < _updateTime) {
        float timeT = (_updateTime - _targetMoveStartTime) / MOVE_TIME;
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
            
            currentTarget = GLKVector3Add(_targetMoveStartPosition, GLKVector3MultiplyScalar(GLKVector3Subtract(_target, _targetMoveStartPosition), positionT));
        }
    }
    else {
        currentTarget = _target;
    }
    
    return currentTarget;
}


#pragma mark - Information retrieval

float Camera::currentZoom(void) {
    return _zoom;
}

GLKMatrix4 Camera::currentModelViewProjection(void) {
    return _modelViewProjectionMatrix;
}

GLKMatrix4 Camera::currentModelView(void) {
    return _modelViewMatrix;
}

GLKMatrix4 Camera::currentProjection(void) {
    return _projectionMatrix;
}

GLKVector3 Camera::cameraInObjectSpace(void) {
    GLKMatrix4 invertedModelViewMatrix = GLKMatrix4Invert(_modelViewMatrix, NULL);
    return GLKVector3Make(invertedModelViewMatrix.m30, invertedModelViewMatrix.m31, invertedModelViewMatrix.m32);
}

GLKVector3 Camera::applyModelViewToPoint(GLKVector2 point) {
    GLKVector4 vec4FromPoint = GLKVector4Make(point.x, point.y, -0.1, 1);
    GLKMatrix4 invertedModelViewProjectionMatrix = GLKMatrix4Invert(_modelViewProjectionMatrix, NULL);
    vec4FromPoint = GLKMatrix4MultiplyVector4(invertedModelViewProjectionMatrix, vec4FromPoint);
    vec4FromPoint = GLKVector4DivideScalar(vec4FromPoint, vec4FromPoint.w);
    
    return GLKVector3Make(vec4FromPoint.x, vec4FromPoint.y, vec4FromPoint.z);
}

#pragma mark - View manipulation

void Camera::rotateRadiansX(float rotate) {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 1.0f, 0.0f), _rotationMatrix);
}

void Camera::rotateRadiansY(float rotate) {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 1.0f, 0.0f, 0.0f), _rotationMatrix);
}

void Camera::rotateRadiansZ(float rotate) {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 0.0f, 1.0f), _rotationMatrix);
}

void Camera::rotateAnimated(GLKMatrix4 rotation, TimeInterval duration) {
    _rotationStart = GLKQuaternionMakeWithMatrix4(_rotationMatrix);
    _rotationTarget = GLKQuaternionMakeWithMatrix4(rotation);
    _rotationStartTime = _updateTime;
    _rotationDuration = duration;
}

void Camera::zoomByScale(float zoom) {
    _zoom += zoom * -_zoom;
    if(_zoom > -0.2) {
        _zoom = -0.2;
    }
    
    if(_zoom < -10.0f) {
        _zoom = -10.0f;
    }
}

void Camera::zoomAnimated(float zoom, TimeInterval duration) {
    if(zoom > -0.2) {
        zoom = -0.2;
    }
    
    if(zoom < -10.0f) {
        zoom = -10.0f;
    }
    
    _zoomStart = _zoom;
    _zoomTarget = zoom;
    _zoomStartTime = _updateTime;
    _zoomDuration = duration;
}

void Camera::setTarget(const GLKVector3& target) {
    _targetMoveStartPosition = _target;
    _target = target;
    _targetMoveStartTime = _updateTime;
    _isMovingToTarget = true;
    zoomAnimated(FINAL_ZOOM_ON_SELECTION, MOVE_TIME);
}

#pragma mark - Momentum Panning/Zooming/Rotation

void Camera::startMomentumPanWithVelocity(GLKVector2 velocity) {
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


#pragma mark - Idle Timer

void Camera::resetIdleTimer() {
    _idleStartTime = _updateTime;
}
