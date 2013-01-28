//
//  OpenGL.hpp
//  InternetMap
//

#ifndef InternetMap_OpenGL_hpp
#define InternetMap_OpenGL_hpp

#ifdef ANDROID
#include <GLES/gl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

extern PFNGLMAPBUFFEROESPROC glMapBufferOES;
extern PFNGLUNMAPBUFFEROESPROC glUnmapBufferOES;
extern bool gHasMapBuffer;
bool InitOpenGLExtensions(void);

#else
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

static bool InitOpenGLExtensions(void) {return true;}
static const bool gHasMapBuffer = true;
#endif

#endif
