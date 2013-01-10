//
//  MapDisplay.m
//  InternetMap
//

#import "MapDisplay.h"
#import <GLKit/GLKit.h>
#import "Camera.hpp"
#import "Lines.hpp"
#import "Nodes.h"

#include "Program.hpp"

@interface MapDisplay () {
    
}

@property (strong, nonatomic) EAGLContext *context;

@property (nonatomic) std::shared_ptr<Program> nodeProgram;
@property (nonatomic) std::shared_ptr<Program> selectedNodeProgram;
@property (nonatomic) std::shared_ptr<Program> connectionProgram;

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
    
    self.nodeProgram = std::shared_ptr<Program>(new Program("node", ATTRIB_VERTEX | ATTRIB_COLOR | ATTRIB_SIZE));
    self.selectedNodeProgram = std::shared_ptr<Program>(new Program("selectedNode", "node", ATTRIB_VERTEX | ATTRIB_COLOR | ATTRIB_SIZE));
    self.connectionProgram = std::shared_ptr<Program>(new Program("line", ATTRIB_VERTEX | ATTRIB_COLOR));

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

- (void)bindDefaultNodeUniforms:(std::shared_ptr<Program>)program {
    Matrix4 mv = self.camera->currentModelView();
    Matrix4 p = self.camera->currentProjection();
    glUniformMatrix4fv(program->uniformForName("modelViewMatrix"), 1, 0, reinterpret_cast<float*>(&mv));
    glUniformMatrix4fv(program->uniformForName("projectionMatrix"), 1, 0, reinterpret_cast<float*>(&p));
    glUniform1f(program->uniformForName("maxSize"), ([HelperMethods deviceIsRetina] ? 150.0f : 75.0f));
    glUniform1f(program->uniformForName("screenWidth"), [UIScreen mainScreen].scale * self.camera->displayWidth());
    glUniform1f(program->uniformForName("screenHeight"), [UIScreen mainScreen].scale * self.camera->displayHeight());
}

- (void)draw
{
    glClearColor(0, 0, 0, 1.0f); //Visualization background color
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_DEPTH_TEST); //enable z testing and writing

    if (self.selectedNodes) {
        self.selectedNodeProgram->bind();
        [self bindDefaultNodeUniforms:self.selectedNodeProgram];
        
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        [self.selectedNodes display];
    }
    
    glBlendFunc(GL_ONE, GL_ONE);
    glDepthMask(GL_FALSE); //disable z writing only
    
    if (self.nodes) {
        self.nodeProgram->bind();
        [self bindDefaultNodeUniforms:self.nodeProgram];
        glUniform1f(self.nodeProgram->uniformForName("minSize"), 2.0f);
        [self.nodes display];
    }
    
    Matrix4 mvp = self.camera->currentModelViewProjection();

    if(self.visualizationLines || self.highlightLines) {
        self.connectionProgram->bind();
        glUniformMatrix4fv(self.connectionProgram->uniformForName("modelViewProjectionMatrix"), 1, 0, reinterpret_cast<float*>(&mvp));
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


