#include <stdint.h>
#include <unistd.h>
#include <pthread.h>
#include <android/native_window.h> // requires ndk r5 or newer
#include <EGL/egl.h> // requires ndk r5 or newer
#include <GLES/gl.h>
#include <EGL/eglplatform.h>
#include <string>
#include <time.h>
#include "renderer.h"

#include <common/MapController.hpp>
#include <common/MapDisplay.hpp>
#include <common/Camera.hpp>
#include <common/Nodes.hpp>

void DetachThreadFromVM(void);

Renderer::Renderer() {
	LOG_INFO("Renderer instance created");
	pthread_mutex_init(&_mutex, 0);
	_window = NULL;
	_display = 0;
	_surface = 0;
	_context = 0;

	_currentTimeSec = double(clock()) / double(CLOCKS_PER_SEC);
	_initialTimeSec = _currentTimeSec;

	// Lock the mutex to keep the thread from doing anything until we get resumed
	pthread_mutex_lock(&_mutex);
	_paused = true;

	// Create the rendering thread
	_done = false;
	pthread_create(&_threadId, 0, threadStartCallback, this);

	return;
}

Renderer::~Renderer() {
	LOG_INFO("Renderer instance destroyed");
	_done = true;
	if (_paused) {
		pthread_mutex_unlock(&_mutex);
	}
	pthread_join(_threadId, 0);
	destroy();
	pthread_mutex_destroy(&_mutex);
	return;
}

void Renderer::resume() {
	assert(_paused);
	pthread_mutex_unlock(&_mutex);
	return;
}

void Renderer::pause() {
	assert(!_paused);
	pthread_mutex_lock(&_mutex);
	return;
}

void Renderer::setWindow(ANativeWindow *window) {
	// notify render thread that window has changed
	if (!_paused) {
		pthread_mutex_lock(&_mutex);
	}
	_window = window;
	if (!_paused) {
		pthread_mutex_unlock(&_mutex);
	}

	return;
}

void Renderer::renderLoop() {
	pthread_mutex_lock(&_mutex);

	while (!_done) {
		// TODO: do we need to handle the window changing after creation, don't think so, but not sure
		if ((_display == 0) && _window) {
			initialize();
		}

		pthread_mutex_unlock(&_mutex);

		if (_display) {
			drawFrame();

			if (!eglSwapBuffers(_display, _surface)) {
				LOG_ERROR("eglSwapBuffers() returned error %d", eglGetError());
			}
		}

		pthread_mutex_lock(&_mutex);
	}

	pthread_mutex_unlock(&_mutex);

	DetachThreadFromVM();

	LOG_INFO("Render loop exits");

	return;
}

bool Renderer::initialize() {
	const EGLint attribs[] = { EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
			EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT, EGL_BLUE_SIZE, 8,
			EGL_GREEN_SIZE, 8, EGL_RED_SIZE, 8, EGL_NONE };

	const EGLint contextAttribs[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };

	EGLDisplay display;
	EGLConfig config;
	EGLint numConfigs;
	EGLint format;
	EGLSurface surface;
	EGLContext context;
	EGLint width;
	EGLint height;

	LOG_INFO("Initializing context");

	if ((display = eglGetDisplay(EGL_DEFAULT_DISPLAY)) == EGL_NO_DISPLAY) {
		LOG_ERROR("eglGetDisplay() returned error %d", eglGetError());
		return false;
	}
	if (!eglInitialize(display, 0, 0)) {
		LOG_ERROR("eglInitialize() returned error %d", eglGetError());
		return false;
	}

	if (!eglChooseConfig(display, attribs, &config, 1, &numConfigs)) {
		LOG_ERROR("eglChooseConfig() returned error %d", eglGetError());
		destroy();
		return false;
	}

	if (!eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format)) {
		LOG_ERROR("eglGetConfigAttrib() returned error %d", eglGetError());
		destroy();
		return false;
	}

	ANativeWindow_setBuffersGeometry(_window, 0, 0, format);

	if (!(surface = eglCreateWindowSurface(display, config, _window, 0))) {
		LOG_ERROR("eglCreateWindowSurface() returned error %d", eglGetError());
		destroy();
		return false;
	}

	if (!(context = eglCreateContext(display, config, 0, contextAttribs))) {
		LOG_ERROR("eglCreateContext() returned error %d", eglGetError());
		destroy();
		return false;
	}

	if (!eglMakeCurrent(display, surface, surface, context)) {
		LOG_ERROR("eglMakeCurrent() returned error %d", eglGetError());
		destroy();
		return false;
	}

	if (!eglQuerySurface(display, surface, EGL_WIDTH, &width)
			|| !eglQuerySurface(display, surface, EGL_HEIGHT, &height)) {
		LOG_ERROR("eglQuerySurface() returned error %d", eglGetError());
		destroy();
		return false;
	}

	_display = display;
	_surface = surface;
	_context = context;
	_width = width;
	_height = height;

	_mapController = new MapController;
	_mapController->display->camera->setDisplaySize(width, height);
	_mapController->data->updateDisplay(_mapController->display);

	_mapController->display->camera->setAllowIdleAnimation(true);

	return true;
}

void Renderer::destroy() {
	LOG_INFO("Destroying context");

	delete _mapController;
	_mapController = NULL;

	eglMakeCurrent(_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
	eglDestroyContext(_display, _context);
	eglDestroySurface(_display, _surface);
	eglTerminate(_display);

	_display = EGL_NO_DISPLAY;
	_surface = EGL_NO_SURFACE;
	_context = EGL_NO_CONTEXT;
	_width = 0;
	_height = 0;

	return;
}

void Renderer::drawFrame() {
	_currentTimeSec = double(clock()) / double(CLOCKS_PER_SEC);
	_mapController->display->update(_currentTimeSec - _initialTimeSec);
	_mapController->display->draw();
}

void* Renderer::threadStartCallback(void *myself) {
	Renderer *renderer = (Renderer*) myself;

	renderer->renderLoop();
	pthread_exit(0);

	return 0;
}

void cameraMoveFinishedCallback(void) {

}
