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
@property float rotateX;
@property float rotateY;
@property float zoom;
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

-(void)rotateRadiansX:(float)x radiansY:(float)y {
    self.rotateX += x;
    self.rotateY += y;
}

-(void)zoom:(float)zoom {
    self.zoom += zoom;
}


-(void)display {
    float time = [NSDate timeIntervalSinceReferenceDate];
    
    if(self.rotateX != 0.0f) {
        self.mapController->display->camera->rotateRadiansX(self.rotateX);
        self.rotateX = 0.0;
    }
    
    if(self.rotateY != 0.0f) {
        self.mapController->display->camera->rotateRadiansY(self.rotateY);
        self.rotateY = 0.0;
    }
    
    if(self.zoom != 0.0f) {
        self.mapController->display->camera->zoomByScale(self.zoom);
        self.zoom = 0.0;
    }
    
    self.mapController->update(time);
    self.mapController->display->draw();
}

@end
