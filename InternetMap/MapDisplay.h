//
//  MapDisplay.h
//  InternetMap
//

@class Camera;
@class Lines;
@class Nodes;


@interface MapDisplay : NSObject


@property (strong, nonatomic, readonly) Camera* camera;

@property (strong, nonatomic) Nodes* nodes;
@property (strong, nonatomic) Lines* visualizationLines;
@property (strong, nonatomic) Lines* highlightLines;

-(void)update;
-(void)draw;

@end
