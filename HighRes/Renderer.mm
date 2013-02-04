//
//  Renderer.m
//  HighRes
//

#import "Renderer.h"
#include "MapController.hpp"
#include "Camera.hpp"
#include <string>

void cameraMoveFinishedCallback(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraMovementFinished" object:nil];
}

void lostSelectedNodeCallback(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lostSelectedNode" object:nil];
}

void loadTextResource(std::string* resource, const std::string& base, const std::string& extension) {
    NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithCString:base.c_str() encoding:NSUTF8StringEncoding] ofType:[NSString stringWithCString:extension.c_str() encoding:NSUTF8StringEncoding]];
    NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if(!contents) {
        *resource = "";
    }
    else {
        *resource = [contents UTF8String];
    }
}

bool deviceIsOld(void) {
    return false;
}

@interface Renderer ()
@property MapController* mapController;

@end

@implementation Renderer

-(id)init {
    if((self = [super init])) {
        self.mapController = new MapController;
        _mapController->updateDisplay(false);
        _mapController->display->camera->setAllowIdleAnimation(true);
    }
    return self;
}

-(void)dealloc {
    delete self.mapController;
    self.mapController = NULL;
}

-(void)resizeWithWidth:(float)width andHeight:(float)height {
    self.mapController->display->camera->setDisplaySize(width, height);
}

-(void)display {
    float time = [NSDate timeIntervalSinceReferenceDate];
    self.mapController->update(time);
    self.mapController->display->draw();
}

@end
