//
//  MapControllerWrapper.m
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "MapControllerWrapper.h"
#include "MapController.hpp"


@interface MapControllerWrapper()

@property (nonatomic, readwrite, assign) MapController* controller;

@end


@implementation MapControllerWrapper

- (id)init {
    if (self = [super init]) {
        _controller = new MapController();
    }
    
    return self;
}

- (void)dealloc {
    delete _controller;
}


- (void)setAllowIdleAnimation:(BOOL)allow{

}

- (void)resetIdleTimer{

}
- (void)update:(NSTimeInterval)now{

}
- (void)draw{

}
- (void)zoomAnimated:(float)zoom duration:(NSTimeInterval)duration{

}
- (void)beginNodeUpdates{

}
- (void)endNodeUpdates{

}
- (void)setColor:(UIColor*)color forNodeAtIndex:(int)index{

}
- (void)stopMomentumPan{

}
- (void)rotateRadiansX:(float)rotate{

}
- (void)rotateRadiansY:(float)rotate{

}
- (void)rotateRadiansZ:(float)rotate{

}
- (void)startMomentumPanWithVelocity:(CGPoint)velocity{

}
- (void)startMomentumRotationWithVelocity:(float)velocity{

}
- (void)stopMomentumRotation{

}
- (void)stopMomentumZoom{

}
- (void)startMomentumZoomWithVelocity:(float)velocity{

}
- (void)zoomByScale:(float)scale{

}

- (NodeWrapper*)nodeByASN:(NSString*)asn{
    return nil;
}

- (void)rotateAnimated:(GLKMatrix4)matrix duration:(NSTimeInterval)duration{

}

- (void)handleTouchDownAtPoint:(CGPoint)point{

}
- (void)selectHoveredNode{

}
- (void)unhoverNode{

}
- (int)indexForNodeAtPoint:(CGPoint)pointInView{
    return 0;
}
- (NodeWrapper*)nodeAtIndex:(int)index{
    return nil;
}
-(CGPoint)getCoordinatesForNodeAtIndex:(int)index{
    return CGPointZero;
}
- (void)updateTargetForIndex:(int)index{

}
- (void)clearHighlightLines{

}
-(void)highlightRoute:(NSArray*)nodeList{

}



@end
