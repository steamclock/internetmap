//
//  Nodes.m
//  InternetMap
//
//  Created by Alexander on 17.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

static const int MAX_NODES = 30000;

#import "Nodes.h"
#import "Program.h"

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

@interface Nodes ()
@property NSUInteger count;
@property GLuint vertexArray;
@property GLuint vertexBuffer;
@property (nonatomic) RawDisplayNode* lockedNodes;
@end


@implementation Nodes

-(void)dealloc {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
}

-(id)initWithNodeCount:(NSUInteger)count {
    if((self = [super init])) {
        self.count = count;
        
        glEnable(GL_BLEND);
        
        glEnable(GL_POINT_SPRITE_OES);
        glEnable(GL_POINT_SMOOTH);

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
    }
    
    return self;
}


- (void)display {

    if(self.lockedNodes) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glUnmapBufferOES(GL_ARRAY_BUFFER);
        self.lockedNodes = NULL;
    }
    
    if( self.count > MAX_NODES) {
        NSLog(@"Display node count is too high, need to increase limit");
        self.count = MAX_NODES;
    }

    
    glBindVertexArrayOES(_vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glDrawArrays(GL_POINTS, 0, self.count);

}



-(void)beginUpdate {
    if(!self.lockedNodes) {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        self.lockedNodes = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    }
}

-(void)endUpdate {
    self.lockedNodes = NULL;
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glUnmapBufferOES(GL_ARRAY_BUFFER);
}

-(void)updateNode:(NSUInteger)index position:(GLKVector3)pos {
    RawDisplayNode* node = &self.lockedNodes[index];
    
    node->x = pos.x;
    node->y = pos.y;
    node->z = pos.z;

}

-(void)updateNode:(NSUInteger)index size:(float)size {

    RawDisplayNode* node = &self.lockedNodes[index];
    
    node->size = size;

}

-(void)updateNode:(NSUInteger)index color:(UIColor*)color {
    RawDisplayNode* node = &self.lockedNodes[index];

    float r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    node->r = (int)(r * 255.0f);
    node->g = (int)(g * 255.0f);
    node->b = (int)(b * 255.0f);
    node->a = (int)(a * 255.0f);

}

-(void)updateNode:(NSUInteger)index position:(GLKVector3)pos size:(float)size color:(UIColor*)color {
    
    [self updateNode:index position:pos];
    [self updateNode:index size:size];
    [self updateNode:index color:color];
    
    
}


@end
