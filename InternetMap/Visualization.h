//
//  Visualization.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <vector>
#include "Node.hpp"
#include "Connection.hpp"

class MapDisplay;

@protocol Visualization <NSObject>

-(GLKVector3)nodePosition:(NodePointer)node;
-(float)nodeSize:(NodePointer)node;

// Update the properties of the nodes in the MapDisplay
// Note: can pass a subset of nodes and it will only update the specified
// nodes and leave the others unchanged
-(void)updateDisplay:(MapDisplay*)display forNodes:(std::vector<NodePointer>)nodes;

//same as updateDisplay:forNodes:, but will replace all nodes
-(void)resetDisplay:(MapDisplay*)display forNodes:(std::vector<NodePointer>)arrNodes;

//same as resetDisplay:forNodes:, but for selected nodes instead of normal nodes
- (void)resetDisplay:(MapDisplay *)display forSelectedNodes:(std::vector<NodePointer>)arrNodes;

// Update the visualizationLines in the display
// Note: unlike updateDisplay, this will replace all existing lines
-(void)updateLineDisplay:(MapDisplay*)display forConnections:(std::vector<ConnectionPointer>)connections;


@end
