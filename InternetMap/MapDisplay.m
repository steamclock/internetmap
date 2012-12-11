//
//  MapDisplay.m
//  InternetMap
//

#import "MapDisplay.h"
#import "Program.h"
#import <GLKit/GLKit.h>
#import "Camera.h"
#import "Lines.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

static const int MAX_NODES = 30000;

// GL vertex data for nodes
typedef struct {
    float x;
    float y;
    float z;
    float size;
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
} RawDisplayNode;

@interface DisplayNode ()

-(id)initWithDisplay:(MapDisplay*)display index:(NSUInteger)index;

@property (strong, nonatomic) MapDisplay* parent;
@property (nonatomic) NSUInteger index;

@end

@interface MapDisplay () {
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

@property (strong, nonatomic) EAGLContext *context;

@property (nonatomic) RawDisplayNode* lockedNodes;

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
    
    //glEnable(GL_DEPTH_TEST);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    
    glEnable(GL_POINT_SPRITE_OES);
    
    // setup vertex buffer for nodes
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glBufferData(GL_ARRAY_BUFFER, MAX_NODES * sizeof(RawDisplayNode), NULL, GL_DYNAMIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(RawDisplayNode), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_SIZE);
    glVertexAttribPointer(ATTRIB_SIZE, 1, GL_FLOAT, GL_FALSE, sizeof(RawDisplayNode), BUFFER_OFFSET(sizeof(float) * 3));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(RawDisplayNode), BUFFER_OFFSET(sizeof(float) * 4));
        
    glBindVertexArrayOES(0);
    
    self.camera = [Camera new];
}

- (void)tearDownGL
{
    self.nodeProgram = nil;
    self. connectionProgram = nil;
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    [self.camera update];
}

- (void)draw
{
    if(self.lockedNodes) {
        glUnmapBufferOES(GL_ARRAY_BUFFER);
        self.lockedNodes = NULL;
    }
    
    if( self.numNodes > MAX_NODES) {
        NSLog(@"Display node count is too high, need to increase limit");
        self.numNodes = MAX_NODES;
    }

    GLKMatrix4 mvp = [self.camera currentModelViewProjection];
    GLKMatrix4 mv = [self.camera currentModelView];
    GLKMatrix4 p = [self.camera currentProjection];
    
    glClearColor(0.05882f, 0.09411f, 0.25098f, 1.0f); //Visualization background color
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);

    [self.nodeProgram use];
    glUniformMatrix4fv([self.nodeProgram uniformForName:@"modelViewMatrix"], 1, 0, mv.m);
    glUniformMatrix4fv([self.nodeProgram uniformForName:@"projectionMatrix"], 1, 0, p.m);
    glUniform1f([self.nodeProgram uniformForName:@"maxSize"], ([[UIScreen mainScreen] scale] == 2.00) ? 150.0f : 75.0f);
    glUniform1f([self.nodeProgram uniformForName:@"screenWidth"], ([[UIScreen mainScreen] scale] == 2.00) ? self.camera.displaySize.width*2 : self.camera.displaySize.width);
    glUniform1f([self.nodeProgram uniformForName:@"screenHeight"], ([[UIScreen mainScreen] scale] == 2.00) ? self.camera.displaySize.height*2 : self.camera.displaySize.height);
    
    glDrawArrays(GL_POINTS, 0, self.numNodes);
    
    if(self.lines) {
        [self.connectionProgram use];
        glUniformMatrix4fv([self.connectionProgram uniformForName:@"modelViewProjectionMatrix"], 1, 0, mvp.m);
        [self.lines display];
    }
}

-(RawDisplayNode*)rawDisplayNodeAtIndex:(NSUInteger)index {
    if(!self.lockedNodes) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        self.lockedNodes = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    }
    
    return &self.lockedNodes[index];
}

-(DisplayNode*)displayNodeAtIndex:(NSUInteger)index {
    if(index >= MIN(self.numNodes, MAX_NODES)) {
        NSLog(@"trying to modify an invalid display node index");
        return NULL;
    }
    
    return [[DisplayNode alloc] initWithDisplay:self index:index];
}

@end


@implementation DisplayNode

-(id)initWithDisplay:(MapDisplay*)display index:(NSUInteger)index {
    if((self = [super init])) {
        self.parent = display;
        self.index = index;
    }
    
    return self;
}

-(void)setX:(float)x {
    [self.parent rawDisplayNodeAtIndex:self.index]->x = x;
}

-(void)setY:(float)y {
    [self.parent rawDisplayNodeAtIndex:self.index]->y = y;
}

-(void)setZ:(float)z {
    [self.parent rawDisplayNodeAtIndex:self.index]->z = z;
}

-(void)setSize:(float)size {
    [self.parent rawDisplayNodeAtIndex:self.index]->size = size;
}

-(void)setColor:(UIColor *)color {
    RawDisplayNode* node = [self.parent rawDisplayNodeAtIndex:self.index];
    float r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    node->r = (int)(r * 255.0f);
    node->g = (int)(g * 255.0f);
    node->b = (int)(b * 255.0f);
    node->a = (int)(a * 255.0f);
}

@end