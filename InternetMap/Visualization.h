//
//  Visualization.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@class Node;
@class MapDisplay;

@protocol Visualization <NSObject>

-(GLKVector3)nodePosition:(Node*)node;
-(float)nodeSize:(Node*)node;

// Update the properties of the nodes in the MapDisplay
// Note: can pass a subset of nodes and it will only update the specified
// nodes and leave the others unchanged
-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)nodes;

// Update the visualizationLines in the display
// Note: unlike updateDisplay, this will replace all existing lines
-(void)updateLineDisplay:(MapDisplay*)display forConnections:(NSArray*)connections;

@end
