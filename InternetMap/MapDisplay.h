//
//  MapDisplay.h
//  InternetMap
//

@class DisplayNode;

@interface DisplayNode : NSObject

@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;
@property (nonatomic) float size;

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
