//
//  MapControllerWrapper.m
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "MapControllerWrapper.h"
#include "MapController.hpp"
#include "Camera.hpp"


//TODO: move these to a better place
std::string loadTextResource(std::string base, std::string extension) {
    NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithCString:base.c_str() encoding:NSUTF8StringEncoding] ofType:[NSString stringWithCString:extension.c_str() encoding:NSUTF8StringEncoding]];
    NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if(!contents) {
        return std::string("");
    }
    else {
        return std::string([contents UTF8String]);
    }
}

bool deviceIsOld() {
    return [HelperMethods deviceIsOld];
}

@interface MapControllerWrapper()

@property (nonatomic, readwrite, assign) MapController* controller;

@end


@implementation MapControllerWrapper

- (id)init {
    if (self = [super init]) {
        _controller = new MapController();
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"];
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
        _controller->data->loadFromString(std::string([fileContents UTF8String]));
        filePath = [[NSBundle mainBundle] pathForResource:@"as2attr" ofType:@"txt"];
        fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
        _controller->data->loadFromAttrString(std::string([fileContents UTF8String]));
        
        _controller->display->setDisplayScale([[UIScreen mainScreen] scale]);
        _controller->data->updateDisplay(_controller->display);
        
    }
    
    return self;
}

- (void)dealloc {
    delete _controller;
}

- (void)setDisplaySize:(CGSize)displaySize {
    _controller->display->camera->setDisplaySize(displaySize.width, displaySize.height);
}

- (void)setAllowIdleAnimation:(BOOL)allow{
    
}

- (void)resetIdleTimer{

}
- (void)update:(NSTimeInterval)now{
    _controller->display->camera->update(now);
}
- (void)draw{
    _controller->display->draw();
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
