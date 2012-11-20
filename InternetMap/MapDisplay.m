//
//  MapDisplay.m
//  InternetMap
//

#import "MapDisplay.h"
#import "Program.h"
#import <GLKit/GLKit.h>

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
    unsigned char lineR;
    unsigned char lineG;
    unsigned char lineB;
    unsigned char lineA;
} RawDisplayNode;

@interface DisplayNode ()

-(id)initWithDisplay:(MapDisplay*)display index:(NSUInteger)index;

@property (strong, nonatomic) MapDisplay* parent;
@property (nonatomic) NSUInteger index;

@end

@interface MapDisplay () {
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _rotationMatrix;
    float _rotation;
    float _zoom;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

@property (strong, nonatomic) EAGLContext *context;

@property (nonatomic) RawDisplayNode* lockedNodes;
@property (strong, nonatomic) NSData* lineIndexData;

@property (strong, nonatomic) Program* nodeProgram;
@property (strong, nonatomic) Program* connectionProgram;

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
    self.nodeProgram = [[Program alloc] initWithName:@"node"];
    self.connectionProgram = [[Program alloc] initWithName:@"line"];
    
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
    
    glEnableVertexAttribArray(ATTRIB_LINECOLOR);
    glVertexAttribPointer(ATTRIB_LINECOLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(RawDisplayNode), BUFFER_OFFSET((sizeof(float) * 4) + 4));
    
    glBindVertexArrayOES(0);

    _rotationMatrix = GLKMatrix4Identity;
    _zoom = -3.0f;
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
    float aspect = fabsf(self.size.width / self.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);

    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, _zoom);
    baseModelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, _rotationMatrix);

    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, baseModelViewMatrix);
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

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);

    [self.nodeProgram use];
    glUniformMatrix4fv([self.nodeProgram uniformForName:@"modelViewProjectionMatrix"], 1, 0, _modelViewProjectionMatrix.m);
    glUniform1f([self.nodeProgram uniformForName:@"maxSize"], ([[UIScreen mainScreen] scale] == 2.00) ? 50.0f : 25.0f);
    
    glDrawArrays(GL_POINTS, 0, self.numNodes);
    
    [self.connectionProgram use];
    glUniformMatrix4fv([self.connectionProgram uniformForName:@"modelViewProjectionMatrix"], 1, 0, _modelViewProjectionMatrix.m);
    glDrawElements(GL_LINES, self.lineIndexData.length / 2, GL_UNSIGNED_SHORT, self.lineIndexData.bytes);
}



-(void) rotateRadiansX:(float)rotate {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 1.0f, 0.0f), _rotationMatrix);
}

-(void) rotateRadiansY:(float)rotate {
    _rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 1.0f, 0.0f, 0.0f), _rotationMatrix);
}

-(void) zoom:(float)zoom {
    _zoom += zoom * -_zoom;
    
    if(_zoom > -0.2) {
        _zoom = -0.2;
    }
    
    if(_zoom < -10.0f) {
        _zoom = -10.0f;
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

-(void)setLineIndices:(NSArray*)lineIndices {
    GLushort* rawData = alloca(lineIndices.count * sizeof(GLushort));
    
    for(int i = 0; i < lineIndices.count; i++) {
        rawData[i] = [[lineIndices objectAtIndex:i] intValue];
    }
    
    self.lineIndexData = [NSData dataWithBytes:rawData length:lineIndices.count * sizeof(GLushort)];
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

-(void)setLineColor:(UIColor *)color {
    RawDisplayNode* node = [self.parent rawDisplayNodeAtIndex:self.index];
    float r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    node->lineR = (int)(r * 255.0f);
    node->lineG = (int)(g * 255.0f);
    node->lineB = (int)(b * 255.0f);
    node->lineA = (int)(a * 255.0f);
}

@end