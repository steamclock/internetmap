//
//  DefaultVisualization.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import "Visualization.h"

@interface DefaultVisualization : NSObject <Visualization>

-(GLKVector3)nodePosition:(Node*)node;
-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)nodes;

@end
