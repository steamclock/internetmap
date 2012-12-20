//
//  Program.h
//  InternetMap
//
//  GLSL Shader program
//
#import <Foundation/Foundation.h>

// Attribute index (vertex attributes are all hard coded right now)
enum
{
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    ATTRIB_SIZE,
    NUM_ATTRIBUTES
};

@interface Program : NSObject

-(id)initWithName:(NSString*)name activeAttributes:(NSIndexSet*)attribs; // loads shaders from name.vsh and name.fsh in application bundle
-(id)initWithFragmentShaderName:(NSString*)fragmentName vertexShaderName:(NSString*)vertexName activeAttributes:(NSIndexSet*)attribs;// loads shaders from vertexName.vsh and fragmentName.fsh in application bundle

-(int)uniformForName:(NSString*)uniformName;
-(void)use;

@end
