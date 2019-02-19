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



@property (nonatomic) unsigned int targetNode;
@property (nonatomic) CGSize logicalDisplaySize;
@property (nonatomic) CGSize physicalDisplaySize;
@property (nonatomic, readonly) float currentZoom;
@property (nonatomic, strong) NSString* lastSearchIP;


- (void)setAllowIdleAnimation:(BOOL)allow;
- (void)resetIdleTimer;
- (void)update:(NSTimeInterval)now;
- (void)draw;
- (void)translateYAnimated:(float)translateY duration:(NSTimeInterval)duration;
- (void)zoomAnimated:(float)zoom duration:(NSTimeInterval)duration;
- (void)stopMomentumPan;
- (void)resetZoomAndRotationAnimatedForOrientation:(BOOL)isPortraitMode;
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
- (BOOL) isWithinMaxNodeIndex:(int)index;
- (void)rotateAnimated:(GLKMatrix4)matrix duration:(NSTimeInterval)duration;
- (NSMutableArray*)allNodes;

- (void)handleTouchDownAtPoint:(CGPoint)point;
- (BOOL)selectHoveredNode;
- (void)unhoverNode;
- (void)deselectCurrentNode;
- (void)hoverNode:(int)index;
- (int)indexForNodeAtPoint:(CGPoint)pointInView;
- (NodeWrapper*)nodeAtIndex:(int)index;
-(CGPoint)getCoordinatesForNodeAtIndex:(int)index;
- (void)updateTargetForIndex:(int)index;
- (void)clearHighlightLines;
- (void)highlightRoute:(NSArray*)nodeList;
- (void)setTimelinePoint:(NSString*)timelinePointName;

- (NSArray*)visualizationNames;
- (void)setVisualization:(int)vis;

- (void)overrideCameraTransform:(matrix_float4x4)transform projection:(matrix_float4x4)projection modelPos:(GLKVector3)modelPos;
- (void)clearCameraOverride;

- (void)enableAR:(BOOL)enable;

- (float)nearPlane;
- (float)farPlane;

@end
