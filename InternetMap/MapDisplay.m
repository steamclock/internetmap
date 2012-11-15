//
//  MapDisplay.m
//  InternetMap
//

#import "MapDisplay.h"
#import <GLKit/GLKit.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

static const int MAX_NODES = 30000;

// GL vertex data for nodes
typedef struct {
    float x;
    float y;
    float z;
    float size;
} RawDisplayNode;

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_SIZE,
    NUM_ATTRIBUTES
};

@interface DisplayNode ()

-(id)initWithDisplay:(MapDisplay*)display index:(NSUInteger)index;

@property (strong, nonatomic) MapDisplay* parent;
@property (nonatomic) NSUInteger index;

@end

@interface MapDisplay () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _rotationMatrix;
    float _rotation;
    float _zoom;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
}

@property (strong, nonatomic) EAGLContext *context;

@property (nonatomic) RawDisplayNode* lockedNodes;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
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
    [self loadShaders];
    
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
    
    glBindVertexArrayOES(0);

    _rotationMatrix = GLKMatrix4Identity;
    _zoom = -3.0f;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
        
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
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
    
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    
    glDrawArrays(GL_POINTS, 0, self.numNodes);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"node" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"node" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_SIZE, "size");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
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

@end


@implementation DisplayNode

-(id)initWithDisplay:(MapDisplay*)display index:(NSUInteger)index {
    if((self = [super init])) {
        self.parent = display;
        self.index = index;
    }
    
    return self;
}

-(float)x {
    return [self.parent rawDisplayNodeAtIndex:self.index]->x;
}

-(void)setX:(float)x {
    [self.parent rawDisplayNodeAtIndex:self.index]->x = x;
}

-(float)y {
    return [self.parent rawDisplayNodeAtIndex:self.index]->y;
}

-(void)setY:(float)y {
    [self.parent rawDisplayNodeAtIndex:self.index]->y = y;
}

-(float)z {
    return [self.parent rawDisplayNodeAtIndex:self.index]->z;
}

-(void)setZ:(float)z {
    [self.parent rawDisplayNodeAtIndex:self.index]->z = z;
}

-(float)size {
    return [self.parent rawDisplayNodeAtIndex:self.index]->size;
}

-(void)setSize:(float)size {
    [self.parent rawDisplayNodeAtIndex:self.index]->size = size;
}


@end