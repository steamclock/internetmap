//
//  Lines.m
//  InternetMap
//

#import "Lines.h"
#import "Program.h"

typedef struct {
    float x;
    float y;
    float z;
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char a;
} LineVertex;

@interface Lines ()
@property NSUInteger count;
@property GLuint vertexArray;
@property GLuint vertexBuffer;
@property LineVertex* lockedVertices;
@end

@implementation Lines

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

-(id)initWithLineCount:(NSUInteger)count {
    if((self = [super init])) {
        self.count = count;
        
        glGenVertexArraysOES(1, &_vertexArray);
        glBindVertexArrayOES(_vertexArray);
        
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        
        glBufferData(GL_ARRAY_BUFFER, count * 2 * sizeof(LineVertex), NULL, GL_DYNAMIC_DRAW);
        
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(LineVertex), BUFFER_OFFSET(0));
        
        glEnableVertexAttribArray(ATTRIB_COLOR);
        glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(LineVertex), BUFFER_OFFSET(sizeof(float) * 3));
        
        glBindVertexArrayOES(0);
    }
    
    return self;
}

-(void)dealloc {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
}

-(void)beginUpdate {
    if(!self.lockedVertices) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        self.lockedVertices = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    }
}

-(void)endUpdate {
    self.lockedVertices = NULL;
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glUnmapBufferOES(GL_ARRAY_BUFFER);
}

-(void)updateLine:(NSUInteger)index withStart:(GLKVector3)start startColor:(UIColor*)startColour end:(GLKVector3)end endColor:(UIColor*)endColor {
    if(index >= self.count) {
        return;
    }
    
    LineVertex* vert0 = &self.lockedVertices[index * 2];
    LineVertex* vert1 = &self.lockedVertices[index * 2 + 1];
    
    vert0->x = start.x;
    vert0->y = start.y;
    vert0->z = start.z;
    vert1->x = end.x;
    vert1->y = end.y;
    vert1->z = end.z;
    
    float r,g,b,a;
    [startColour getRed:&r green:&g blue:&b alpha:&a];
    vert0->r = (int)(r * 255.0f);
    vert0->g = (int)(g * 255.0f);
    vert0->b = (int)(b * 255.0f);
    vert0->a = (int)(a * 255.0f);
    
    [endColor getRed:&r green:&g blue:&b alpha:&a];
    vert1->r = (int)(r * 255.0f);
    vert1->g = (int)(g * 255.0f);
    vert1->b = (int)(b * 255.0f);
    vert1->a = (int)(a * 255.0f);
}

-(void)display {
    glBindVertexArrayOES(_vertexArray);
    glDrawArrays(GL_LINES, 0, self.count * 2);
}

@end
