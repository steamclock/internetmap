//
//  Camera.m
//  InternetMap
//

#import "Camera.h"

static const float MOVE_TIME = 1.0f;

@interface Camera () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _rotationMatrix;
    float _rotation;
    float _zoom;
    GLKVector3 _target;
}

@property (nonatomic) NSTimeInterval targetMoveStart;
@property (nonatomic) GLKVector3 targetMoveStartPosition;
@end

@implementation Camera

-(id)init {
    if((self = [super init])) {
        _rotationMatrix = GLKMatrix4Identity;
        _zoom = -3.0f;
        self.target = GLKVector3Make(0.0f, 0.0f, 0.0f);
        self.targetMoveStartPosition = GLKVector3Make(0.0f, 0.0f, 0.0f);
        self.targetMoveStart = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
    }
    
    return self;
}

-(void) rotateRadiansX:(float)rotate {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 1.0f, 0.0f), _rotationMatrix);
}

-(void) rotateRadiansY:(float)rotate {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 1.0f, 0.0f, 0.0f), _rotationMatrix);
}

-(void) zoom:(float)zoom {
    _zoom += zoom * -_zoom;
    
    if(_zoom > -0.2) {
        _zoom = -0.2;
    }
    
    if(_zoom < -10.0f) {
        _zoom = -10.0f;
    }
}

-(void)setTarget:(GLKVector3)target {
    _targetMoveStartPosition = _target;
    _target = target;
    _targetMoveStart = [NSDate timeIntervalSinceReferenceDate];
}

-(GLKVector3)target {
    return _target;
}

- (void)update
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    GLKVector3 currentTarget;
    
    if(self.targetMoveStart < now) {
        float timeT = (now - self.targetMoveStart) / MOVE_TIME;
        if(timeT > 1.0f) {
            currentTarget = self.target;
            self.targetMoveStart = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
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
    
    float aspect = fabsf(self.displaySize.width / self.displaySize.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 model = GLKMatrix4Multiply(_rotationMatrix, GLKMatrix4MakeTranslation(-currentTarget.x, -currentTarget.y, -currentTarget.z));
    GLKMatrix4 zoom = GLKMatrix4MakeTranslation(0.0f, 0.0f, _zoom);
    GLKMatrix4 modelView = GLKMatrix4Multiply(zoom, model);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelView);
}

-(GLKMatrix4)currentModelViewProjection {
    return _modelViewProjectionMatrix;
}

@end
