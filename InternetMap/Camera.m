//
//  Camera.m
//  InternetMap
//

#import "Camera.h"

@interface Camera () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _rotationMatrix;
    float _rotation;
    float _zoom;
}

@end

@implementation Camera

-(id)init {
    if((self = [super init])) {
        _rotationMatrix = GLKMatrix4Identity;
        _zoom = -3.0f;
        self.target = GLKVector3Make(0.0f, 0.0f, 0.0f);
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

- (void)update
{
    float aspect = fabsf(self.displaySize.width / self.displaySize.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 model = GLKMatrix4Multiply(_rotationMatrix, GLKMatrix4MakeTranslation(-self.target.x, -self.target.y, -self.target.z));
    GLKMatrix4 zoom = GLKMatrix4MakeTranslation(0.0f, 0.0f, _zoom);
    GLKMatrix4 modelView = GLKMatrix4Multiply(zoom, model);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelView);
}

-(GLKMatrix4)currentModelViewProjection {
    return _modelViewProjectionMatrix;
}

@end
