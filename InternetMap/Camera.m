
//  Camera.m
//  InternetMap
//

#import "Camera.h"

static const float MOVE_TIME = 1.0f;
static const float FINAL_ZOOM_ON_SELECTION = -0.4;

@interface Camera () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    GLKMatrix4 _projectionMatrix;
    
    GLKMatrix4 _rotationMatrix;
    float _rotation;
    float _zoom;
    GLKVector3 _target;
}

@property (nonatomic) NSTimeInterval targetMoveStartTime;
@property (nonatomic) GLKVector3 targetMoveStartPosition;

@property (nonatomic) float zoomStart;
@property (nonatomic) float zoomTarget;
@property (nonatomic) NSTimeInterval zoomStartTime;
@property (nonatomic) NSTimeInterval zoomDuration;

@property (nonatomic) NSTimeInterval updateTime;
@property (nonatomic) NSTimeInterval idleStartTime; // For "attract" mode

@property (nonatomic) CGPoint panVelocity;
@property (nonatomic) NSTimeInterval panEndTime;

@property (nonatomic) CGFloat zoomVelocity;
@property (nonatomic) NSTimeInterval zoomEndTime;

@property (nonatomic) CGFloat rotationVelocity;
@property (nonatomic) NSTimeInterval rotationEndTime;


@property (nonatomic) GLKQuaternion rotationStart;
@property (nonatomic) GLKQuaternion rotationTarget;
@property (nonatomic) NSTimeInterval rotationStartTime;
@property (nonatomic) NSTimeInterval rotationDuration;

@end

@implementation Camera

-(id)init {
    if((self = [super init])) {
        _rotationMatrix = GLKMatrix4Identity;
        _zoom = -3.0f;
        self.target = GLKVector3Make(0.0f, 0.0f, 0.0f);
        self.targetMoveStartPosition = GLKVector3Make(0.0f, 0.0f, 0.0f);
        self.targetMoveStartTime = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
        self.isMovingToTarget = NO;
    }
    
    return self;
}

#pragma mark - Main update loop

- (void)update
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    NSTimeInterval delta = now - self.updateTime;
    self.updateTime = now;

    [self handleIdleMovementAtTime:now delta:delta];
    [self handleMomentumPanAtTime:now delta:delta];
    [self handleMomentumZoomAtTime:now delta:delta];
    [self handleMomentumRotationAtTime:now delta:delta];
    GLKVector3 currentTarget = [self calculateMoveTargetAtTime:now delta:delta];
    [self handleAnimatedZoomAtTime:now delta:delta];
    [self handleAnimatedRotationAtTime:now delta:delta];
    
    
    float aspect = fabsf(self.displaySize.width / self.displaySize.height);
    GLKMatrix4 model = GLKMatrix4Multiply(_rotationMatrix, GLKMatrix4MakeTranslation(-currentTarget.x, -currentTarget.y, -currentTarget.z));
    GLKMatrix4 view = GLKMatrix4MakeTranslation(0.0f, 0.0f, _zoom);
    GLKMatrix4 modelView = GLKMatrix4Multiply(view, model);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    _projectionMatrix = projectionMatrix;
    _modelViewMatrix = modelView;
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelView);
}

#pragma mark - Update loop helpers

- (void)handleIdleMovementAtTime:(NSTimeInterval)now delta:(NSTimeInterval)delta {
    // Rotate camera if idle
    NSTimeInterval idleTime = now - self.idleStartTime;
    float idleDelay = 0.1;
    
    if (self.allowIdleAnimation && (idleTime > idleDelay)) {
        // Ease in
        float spinupFactor = fminf(1.0, (idleTime - idleDelay) / 2);
        
        [self rotateRadiansX:0.0006 * spinupFactor];
        [self rotateRadiansY:0.0001 * spinupFactor];
    }
}

