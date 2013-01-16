#ifndef RENDERER_H
#define RENDERER_H

#include <pthread.h>
#include <EGL/egl.h> // requires ndk r5 or newer
#include <GLES/gl.h>

#include <android/log.h>

#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "InternetMap", __VA_ARGS__)
#define LOG_INFO(...) __android_log_print(ANDROID_LOG_INFO, "InternetMap", __VA_ARGS__)
#define LOG_ERROR(...) __android_log_print(ANDROID_LOG_ERROR, "InternetMap", __VA_ARGS__)

class MapController;

class Renderer {

public:
    Renderer();
    virtual ~Renderer();

    void resume();
    void pause();
    void setWindow(ANativeWindow* window);
    
    
private:
    pthread_t _threadId;
    pthread_mutex_t _mutex;
    bool _done;
    bool _paused;
    
    ANativeWindow* _window;

    EGLDisplay _display;
    EGLSurface _surface;
    EGLContext _context;
    int _width;
    int _height;
    double _initialTimeSec;
    double _currentTimeSec;
    MapController* _mapController;

    // RenderLoop is called in a rendering thread started in start() method
    // It creates rendering context and renders scene until stop() is called
    void renderLoop();
    
    bool initialize();
    void destroy();

    void drawFrame();

    // Helper method for starting the thread 
    static void* threadStartCallback(void *myself);

};

#endif // RENDERER_H
