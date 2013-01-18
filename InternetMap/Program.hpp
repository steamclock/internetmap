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
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
    ATTRIB_SIZE,
    NUM_ATTRIBUTES
};

class Program {
    unsigned int _program;
    unsigned int _activeAttributes;
    
    void setup(const std::string& fragmentName, const std::string& vertexName, unsigned int attributes);
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