- (void)handleMomentumPanAtTime:(NSTimeInterval)now delta:(NSTimeInterval)delta {
    //momentum panning
    if (self.panVelocity.x != 0 && self.panVelocity.y != 0) {
        
        NSTimeInterval rotationTime = now-self.panEndTime;
        static NSTimeInterval totalTime = 1.0;
        float timeT = rotationTime / totalTime;
        if(timeT > 1.0) {
            self.panVelocity = CGPointZero;
        }
        else {
            //quadratic ease out
            float positionT = 1+(timeT*timeT-2.0f*timeT);
            
            [self rotateRadiansX:self.panVelocity.x*delta*positionT];
            [self rotateRadiansY:self.panVelocity.y*delta*positionT];
        }
    }
}


- (void)handleMomentumZoomAtTime:(NSTimeInterval)now delta:(NSTimeInterval)delta {
    //momentum zooming
    if (self.zoomVelocity != 0) {
        static NSTimeInterval totalTime = 0.5;
        NSTimeInterval zoomTime = now-self.zoomEndTime;
        float timeT = zoomTime / totalTime;
        if(timeT > 1.0) {
            self.zoomVelocity = 0;
        }
        else {
            //quadratic ease out
            float positionT = 1+(timeT*timeT-2.0f*timeT);
            [self zoomByScale:self.zoomVelocity*delta*positionT];
        }
    }
}

-(void)handleMomentumRotationAtTime:(NSTimeInterval)now delta:(NSTimeInterval)delta {
    
    
    //momentum rotation
    if (self.rotationVelocity != 0) {
        
        NSTimeInterval rotationTime = now-self.rotationEndTime;
        static NSTimeInterval totalTime = 1.0;
        float timeT = rotationTime / totalTime;
        if(timeT > 1.0) {
            self.rotationVelocity = 0;
        }
        else {
            //quadratic ease out
            float positionT = 1+(timeT*timeT-2.0f*timeT);
            
            [self rotateRadiansZ:self.rotationVelocity*delta*positionT];
        }
    }
}

- (void)handleAnimatedZoomAtTime:(NSTimeInterval)now delta:(NSTimeInterval)delta {
    //animated zoom
    if(self.zoomStartTime < now) {
        float timeT = (now - self.zoomStartTime) / self.zoomDuration;
        if(timeT > 1.0f) {
            self.zoomStartTime = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
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
            _zoom = self.zoomStart + (self.zoomTarget-self.zoomStart)*positionT;
        }
    }
}

- (void)handleAnimatedRotationAtTime:(NSTimeInterval)now delta:(NSTimeInterval)delta {
    //animated rotation
    if (self.rotationStartTime < now) {
        float timeT = (now - self.rotationStartTime) / self.rotationDuration;
        if(timeT > 1.0f) {
            self.rotationStartTime = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
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
            _rotationMatrix = GLKMatrix4MakeWithQuaternion(GLKQuaternionSlerp(self.rotationStart, self.rotationTarget, positionT));
        }
    }
}

- (GLKVector3)calculateMoveTargetAtTime:(NSTimeInterval)now delta:(NSTimeInterval)delta {
    
    GLKVector3 currentTarget;
    //animated move to target
    if(self.targetMoveStartTime < now) {
        float timeT = (now - self.targetMoveStartTime) / MOVE_TIME;
        if(timeT > 1.0f) {
            currentTarget = self.target;
            self.targetMoveStartTime = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
            self.isMovingToTarget = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraMovementFinished" object:nil];
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
            
            currentTarget = GLKVector3Add(self.targetMoveStartPosition, GLKVector3MultiplyScalar(GLKVector3Subtract(self.target, self.targetMoveStartPosition), positionT));
        }
    }
    else {
        currentTarget = self.target;
    }
    return currentTarget;
}


#pragma mark - Information retrieval

-(GLKVector3)target {
    return _target;
}

-(float)currentZoom {
    return _zoom;
}

-(GLKMatrix4)currentModelViewProjection {
    return _modelViewProjectionMatrix;
}

-(GLKMatrix4)currentModelView {
    return _modelViewMatrix;
}


