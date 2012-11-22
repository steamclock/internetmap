//
//  MapDisplay.h
//  InternetMap
//

@class DisplayNode;
@class Camera;

@interface DisplayNode : NSObject
-(void)setX:(float)x;
-(void)setY:(float)y;
-(void)setZ:(float)z;
-(void)setSize:(float)size;
-(void)setColor:(UIColor *)color;
-(void)setLineColor:(UIColor *)color;
@end

@interface MapDisplay : NSObject

@property (nonatomic) NSUInteger numNodes;

@property (strong, nonatomic, readonly) Camera* camera;

-(void)update;
-(void)draw;

-(DisplayNode*)displayNodeAtIndex:(NSUInteger)index;
-(void)setLineIndices:(NSArray*)lineIndices;

@end
