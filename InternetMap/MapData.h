//
//  MapData
//  InternetMap
//

#import "Visualization.h"
#include <memory>
#include <vector>
#include <map>
#include "Node.hpp"

@class MapDisplay;

@interface MapData : NSObject

@property (strong, nonatomic) NSObject<Visualization>* visualization;

-(void)loadFromFile:(NSString*)filename;
-(void)loadFromAttrFile:(NSString*)filename;
-(void)loadAsInfo:(NSString*)filename;
-(void)updateDisplay:(MapDisplay*)display;

-(NodePointer)nodeAtIndex:(NSUInteger)index;

@property (nonatomic) std::vector<NodePointer> nodes;
@property (nonatomic) std::map<std::string, NodePointer> nodesByAsn;
@property (strong, nonatomic) NSMutableArray* boxesForNodes;
@property (strong, nonatomic) NSMutableArray* connections;

@end
