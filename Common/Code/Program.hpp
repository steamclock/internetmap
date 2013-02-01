//
//  Program.h
//  InternetMap
//
//  GLSL Shader program
//

#ifndef InternetMap_Program_hpp
#define InternetMap_Program_hpp

#include <string>

// Attribute index (vertex attributes are all hard coded right now)
enum
{
    ATTRIB_POSITION = 0,
    ATTRIB_COLOR,
    ATTRIB_SIZE,
    ATTRIB_POSITIONTARGET,
    ATTRIB_COLORTARGET,
    ATTRIB_SIZETARGET,
    NUM_ATTRIBUTES
};

#define ATTRIB_MASK(x) (1 << x)
static const int VERTEX_LINE = ATTRIB_MASK(ATTRIB_POSITION) | ATTRIB_MASK(ATTRIB_COLOR);
static const int VERTEX_NODE = ATTRIB_MASK(ATTRIB_POSITION) | ATTRIB_MASK(ATTRIB_COLOR) | ATTRIB_MASK(ATTRIB_SIZE);
static const int VERTEX_BLEND_NODE = ATTRIB_MASK(ATTRIB_POSITION) | ATTRIB_MASK(ATTRIB_COLOR) | ATTRIB_MASK(ATTRIB_SIZE) | ATTRIB_MASK(ATTRIB_POSITIONTARGET) | ATTRIB_MASK(ATTRIB_COLORTARGET) | ATTRIB_MASK(ATTRIB_SIZETARGET);

class Program {
    unsigned int _program;
    unsigned int _activeAttributesMask;
    
    void setup(const std::string& fragmentName, const std::string& vertexName, unsigned int attribMask);
    bool compileShader(unsigned int* shader, unsigned int type, const std::string& file);
    bool linkProgram(unsigned int program);
    bool validateProgram(unsigned int program);
    
public:
    
    Program(const std::string& name, unsigned int attributes);
    Program(const std::string& fragmentName, const std::string& vertexName, unsigned int attributes);
    ~Program();
    
    int uniformForName(const std::string& name);
    void bind(void);
};

#endif
