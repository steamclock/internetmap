//
//  MapDisplay.h
//  InternetMap
//

typedef struct {
    float x;
    float y;
    float z;
    float size;
} DisplayNode;

@interface MapDisplay : NSObject

@property CGSize size;

-(void)update;
-(void)draw;

-(void)rotateRadiansX:(float)rotate;
-(void)rotateRadiansY:(float)rotate;
-(void)zoom:(float)zoom;

-(void)setNodesToDisplay:(DisplayNode*)nodes count:(int)count;

@end
