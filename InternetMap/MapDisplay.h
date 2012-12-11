//
//  MapDisplay.h
//  InternetMap
//

@class DisplayNode;
@class Camera;
@class Lines;

@interface DisplayNode : NSObject
-(void)setX:(float)x;
-(void)setY:(float)y;
-(void)setZ:(float)z;
-(void)setSize:(float)size;
-(void)setColor:(UIColor *)color;
@end

@interface MapDisplay : NSObject

@property (nonatomic) NSUInteger numNodes;

@property (strong, nonatomic, readonly) Camera* camera;

@property (strong, nonatomic) Lines* visualizationLines;
@property (strong, nonatomic) Lines* highlightLines;
-(DisplayNode*)displayNodeAtIndex:(NSUInteger)index;

-(void)update;
-(void)draw;

@end
