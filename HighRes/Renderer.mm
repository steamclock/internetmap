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
@property (strong) NSString* screenshot;
@property float width;
@property float height;
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
    self.width = width;
    self.height = height;
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
    
    if(self.screenshot) {
        [self captureImageToFile:self.screenshot];
        self.screenshot = nil;
    }
}

-(void)captureImageToFile:(NSString*)filename {
    float width = self.width;
    float height = self.height;
    
    GLvoid *imageData = malloc(width*height*4);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    CGDataProviderRef dataProviderRef = CGDataProviderCreateWithData(NULL, imageData, width*height*4, nil);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(width, height, 8 /* bits per component*/, 32 /* bits per pixel*/, width * 4, colorSpaceRef, kCGBitmapByteOrderDefault, dataProviderRef,    NULL, NO, kCGRenderingIntentDefault);
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filename];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, imageRef, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", filename);
    }
    
    CFRelease(destination);
    
    CGDataProviderRelease(dataProviderRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    free(imageData);
}

-(void)screenshot:(NSString*)filename {
    self.screenshot = filename;
}

@end
