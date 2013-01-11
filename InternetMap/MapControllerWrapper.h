//
//  MapControllerWrapper.h
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <GLKit/GLKit.h>

@class NodeWrapper;

@interface MapControllerWrapper : NSObject



@property (nonatomic) NSUInteger targetNode;
@property (nonatomic) CGSize displaySize;
@property (nonatomic, readonly) float currentZoom;
@property (nonatomic) int hoveredNodeIndex;
@property (strong) NSString* lastSearchIP;

- (void)setAllowIdleAnimation:(BOOL)allow;
- (void)resetIdleTimer;
- (void)update:(NSTimeInterval)now;
- (void)draw;
- (void)zoomAnimated:(float)zoom duration:(NSTimeInterval)duration;
- (void)beginNodeUpdates;
- (void)endNodeUpdates;
- (void)setColor:(UIColor*)color forNodeAtIndex:(int)index;
- (void)stopMomentumPan;
- (void)rotateRadiansX:(float)rotate;
- (void)rotateRadiansY:(float)rotate;
- (void)rotateRadiansZ:(float)rotate;
- (void)startMomentumPanWithVelocity:(CGPoint)velocity;
- (void)startMomentumRotationWithVelocity:(float)velocity;
- (void)stopMomentumRotation;
- (void)stopMomentumZoom;
- (void)startMomentumZoomWithVelocity:(float)velocity;
- (void)zoomByScale:(float)scale;
- (NodeWrapper*)nodeByASN:(NSString*)asn;
- (void)rotateAnimated:(GLKMatrix4)matrix duration:(NSTimeInterval)duration;

- (void)handleTouchDownAtPoint:(CGPoint)point;
- (void)selectHoveredNode;
- (void)unhoverNode;
- (int)indexForNodeAtPoint:(CGPoint)pointInView;
- (NodeWrapper*)nodeAtIndex:(int)index;
-(CGPoint)getCoordinatesForNodeAtIndex:(int)index;
- (void)updateTargetForIndex:(int)index;
- (void)clearHighlightLines;
-(void)highlightRoute:(NSArray*)nodeList;



@end
