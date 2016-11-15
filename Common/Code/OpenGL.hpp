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
static inline bool InitOpenGLExtensions(void) {return true;}
static const bool gHasMapBuffer = true;

#ifdef BUILD_MAC

#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/gl3.h>

#define GL_WRITE_ONLY_OES GL_WRITE_ONLY
#define GL_POINT_SPRITE_OES GL_POINT_SPRITE
#define glMapBufferOES glMapBuffer
#define glUnmapBufferOES glUnmapBuffer

#else // iOS

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#endif

#endif

#endif
