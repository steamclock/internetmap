//
//  MapDisplay.h
//  InternetMap
//

#import <memory>

class Lines;
class Camera;
class Nodes;

@interface MapDisplay : NSObject


@property (nonatomic, readonly) std::shared_ptr<Camera> camera;

@property (nonatomic) std::shared_ptr<Nodes> nodes;
@property (nonatomic) std::shared_ptr<Nodes> selectedNodes;
@property (nonatomic) std::shared_ptr<Lines> visualizationLines;
@property (nonatomic) std::shared_ptr<Lines> highlightLines;

-(void)update;
-(void)draw;

@end
