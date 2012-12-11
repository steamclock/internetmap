//
//  Lines.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Lines : NSObject

-(id)initWithLineCount:(NSUInteger)count;

-(void)beginUpdate;
-(void)endUpdate;
-(void)updateLine:(NSUInteger)index withStart:(GLKVector3)start startColor:(UIColor*)startColour end:(GLKVector3)end endColor:(UIColor*)endColor;

-(void)display;

@end
