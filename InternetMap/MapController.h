//
//  MapController.h
//  InternetMap
//
//  Created by Alexander on 07.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MapData;
@class MapDisplay;

@interface MapController : NSObject

@property (nonatomic, strong) MapDisplay* display;
@property (nonatomic, strong) MapData* data;
@property (nonatomic) NSUInteger targetNode;
@property (nonatomic) int hoveredNodeIndex;
@property (strong, nonatomic) NSMutableIndexSet* highlightedNodes;
@property (strong) NSString* lastSearchIP;

- (void)unhoverNode;
- (void)updateTargetForIndex:(int)index;
- (void)handleTouchDownAtPoint:(CGPoint)point;
- (void)selectHoveredNode;
- (int)indexForNodeAtPoint:(CGPoint)pointInView;
-(CGPoint)getCoordinatesForNodeAtIndex:(int)index;
- (void)clearHighlightLines;
-(void)highlightRoute:(NSArray*)nodeList;

@end