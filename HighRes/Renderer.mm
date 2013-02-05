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
@property float captureWidth;
@property float captureHeight;
@property GLuint fbo;
@end

@implementation Renderer

-(id)init {
    if((self = [super init])) {
        self.mapController = new MapController;
        _mapController->updateDisplay(false);
        _mapController->display->camera->setAllowIdleAnimation(true);
                
        self.captureHeight = self.captureWidth = 4096;
        
        self.fbo = [self buildFBOWithWidth:self.captureWidth andHeight:self.captureHeight];
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

    if(self.screenshot) {
        GLint maxDims[2];
        glGetIntegerv(GL_MAX_VIEWPORT_DIMS, maxDims);
        int axisDivisions = maxDims[0] / self.captureWidth;
                
        glBindFramebuffer(GL_FRAMEBUFFER, self.fbo);
        
        glViewport(0,0,self.captureWidth, self.captureHeight);
        self.mapController->display->camera->setDisplaySize(1024, 1024);
        self.mapController->display->setDisplayScale(self.captureHeight/1024);
        self.mapController->display->draw();
        NSString* filename = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"InternetMap/master.png"]];
        [self captureImageToFile:filename];
        
        self.mapController->display->setDisplayScale(maxDims[0]/1024);
        
        for(int y = 0; y < axisDivisions; y++) {
            for(int x = 0; x < axisDivisions; x++) {
                glViewport(-(x * self.captureWidth), -(y * self.captureHeight), self.captureWidth * axisDivisions, self.captureHeight * axisDivisions);
                self.mapController->display->draw();
                NSString* filename = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"InternetMap/tile%.2d.png",(y * axisDivisions) + x]];
                [self captureImageToFile:filename];
            }
        }
        
        self.mapController->display->camera->setDisplaySize(self.width, self.height);
        self.mapController->display->setDisplayScale(1.0f);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glViewport(0,0,self.width, self.width);
        self.screenshot = nil;

    }
    else {
        self.mapController->display->draw();
    }
    
    
    
    if(self.screenshot) {
    }
}

-(GLuint) buildFBOWithWidth:(GLuint)width andHeight:(GLuint) height
{
	GLuint fboName;
	
	GLuint colorTexture;
	
	// Create a texture object to apply to model
	glGenTextures(1, &colorTexture);
	glBindTexture(GL_TEXTURE_2D, colorTexture);
	
	// Set up filter and wrap modes for this texture object
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
#if ESSENTIAL_GL_PRACTICES_IOS
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
#else
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
#endif
	
	// Allocate a texture image with which we can render to
	// Pass NULL for the data parameter since we don't need to load image data.
	//     We will be generating the image by rendering to this texture
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
				 width, height, 0,
				 GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	
	GLuint depthRenderbuffer;
	glGenRenderbuffers(1, &depthRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
	
	glGenFramebuffers(1, &fboName);
	glBindFramebuffer(GL_FRAMEBUFFER, fboName);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTexture, 0);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		return 0;
	}

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
	return fboName;
}

-(void)captureImageToFile:(NSString*)filename {
    float width = self.captureWidth;
    float height = self.captureHeight;
    
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
