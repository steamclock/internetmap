//
//  Program.m
//  InternetMap
//
//  Created by Nigel Brooke on 2012-11-19.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#include "Program.hpp"
#include "OpenGL.hpp"
#include "Types.hpp"
#include <stdlib.h>

// TODO: clean this up
void loadTextResource(std::string* resource, const std::string& base, const std::string& extension);

Program::Program(const std::string& name, unsigned int attributes)  :
    _program(0),
    _activeAttributesMask(0)
{
    setup(name, name, attributes);
}

Program::Program(const std::string& fragmentName, const std::string& vertexName, unsigned int attributes) :
    _program(0),
    _activeAttributesMask(0)
{
    setup(fragmentName, vertexName, attributes);
}

void Program::setup(const std::string& fragmentName, const std::string& vertexName, unsigned int attributes) {
    GLuint vertShader, fragShader;
    
    _activeAttributesMask = attributes;
    
    // Create and compile vertex shader.
    std::string vertShaderCode;
    loadTextResource(&vertShaderCode, vertexName, "vsh");
    
#ifdef BUILD_MAC
    vertShaderCode = "#version 120\n" + vertShaderCode;
#endif
    
    if (!compileShader(&vertShader,GL_VERTEX_SHADER,vertShaderCode)) {
        LOG("Failed to compile vertex shader");
        return;
    }
    
    // Create and compile fragment shader.
    std::string fragShaderCode;
    
    loadTextResource(&fragShaderCode, fragmentName, "fsh");

#ifdef BUILD_MAC
    fragShaderCode = "#version 120\n" + fragShaderCode;
#else
    fragShaderCode = "precision mediump float;\n" + fragShaderCode;
#endif

    if (!compileShader(&fragShader,GL_FRAGMENT_SHADER,fragShaderCode)) {
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
    if(_activeAttributesMask & ATTRIB_MASK(ATTRIB_POSITION)) {
        glBindAttribLocation(_program, ATTRIB_POSITION, "position");
    }
    
    if(_activeAttributesMask & ATTRIB_MASK(ATTRIB_SIZE)) {
        glBindAttribLocation(_program, ATTRIB_SIZE, "size");
    }
    
    if(_activeAttributesMask & ATTRIB_MASK(ATTRIB_COLOR)) {
        glBindAttribLocation(_program, ATTRIB_COLOR, "color");
    }
    
    if(_activeAttributesMask & ATTRIB_MASK(ATTRIB_POSITIONTARGET)) {
        glBindAttribLocation(_program, ATTRIB_POSITIONTARGET, "positionTarget");
    }
    
    if(_activeAttributesMask & ATTRIB_MASK(ATTRIB_SIZETARGET)) {
        glBindAttribLocation(_program, ATTRIB_SIZETARGET, "sizeTarget");
    }
    
    if(_activeAttributesMask & ATTRIB_MASK(ATTRIB_COLORTARGET)) {
        glBindAttribLocation(_program, ATTRIB_COLORTARGET, "colorTarget");
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

int Program::uniformForName(const std::string& name) {
    return glGetUniformLocation(_program, name.c_str());
}

void Program::bind() {
    glUseProgram(_program);
}

bool Program::compileShader(unsigned int* shader, unsigned int type, const std::string& code)
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
