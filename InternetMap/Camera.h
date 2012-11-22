//
//  Camera.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import "GLKit/GLKit.h"

@interface Camera : NSObject

@property (nonatomic) CGSize displaySize;

@property (nonatomic) GLKVector3 target;
-(void)rotateRadiansX:(float)rotate;
-(void)rotateRadiansY:(float)rotate;
-(void)zoom:(float)zoom;

-(void)update;

-(GLKMatrix4)currentModelViewProjection;


@end
