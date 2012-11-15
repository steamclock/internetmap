//
//  MapDisplay.h
//  InternetMap
//

@class DisplayNode;

@interface DisplayNode : NSObject
-(void)setX:(float)x;
-(void)setY:(float)y;
-(void)setZ:(float)z;
-(void)setSize:(float)size;
-(void)setColor:(UIColor *)color;
@end

@interface MapDisplay : NSObject

@property (nonatomic) NSUInteger numNodes;
@property (nonatomic) CGSize size;

-(void)update;
-(void)draw;

-(void)rotateRadiansX:(float)rotate;
-(void)rotateRadiansY:(float)rotate;
-(void)zoom:(float)zoom;

-(DisplayNode*)displayNodeAtIndex:(NSUInteger)index;

@end
