//
//  Program.m
//  InternetMap
//
//  Created by Nigel Brooke on 2012-11-19.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#include "Program.hpp"
#include "OpenGL.hpp"

// TODO: clean this up
std::string loadTextResource(std::string base, std::string extension);

Program::Program(std::string name, unsigned int attributes)  :
    _program(0),
    _activeAttributes(0)
{
    setup(name, name, attributes);
}

Program::Program(std::string fragmentName, std::string vertexName, unsigned int attributes) :
    _program(0),
    _activeAttributes(0)
{
    setup(fragmentName, vertexName, attributes);
}

void Program::setup(std::string fragmentName, std::string vertexName, unsigned int attributes) {
    GLuint vertShader, fragShader;
    
    _activeAttributes = attributes;
    
    // Create and compile vertex shader.
    std::string vertShaderCode = loadTextResource(vertexName, "vsh");
    if (!compileShader(&vertShader,GL_VERTEX_SHADER,vertShaderCode)) {
        LOG("Failed to compile vertex shader");
        return;
    }
    
    // Create and compile fragment shader.
    std::string frahShaderCode = loadTextResource(fragmentName, "fsh");
    if (!compileShader(&fragShader,GL_FRAGMENT_SHADER,frahShaderCode)) {
        LOG("Failed to compile fragment shader");
        return;
    }
    
    // Create shader program.
    _program = glCreateProgram();

    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    if(_activeAttributes & ATTRIB_VERTEX) {
        glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    }
    
    if(_activeAttributes & ATTRIB_SIZE) {
        glBindAttribLocation(_program, ATTRIB_SIZE, "size");
    }
    
    if(_activeAttributes & ATTRIB_COLOR) {
        glBindAttribLocation(_program, ATTRIB_COLOR, "color");
    }
    
    // Link program.
    if (!linkProgram(_program)) {
        LOG("Failed to link program: %d", _program);
        
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
        
        return;
    }
    
    LOG("Compiled shader %s/%s", fragmentName.c_str(), vertexName.c_str());

    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
}

Program::~Program() {
    if(_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

int Program::uniformForName(std::string name) {
    return glGetUniformLocation(_program, name.c_str());
}

void Program::bind() {
    glUseProgram(_program);
}

#pragma mark - Shader compilation helpers

bool Program::compileShader(unsigned int* shader, unsigned int type, std::string code)
{
    GLint status;
    const GLchar *source = code.c_str();
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        printf("Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return false;
    }
    
    return true;
}

bool Program::linkProgram(GLuint prog) {
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}

bool Program::validateProgram(GLuint prog) {
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}
