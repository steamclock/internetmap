//
//  MapDisplay.h
//  InternetMap
//

class Lines;

#import <memory>

@class Camera;
@class Nodes;


@interface MapDisplay : NSObject


@property (strong, nonatomic, readonly) Camera* camera;

@property (strong, nonatomic) Nodes* nodes;
@property (strong, nonatomic) Nodes* selectedNodes;
@property (nonatomic) std::shared_ptr<Lines> visualizationLines;
@property (nonatomic) std::shared_ptr<Lines> highlightLines;

-(void)update;
-(void)draw;

@end
