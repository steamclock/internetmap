//
//  DefaultVisualization.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import "Visualization.h"

@interface DefaultVisualization : NSObject <Visualization>

-(GLKVector3)nodePosition:(Node*)node;
-(float)nodeSize:(Node*)node;
-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)nodes;
-(void)updateLineDisplay:(MapDisplay*)display forConnections:(NSArray*)connections;

@end
