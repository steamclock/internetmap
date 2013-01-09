//
//  MapDisplay.m
//  InternetMap
//

#import "MapDisplay.h"
#import "Program.h"
#import <GLKit/GLKit.h>
#import "Camera.hpp"
#import "Lines.hpp"
#import "Nodes.h"

@interface MapDisplay () {
    
}

@property (strong, nonatomic) EAGLContext *context;

@property (strong, nonatomic) Program* nodeProgram;
@property (strong, nonatomic) Program* selectedNodeProgram;
@property (strong, nonatomic) Program* connectionProgram;

@property (nonatomic, readwrite) std::shared_ptr<Camera> camera;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation MapDisplay

- (id)init
{
    if((self = [super init])) {
        [self setupGL];
    }
    
    return self;
}

- (void)dealloc
{    
    [self tearDownGL];
}

- (void)setupGL
{
    NSMutableIndexSet* nodeVertexComponents = [NSMutableIndexSet new];
    [nodeVertexComponents addIndex:ATTRIB_VERTEX];
    [nodeVertexComponents addIndex:ATTRIB_COLOR];
    [nodeVertexComponents addIndex:ATTRIB_SIZE];
    
    NSMutableIndexSet* lineVertexComponents = [NSMutableIndexSet new];
    [lineVertexComponents addIndex:ATTRIB_VERTEX];
    [lineVertexComponents addIndex:ATTRIB_COLOR];
    
    self.nodeProgram = [[Program alloc] initWithName:@"node" activeAttributes:nodeVertexComponents];
    self.selectedNodeProgram = [[Program alloc] initWithFragmentShaderName:@"selectedNode" vertexShaderName:@"node" activeAttributes:nodeVertexComponents];
    self.connectionProgram = [[Program alloc] initWithName:@"line" activeAttributes:lineVertexComponents];
    
    self.camera = std::shared_ptr<Camera>(new Camera());
}

- (void)tearDownGL
{
    self.nodeProgram = nil;
    self.connectionProgram = nil;
    
    [EAGLContext setCurrentContext:self.context];
    self.nodes = nil;
    self.selectedNodes = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.camera->update([NSDate timeIntervalSinceReferenceDate]);
}

- (void)draw
{
    GLKMatrix4 mvp = self.camera->currentModelViewProjection();
    GLKMatrix4 mv = self.camera->currentModelView();
    GLKMatrix4 p = self.camera->currentProjection();
    
    glClearColor(0, 0, 0, 1.0f); //Visualization background color
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.selectedNodeProgram use];
    glUniformMatrix4fv([self.selectedNodeProgram uniformForName:@"modelViewMatrix"], 1, 0, mv.m);
    glUniformMatrix4fv([self.selectedNodeProgram uniformForName:@"projectionMatrix"], 1, 0, p.m);
    glUniform1f([self.selectedNodeProgram uniformForName:@"maxSize"], ([[UIScreen mainScreen] scale] == 2.00) ? 150.0f : 75.0f);
    glUniform1f([self.selectedNodeProgram uniformForName:@"screenWidth"], [HelperMethods deviceIsRetina] ? self.camera->displayWidth()*2 : self.camera->displayWidth());
    glUniform1f([self.selectedNodeProgram uniformForName:@"screenHeight"], [HelperMethods deviceIsRetina] ? self.camera->displayHeight()*2 : self.camera->displayHeight());
    
    glEnable(GL_DEPTH_TEST); //enable z testing and writing
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    if (self.selectedNodes) {
        [self.selectedNodes display];
    }
    
    [self.nodeProgram use];
    glUniformMatrix4fv([self.nodeProgram uniformForName:@"modelViewMatrix"], 1, 0, mv.m);
    glUniformMatrix4fv([self.nodeProgram uniformForName:@"projectionMatrix"], 1, 0, p.m);
    glUniform1f([self.nodeProgram uniformForName:@"maxSize"], [HelperMethods deviceIsRetina] ? 150.0f : 75.0f);
    glUniform1f([self.nodeProgram uniformForName:@"minSize"], 2.0f);
    glUniform1f([self.selectedNodeProgram uniformForName:@"screenWidth"], [HelperMethods deviceIsRetina] ? self.camera->displayWidth()*2 : self.camera->displayWidth());
    glUniform1f([self.selectedNodeProgram uniformForName:@"screenHeight"], [HelperMethods deviceIsRetina] ? self.camera->displayHeight()*2 : self.camera->displayHeight());
    
    glBlendFunc(GL_ONE, GL_ONE);
    glDepthMask(GL_FALSE); //disable z writing only
    if (self.nodes) {
        [self.nodes display];
    }
    
    if(self.visualizationLines || self.highlightLines) {
        [self.connectionProgram use];
        glUniformMatrix4fv([self.connectionProgram uniformForName:@"modelViewProjectionMatrix"], 1, 0, mvp.m);
    }
    
    if(self.visualizationLines && ![HelperMethods deviceIsOld]) { // No lines on 3GS, iPod 3rd Gen or iPad 1
        self.visualizationLines->display();
    }

    if(self.highlightLines) {
        self.highlightLines->display();
    }
    
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    
}





@end


