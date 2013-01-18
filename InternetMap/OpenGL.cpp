//
//  OpenGL.cpp
//  InternetMap
//

#include "OpenGL.hpp"
#include "Types.hpp"
#include <string>

#ifdef ANDROID 

#include <egl/egl.h>

PFNGLMAPBUFFEROESPROC glMapBufferOES;
PFNGLUNMAPBUFFEROESPROC glUnmapBufferOES;
bool gHasMapBuffer;

bool InitOpenGLExtensions(void) {
    std::string mapBufferExtension("GL_OES_mapbuffer");
    std::string extensions((char*)(glGetString(GL_EXTENSIONS)));

    gHasMapBuffer = false;// extensions.find(mapBufferExtension) != std::string::npos;
    LOG("hasMapBuffer %d", (int)gHasMapBuffer);

    if(gHasMapBuffer) {
        glMapBufferOES = (PFNGLMAPBUFFEROESPROC) eglGetProcAddress("glMapBufferOES");
        glUnmapBufferOES = (PFNGLUNMAPBUFFEROESPROC) eglGetProcAddress("glUnmapBufferOES");
    }
    
    return gHasMapBuffer && glMapBufferOES && glUnmapBufferOES;
}

#endif
