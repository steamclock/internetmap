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
    
    bool compileShader(unsigned int* shader, unsigned int type, std::string file);
    bool linkProgram(unsigned int program);
    bool validateProgram(unsigned int program);
    
public:
    
    Program(std::string name, unsigned int attributes);
    Program(std::string fragmentName, std::string vertexName, unsigned int attributes);
    ~Program();
    
    int uniformForName(std::string name);
    void bind(void);
};

#endif
