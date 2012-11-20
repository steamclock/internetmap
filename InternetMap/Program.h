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
    ATTRIB_SIZE,
    ATTRIB_COLOR,
    ATTRIB_LINECOLOR,
    NUM_ATTRIBUTES
};

@interface Program : NSObject

-(id)initWithName:(NSString*)name; // loads shaders from name.vsh and name.fsh in applicaiton bundle

-(int)uniformForName:(NSString*)uniformName;
-(void)use;

@end
