//
//  OpenGL.cpp
//  InternetMap
//

#include "OpenGL.hpp"

#ifdef ANDROID 

#include <egl/egl.h>

PFNGLGENVERTEXARRAYSOESPROC glGenVertexArraysOES;
PFNGLBINDVERTEXARRAYOESPROC glBindVertexArrayOES;
PFNGLDELETEVERTEXARRAYSOESPROC glDeleteVertexArraysOES;
PFNGLMAPBUFFEROESPROC glMapBufferOES;
PFNGLUNMAPBUFFEROESPROC glUnmapBufferOES;

bool InitOpenGLExtensions(void) {
    glGenVertexArraysOES = (PFNGLGENVERTEXARRAYSOESPROC) eglGetProcAddress("glGenVertexArraysOES");
    glBindVertexArrayOES = (PFNGLBINDVERTEXARRAYOESPROC) eglGetProcAddress("glBindVertexArrayOES");
    glDeleteVertexArraysOES = (PFNGLDELETEVERTEXARRAYSOESPROC) eglGetProcAddress("glDeleteVertexArraysOES");
    glMapBufferOES = (PFNGLMAPBUFFEROESPROC) eglGetProcAddress("glMapBufferOES");
    glUnmapBufferOES = (PFNGLUNMAPBUFFEROESPROC) eglGetProcAddress("glUnmapBufferOES");
    
    return glGenVertexArraysOES && glBindVertexArrayOES && glDeleteVertexArraysOES && glMapBufferOES && glUnmapBufferOES;
}

#endif