-(GLKMatrix4)currentProjection {
    return _projectionMatrix;
}

- (GLKVector3)cameraInObjectSpace {
    GLKMatrix4 invertedModelViewMatrix = GLKMatrix4Invert(_modelViewMatrix, NULL);
    return GLKVector3Make(invertedModelViewMatrix.m30, invertedModelViewMatrix.m31, invertedModelViewMatrix.m32);
    
}

-(GLKVector3)applyModelViewToPoint:(CGPoint)point {
    GLKVector4 vec4FromPoint = GLKVector4Make(point.x, point.y, -0.1, 1);
    GLKMatrix4 invertedModelViewProjectionMatrix = GLKMatrix4Invert(_modelViewProjectionMatrix, NULL);
    vec4FromPoint = GLKMatrix4MultiplyVector4(invertedModelViewProjectionMatrix, vec4FromPoint);
    vec4FromPoint = GLKVector4DivideScalar(vec4FromPoint, vec4FromPoint.w);
    
    return GLKVector3Make(vec4FromPoint.x, vec4FromPoint.y, vec4FromPoint.z);
    
}

#pragma mark - View manipulation

-(void) rotateRadiansX:(float)rotate {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 1.0f, 0.0f), _rotationMatrix);
}

-(void) rotateRadiansY:(float)rotate {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 1.0f, 0.0f, 0.0f), _rotationMatrix);
}

-(void) rotateRadiansZ:(float)rotate {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 0.0f, 1.0f), _rotationMatrix);
}

- (void)setRotationAnimatedTo:(GLKMatrix4)rotation duration:(NSTimeInterval)duration{
    self.rotationStart = GLKQuaternionMakeWithMatrix4(_rotationMatrix);
    self.rotationTarget = GLKQuaternionMakeWithMatrix4(rotation);
    self.rotationStartTime = [NSDate timeIntervalSinceReferenceDate];
    self.rotationDuration = duration;
}

-(void) zoomByScale:(float)zoom {
    _zoom += zoom * -_zoom;
    if(_zoom > -0.2) {
        _zoom = -0.2;
    }
    
    if(_zoom < -10.0f) {
        _zoom = -10.0f;
    }
}

- (void)zoomAnimatedTo:(float)zoom duration:(NSTimeInterval)duration {
    if(zoom > -0.2) {
        zoom = -0.2;
    }
    
    if(zoom < -10.0f) {
        zoom = -10.0f;
    }
    self.zoomStart = _zoom;
    self.zoomTarget = zoom;
    self.zoomStartTime = [NSDate timeIntervalSinceReferenceDate];
    self.zoomDuration = duration;
}

-(void)setTarget:(GLKVector3)target {
    _targetMoveStartPosition = _target;
    _target = target;
    _targetMoveStartTime = [NSDate timeIntervalSinceReferenceDate];
    _isMovingToTarget = YES;
    [self zoomAnimatedTo:FINAL_ZOOM_ON_SELECTION duration:MOVE_TIME];
}

#pragma mark - Momentum Panning/Zooming/Rotation

- (void)startMomentumPanWithVelocity:(CGPoint)velocity {
    self.panEndTime = [NSDate timeIntervalSinceReferenceDate];
    self.panVelocity = velocity;
}

- (void)stopMomentumPan {
    self.panVelocity = CGPointZero;
}

- (void)startMomentumZoomWithVelocity:(CGFloat)velocity {
    self.zoomEndTime = [NSDate timeIntervalSinceReferenceDate];
    self.zoomVelocity = velocity*0.5;
}

- (void)stopMomentumZoom {
    self.zoomVelocity = 0;
}

- (void)startMomentumRotationWithVelocity:(CGFloat)velocity {
    self.rotationVelocity = velocity;
    self.rotationEndTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void)stopMomentumRotation {
    self.rotationVelocity = 0;
}


#pragma mark - Idle Timer

-(void)resetIdleTimer {
    self.idleStartTime = [NSDate timeIntervalSinceReferenceDate];
}




@end
