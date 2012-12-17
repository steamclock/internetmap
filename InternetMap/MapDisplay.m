//
//  MapDisplay.m
//  InternetMap
//

#import "MapDisplay.h"
#import "Program.h"
#import <GLKit/GLKit.h>
#import "Camera.h"
#import "Lines.h"
#import "Nodes.h"

@interface MapDisplay () {
    
}

@property (strong, nonatomic) EAGLContext *context;

@property (strong, nonatomic) Program* nodeProgram;
@property (strong, nonatomic) Program* connectionProgram;

@property (strong, nonatomic, readwrite) Camera* camera;

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
    self.connectionProgram = [[Program alloc] initWithName:@"line" activeAttributes:lineVertexComponents];
    
    

    
    self.camera = [Camera new];
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
    [self.camera update];
}

- (void)draw
{


    GLKMatrix4 mvp = [self.camera currentModelViewProjection];
    GLKMatrix4 mv = [self.camera currentModelView];
    GLKMatrix4 p = [self.camera currentProjection];
    
    glClearColor(0.05882f, 0.09411f, 0.25098f, 1.0f); //Visualization background color
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    

    [self.nodeProgram use];
    glUniformMatrix4fv([self.nodeProgram uniformForName:@"modelViewMatrix"], 1, 0, mv.m);
    glUniformMatrix4fv([self.nodeProgram uniformForName:@"projectionMatrix"], 1, 0, p.m);
    glUniform1f([self.nodeProgram uniformForName:@"maxSize"], ([[UIScreen mainScreen] scale] == 2.00) ? 150.0f : 75.0f);
    glUniform1f([self.nodeProgram uniformForName:@"screenWidth"], ([[UIScreen mainScreen] scale] == 2.00) ? self.camera.displaySize.width*2 : self.camera.displaySize.width);
    glUniform1f([self.nodeProgram uniformForName:@"screenHeight"], ([[UIScreen mainScreen] scale] == 2.00) ? self.camera.displaySize.height*2 : self.camera.displaySize.height);
    
    glEnable(GL_DEPTH_TEST);
    if (self.selectedNodes) {
        [self.selectedNodes display];
    }
    
    glDepthMask(GL_FALSE);
    if (self.nodes) {
        [self.nodes display];
    }
    
    
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);


    if(self.visualizationLines || self.highlightLines) {
        [self.connectionProgram use];
        glUniformMatrix4fv([self.connectionProgram uniformForName:@"modelViewProjectionMatrix"], 1, 0, mvp.m);
    }
    
    if(self.visualizationLines) {
        [self.visualizationLines display];
    }

    if(self.highlightLines) {
        glLineWidth(([[UIScreen mainScreen] scale] == 2.00) ? 6.0 : 3.0);
        [self.highlightLines display];
        glLineWidth(1.0f);
    }
}





@end


