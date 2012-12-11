//
//  MapData
//  InternetMap
//

#import "Visualization.h"

@class MapDisplay;
@class Node;

@interface MapData : NSObject

@property (strong, nonatomic) NSObject<Visualization>* visualization;

-(void)loadFromFile:(NSString*)filename;
-(void)loadFromAttrFile:(NSString*)filename;
-(void)updateDisplay:(MapDisplay*)display;

-(Node*)nodeAtIndex:(NSUInteger)index;

@property (strong, nonatomic) NSMutableArray* nodes;
@property (strong, nonatomic) NSMutableDictionary* nodesByAsn;
@property (strong, nonatomic) NSMutableArray* connections;

@end
