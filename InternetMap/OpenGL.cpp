//
//  OpenGL.cpp
//  InternetMap
//

#include "OpenGL.hpp"

#ifdef ANDROID 

#include <egl/egl.h>

PFNGLMAPBUFFEROESPROC glMapBufferOES;
PFNGLUNMAPBUFFEROESPROC glUnmapBufferOES;

bool InitOpenGLExtensions(void) {
    glMapBufferOES = (PFNGLMAPBUFFEROESPROC) eglGetProcAddress("glMapBufferOES");
    glUnmapBufferOES = (PFNGLUNMAPBUFFEROESPROC) eglGetProcAddress("glUnmapBufferOES");
    
    return glMapBufferOES && glUnmapBufferOES;
}

#endif
