//
//  DefaultVisualization.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import "Visualization.h"

#define SELECTED_NODE_COLOR UIColorFromRGB(0xffa300)
#define SELECTED_CONNECTION_COLOR_BRIGHT UIColorFromRGB(0xffa300)
#define SELECTED_CONNECTION_COLOR_DIM UIColorFromRGB(0x3f2800)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface DefaultVisualization : NSObject <Visualization>

-(GLKVector3)nodePosition:(Node*)node;
-(float)nodeSize:(Node*)node;
-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)nodes;
-(void)updateLineDisplay:(MapDisplay*)display forConnections:(NSArray*)connections;
-(void)resetDisplay:(MapDisplay*)display forNodes:(NSArray*)arrNodes;
- (void)resetDisplay:(MapDisplay *)display forSelectedNodes:(NSArray*)arrNodes;

@end
