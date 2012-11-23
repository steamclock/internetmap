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
-(void)updateDisplay:(MapDisplay*)display forNodes:(NSArray*)nodes;

@end
