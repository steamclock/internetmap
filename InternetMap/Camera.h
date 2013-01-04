//
//  Camera.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import "GLKit/GLKit.h"

@protocol CameraDelegate <NSObject>

- (BOOL)shouldDoIdleAnimation;

@end


@interface Camera : NSObject

@property (nonatomic) CGSize displaySize;

@property (nonatomic) GLKVector3 target;
@property (nonatomic) BOOL isMovingToTarget;
@property (nonatomic, weak) id<CameraDelegate> delegate;

-(void)rotateRadiansX:(float)rotate;
-(void)rotateRadiansY:(float)rotate;
-(void)rotateRadiansZ:(float)rotate;
-(void)rotateAnimatedTo:(GLKMatrix4)rotation duration:(NSTimeInterval)duration;
-(void)zoomAnimatedTo:(float)zoom duration:(NSTimeInterval)duration;
-(void)zoom:(float)zoom;
-(void)resetIdleTimer;

-(void)update;

-(GLKMatrix4)currentModelViewProjection;
-(GLKMatrix4)currentModelView;
-(GLKMatrix4)currentProjection;
-(float)currentZoom;

-(GLKVector3)applyModelViewToPoint:(CGPoint)point;
-(GLKVector3)cameraInObjectSpace;

- (void)startMomentumPanWithVelocity:(CGPoint)velocity;
- (void)stopMomentumPan;

@end
