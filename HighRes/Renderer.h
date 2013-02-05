//
//  Renderer.h
//  HighRes
//

#import <Foundation/Foundation.h>

@interface Renderer : NSObject

-(void)display;
-(void)resizeWithWidth:(float)width andHeight:(float)height;
-(void)rotateRadiansX:(float)x radiansY:(float)y;
-(void)zoom:(float)zoom;
-(void)clickedAtPoint:(NSPoint)point;

-(void)screenshot:(NSString*)filename;

@end
