struct objc_selector; struct objc_class;
struct __rw_objc_super { struct objc_object *object; struct objc_object *superClass; };
#ifndef _REWRITER_typedef_Protocol
typedef struct objc_object Protocol;
#define _REWRITER_typedef_Protocol
#endif
#define __OBJC_RW_DLLIMPORT extern
__OBJC_RW_DLLIMPORT struct objc_object *objc_msgSend(struct objc_object *, struct objc_selector *, ...);
__OBJC_RW_DLLIMPORT struct objc_object *objc_msgSendSuper(struct objc_super *, struct objc_selector *, ...);
__OBJC_RW_DLLIMPORT struct objc_object* objc_msgSend_stret(struct objc_object *, struct objc_selector *, ...);
__OBJC_RW_DLLIMPORT struct objc_object* objc_msgSendSuper_stret(struct objc_super *, struct objc_selector *, ...);
__OBJC_RW_DLLIMPORT double objc_msgSend_fpret(struct objc_object *, struct objc_selector *, ...);
__OBJC_RW_DLLIMPORT struct objc_object *objc_getClass(const char *);
__OBJC_RW_DLLIMPORT struct objc_class *class_getSuperclass(struct objc_class *);
__OBJC_RW_DLLIMPORT struct objc_object *objc_getMetaClass(const char *);
__OBJC_RW_DLLIMPORT void objc_exception_throw(struct objc_object *);
__OBJC_RW_DLLIMPORT void objc_exception_try_enter(void *);
__OBJC_RW_DLLIMPORT void objc_exception_try_exit(void *);
__OBJC_RW_DLLIMPORT struct objc_object *objc_exception_extract(void *);
__OBJC_RW_DLLIMPORT int objc_exception_match(struct objc_class *, struct objc_object *);
__OBJC_RW_DLLIMPORT void objc_sync_enter(struct objc_object *);
__OBJC_RW_DLLIMPORT void objc_sync_exit(struct objc_object *);
__OBJC_RW_DLLIMPORT Protocol *objc_getProtocol(const char *);
#ifndef __FASTENUMERATIONSTATE
struct __objcFastEnumerationState {
	unsigned long state;
	void **itemsPtr;
	unsigned long *mutationsPtr;
	unsigned long extra[5];
};
__OBJC_RW_DLLIMPORT void objc_enumerationMutation(struct objc_object *);
#define __FASTENUMERATIONSTATE
#endif
#ifndef __NSCONSTANTSTRINGIMPL
struct __NSConstantStringImpl {
  int *isa;
  int flags;
  char *str;
  long length;
};
#ifdef CF_EXPORT_CONSTANT_STRING
extern "C" __declspec(dllexport) int __CFConstantStringClassReference[];
#else
__OBJC_RW_DLLIMPORT int __CFConstantStringClassReference[];
#endif
#define __NSCONSTANTSTRINGIMPL
#endif
#ifndef BLOCK_IMPL
#define BLOCK_IMPL
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};
// Runtime copy/destroy helper functions (from Block_private.h)
#ifdef __OBJC_EXPORT_BLOCKS
extern "C" __declspec(dllexport) void _Block_object_assign(void *, const void *, const int);
extern "C" __declspec(dllexport) void _Block_object_dispose(const void *, const int);
extern "C" __declspec(dllexport) void *_NSConcreteGlobalBlock[32];
extern "C" __declspec(dllexport) void *_NSConcreteStackBlock[32];
#else
__OBJC_RW_DLLIMPORT void _Block_object_assign(void *, const void *, const int);
__OBJC_RW_DLLIMPORT void _Block_object_dispose(const void *, const int);
__OBJC_RW_DLLIMPORT void *_NSConcreteGlobalBlock[32];
__OBJC_RW_DLLIMPORT void *_NSConcreteStackBlock[32];
#endif
#endif
#define __block
#define __weak

#define __OFFSETOFIVAR__(TYPE, MEMBER) ((long long) &((TYPE *)0)->MEMBER)
static __NSConstantStringImpl __NSConstantStringImpl_Camera_m_0 __attribute__ ((section ("__DATA, __cfstring"))) = {__CFConstantStringClassReference,0x000007c8,"cameraMovementFinished",22};

//  Camera.m
//  InternetMap
//

#include "Camera.h"

static const float MOVE_TIME = 1.0f;
static const float FINAL_ZOOM_ON_SELECTION = -0.4;

// @implementation Camera

// // // // // // @synthesize displaySize = _displaySize, target = _target, isMovingToTarget = _isMovingToTarget, targetMoveStart = _targetMoveStart, targetMoveStartPosition = _targetMoveStartPosition, targetZoomStart = _targetZoomStart;
static CGSize _I_Camera_displaySize(struct Camera * self, SEL _cmd) { return ((struct Camera_IMPL *)self)->_displaySize; }
static void _I_Camera_setDisplaySize_(struct Camera * self, SEL _cmd, CGSize displaySize) { ((struct Camera_IMPL *)self)->_displaySize = displaySize; }
static BOOL _I_Camera_isMovingToTarget(struct Camera * self, SEL _cmd) { return ((struct Camera_IMPL *)self)->_isMovingToTarget; }
static void _I_Camera_setIsMovingToTarget_(struct Camera * self, SEL _cmd, BOOL isMovingToTarget) { ((struct Camera_IMPL *)self)->_isMovingToTarget = isMovingToTarget; }
static NSTimeInterval _I_Camera_targetMoveStart(struct Camera * self, SEL _cmd) { return ((struct Camera_IMPL *)self)->_targetMoveStart; }
static void _I_Camera_setTargetMoveStart_(struct Camera * self, SEL _cmd, NSTimeInterval targetMoveStart) { ((struct Camera_IMPL *)self)->_targetMoveStart = targetMoveStart; }
static GLKVector3 _I_Camera_targetMoveStartPosition(struct Camera * self, SEL _cmd) { return ((struct Camera_IMPL *)self)->_targetMoveStartPosition; }
static void _I_Camera_setTargetMoveStartPosition_(struct Camera * self, SEL _cmd, GLKVector3 targetMoveStartPosition) { ((struct Camera_IMPL *)self)->_targetMoveStartPosition = targetMoveStartPosition; }
static float _I_Camera_targetZoomStart(struct Camera * self, SEL _cmd) { return ((struct Camera_IMPL *)self)->_targetZoomStart; }
static void _I_Camera_setTargetZoomStart_(struct Camera * self, SEL _cmd, float targetZoomStart) { ((struct Camera_IMPL *)self)->_targetZoomStart = targetZoomStart; }


static id _I_Camera_init(struct Camera * self, SEL _cmd) {
    if((self = ((id (*)(struct objc_super *, SEL))(void *)objc_msgSendSuper)((struct objc_super){ (id)self, (id)class_getSuperclass((Class)objc_getClass("Camera")) }, sel_registerName("init")))) {
        ((struct Camera_IMPL *)self)->_rotationMatrix = GLKMatrix4Identity;
        ((struct Camera_IMPL *)self)->_zoom = -3.0f;
        ((void (*)(id, SEL, GLKVector3))(void *)objc_msgSend)((id)self, sel_registerName("setTarget:"), GLKVector3Make(0, 0, 0));
        ((void (*)(id, SEL, GLKVector3))(void *)objc_msgSend)((id)self, sel_registerName("setTargetMoveStartPosition:"), GLKVector3Make(0, 0, 0));
        ((void (*)(id, SEL, NSTimeInterval))(void *)objc_msgSend)((id)self, sel_registerName("setTargetMoveStart:"), ((NSTimeInterval (*)(id, SEL))(void *)objc_msgSend_fpret)((id)((id (*)(id, SEL))(void *)objc_msgSend)(objc_getClass("NSDate"), sel_registerName("distantFuture")), sel_registerName("timeIntervalSinceReferenceDate")));
        self.isMovingToTarget = NO;
    }
    
    return self;
}


static void _I_Camera_rotateRadiansX_(struct Camera * self, SEL _cmd, float rotate) {
    ((struct Camera_IMPL *)self)->_rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 1.0f, 0.0f), ((struct Camera_IMPL *)self)->_rotationMatrix);
}


static void _I_Camera_rotateRadiansY_(struct Camera * self, SEL _cmd, float rotate) {
    ((struct Camera_IMPL *)self)->_rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 1.0f, 0.0f, 0.0f), ((struct Camera_IMPL *)self)->_rotationMatrix);
}


static void _I_Camera_rotateRadiansZ_(struct Camera * self, SEL _cmd, float rotate) {
    ((struct Camera_IMPL *)self)->_rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(rotate, 0.0f, 0.0f, 1.0f), ((struct Camera_IMPL *)self)->_rotationMatrix);
}


static void _I_Camera_zoom_(struct Camera * self, SEL _cmd, float zoom) {
    ((struct Camera_IMPL *)self)->_zoom += zoom * -((struct Camera_IMPL *)self)->_zoom;
    if(((struct Camera_IMPL *)self)->_zoom > -0.2) {
        ((struct Camera_IMPL *)self)->_zoom = -0.2;
    }
    
    if(((struct Camera_IMPL *)self)->_zoom < -10.0f) {
        ((struct Camera_IMPL *)self)->_zoom = -10.0f;
    }
    

}


static void _I_Camera_setTarget_(struct Camera * self, SEL _cmd, GLKVector3 target) {
    ((struct Camera_IMPL *)self)->_targetMoveStartPosition = ((struct Camera_IMPL *)self)->_target;
    ((struct Camera_IMPL *)self)->_target = target;
    ((struct Camera_IMPL *)self)->_targetZoomStart = ((struct Camera_IMPL *)self)->_zoom;
    ((struct Camera_IMPL *)self)->_targetMoveStart = ((NSTimeInterval (*)(id, SEL))(void *)objc_msgSend_fpret)(objc_getClass("NSDate"), sel_registerName("timeIntervalSinceReferenceDate"));
    ((struct Camera_IMPL *)self)->_isMovingToTarget = YES;
}


static GLKVector3 _I_Camera_target(struct Camera * self, SEL _cmd) {
    return ((struct Camera_IMPL *)self)->_target;
}


static void _I_Camera_update(struct Camera * self, SEL _cmd) {
    NSTimeInterval now = ((NSTimeInterval (*)(id, SEL))(void *)objc_msgSend_fpret)(objc_getClass("NSDate"), sel_registerName("timeIntervalSinceReferenceDate"));
    
    GLKVector3 currentTarget;
    if(((NSTimeInterval (*)(id, SEL))(void *)objc_msgSend_fpret)((id)self, sel_registerName("targetMoveStart")) < now) {
        float timeT = (now - ((NSTimeInterval (*)(id, SEL))(void *)objc_msgSend_fpret)((id)self, sel_registerName("targetMoveStart"))) / MOVE_TIME;
        if(timeT > 1.0f) {
            currentTarget = (sizeof(GLKVector3) <= 8 ? ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("target")) : ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend_stret)((id)self, sel_registerName("target")));
            ((void (*)(id, SEL, NSTimeInterval))(void *)objc_msgSend)((id)self, sel_registerName("setTargetMoveStart:"), ((NSTimeInterval (*)(id, SEL))(void *)objc_msgSend_fpret)((id)((id (*)(id, SEL))(void *)objc_msgSend)(objc_getClass("NSDate"), sel_registerName("distantFuture")), sel_registerName("timeIntervalSinceReferenceDate")));
            self.isMovingToTarget = NO;
            ((void (*)(id, SEL, NSString *, id))(void *)objc_msgSend)((id)((id (*)(id, SEL))(void *)objc_msgSend)(objc_getClass("NSNotificationCenter"), sel_registerName("defaultCenter")), sel_registerName("postNotificationName:object:"), (NSString *)&__NSConstantStringImpl_Camera_m_0, (id)((void *)0));
        }
        else {
            float positionT;
            
            // Quadratic ease-in / ease-out
            if (timeT < 0.5f)
            {
                positionT = timeT * timeT * 2;
            }
            else {
                positionT = 1.0f - ((timeT - 1.0f) * (timeT - 1.0f) * 2.0f);
            }
            
            currentTarget = GLKVector3Add((sizeof(GLKVector3) <= 8 ? ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("targetMoveStartPosition")) : ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend_stret)((id)self, sel_registerName("targetMoveStartPosition"))), GLKVector3MultiplyScalar(GLKVector3Subtract((sizeof(GLKVector3) <= 8 ? ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("target")) : ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend_stret)((id)self, sel_registerName("target"))), (sizeof(GLKVector3) <= 8 ? ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("targetMoveStartPosition")) : ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend_stret)((id)self, sel_registerName("targetMoveStartPosition")))), positionT));
            ((struct Camera_IMPL *)self)->_zoom = ((float (*)(id, SEL))(void *)objc_msgSend_fpret)((id)self, sel_registerName("targetZoomStart")) + (FINAL_ZOOM_ON_SELECTION-((float (*)(id, SEL))(void *)objc_msgSend_fpret)((id)self, sel_registerName("targetZoomStart")))*positionT;
        }
    }
    else {
        currentTarget = (sizeof(GLKVector3) <= 8 ? ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("target")) : ((GLKVector3 (*)(id, SEL))(void *)objc_msgSend_stret)((id)self, sel_registerName("target")));
    }
    
    float aspect = fabsf((sizeof(CGSize) <= 8 ? ((CGSize (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("displaySize")) : ((CGSize (*)(id, SEL))(void *)objc_msgSend_stret)((id)self, sel_registerName("displaySize"))).width / (sizeof(CGSize) <= 8 ? ((CGSize (*)(id, SEL))(void *)objc_msgSend)((id)self, sel_registerName("displaySize")) : ((CGSize (*)(id, SEL))(void *)objc_msgSend_stret)((id)self, sel_registerName("displaySize"))).height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    GLKMatrix4 model = GLKMatrix4Multiply(((struct Camera_IMPL *)self)->_rotationMatrix, GLKMatrix4MakeTranslation(-currentTarget.x, -currentTarget.y, -currentTarget.z));
    GLKMatrix4 zoom = GLKMatrix4MakeTranslation(0.0f, 0.0f, ((struct Camera_IMPL *)self)->_zoom);
    GLKMatrix4 modelView = GLKMatrix4Multiply(zoom, model);
    
    ((struct Camera_IMPL *)self)->_projectionMatrix = projectionMatrix;
    ((struct Camera_IMPL *)self)->_modelViewMatrix = modelView;
    ((struct Camera_IMPL *)self)->_modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelView);
}


static GLKMatrix4 _I_Camera_currentModelViewProjection(struct Camera * self, SEL _cmd) {
    return ((struct Camera_IMPL *)self)->_modelViewProjectionMatrix;
}


static GLKMatrix4 _I_Camera_currentModelView(struct Camera * self, SEL _cmd) {
    return ((struct Camera_IMPL *)self)->_modelViewMatrix;
}



static GLKMatrix4 _I_Camera_currentProjection(struct Camera * self, SEL _cmd) {
    return ((struct Camera_IMPL *)self)->_projectionMatrix;
}



static GLKVector3 _I_Camera_cameraInObjectSpace(struct Camera * self, SEL _cmd) {
    GLKMatrix4 invertedModelViewMatrix = GLKMatrix4Invert(((struct Camera_IMPL *)self)->_modelViewMatrix, NULL);
    return GLKVector3Make(invertedModelViewMatrix.m30, invertedModelViewMatrix.m31, invertedModelViewMatrix.m32);

}


static GLKVector3 _I_Camera_applyModelViewToPoint_(struct Camera * self, SEL _cmd, CGPoint point) {
    GLKVector4 vec4FromPoint = GLKVector4Make(point.x, point.y, -0.1, 1);
    GLKMatrix4 invertedModelViewProjectionMatrix = GLKMatrix4Invert(((struct Camera_IMPL *)self)->_modelViewProjectionMatrix, NULL);
    vec4FromPoint = GLKMatrix4MultiplyVector4(invertedModelViewProjectionMatrix, vec4FromPoint);
    vec4FromPoint = GLKVector4DivideScalar(vec4FromPoint, vec4FromPoint.w);

    return GLKVector3Make(vec4FromPoint.x, vec4FromPoint.y, vec4FromPoint.z);

}

// @end

struct _objc_ivar {
	char *ivar_name;
	char *ivar_type;
	int ivar_offset;
};

static struct {
	int ivar_count;
	struct _objc_ivar ivar_list[12];
} _OBJC_INSTANCE_VARIABLES_Camera __attribute__ ((used, section ("__OBJC, __instance_vars")))= {
	12
	,{{"_modelViewProjectionMatrix", "(_GLKMatrix4=\"\"{?=\"m00\"f\"m01\"f\"m02\"f\"m03\"f\"m10\"f\"m11\"f\"m12\"f\"m13\"f\"m20\"f\"m21\"f\"m22\"f\"m23\"f\"m30\"f\"m31\"f\"m32\"f\"m33\"f}\"m\"[16f])", __OFFSETOFIVAR__(struct Camera, _modelViewProjectionMatrix)}
	  ,{"_modelViewMatrix", "(_GLKMatrix4=\"\"{?=\"m00\"f\"m01\"f\"m02\"f\"m03\"f\"m10\"f\"m11\"f\"m12\"f\"m13\"f\"m20\"f\"m21\"f\"m22\"f\"m23\"f\"m30\"f\"m31\"f\"m32\"f\"m33\"f}\"m\"[16f])", __OFFSETOFIVAR__(struct Camera, _modelViewMatrix)}
	  ,{"_projectionMatrix", "(_GLKMatrix4=\"\"{?=\"m00\"f\"m01\"f\"m02\"f\"m03\"f\"m10\"f\"m11\"f\"m12\"f\"m13\"f\"m20\"f\"m21\"f\"m22\"f\"m23\"f\"m30\"f\"m31\"f\"m32\"f\"m33\"f}\"m\"[16f])", __OFFSETOFIVAR__(struct Camera, _projectionMatrix)}
	  ,{"_rotationMatrix", "(_GLKMatrix4=\"\"{?=\"m00\"f\"m01\"f\"m02\"f\"m03\"f\"m10\"f\"m11\"f\"m12\"f\"m13\"f\"m20\"f\"m21\"f\"m22\"f\"m23\"f\"m30\"f\"m31\"f\"m32\"f\"m33\"f}\"m\"[16f])", __OFFSETOFIVAR__(struct Camera, _rotationMatrix)}
	  ,{"_rotation", "f", __OFFSETOFIVAR__(struct Camera, _rotation)}
	  ,{"_zoom", "f", __OFFSETOFIVAR__(struct Camera, _zoom)}
	  ,{"_displaySize", "{CGSize=\"width\"d\"height\"d}", __OFFSETOFIVAR__(struct Camera, _displaySize)}
	  ,{"_target", "(_GLKVector3=\"\"{?=\"x\"f\"y\"f\"z\"f}\"\"{?=\"r\"f\"g\"f\"b\"f}\"\"{?=\"s\"f\"t\"f\"p\"f}\"v\"[3f])", __OFFSETOFIVAR__(struct Camera, _target)}
	  ,{"_isMovingToTarget", "c", __OFFSETOFIVAR__(struct Camera, _isMovingToTarget)}
	  ,{"_targetMoveStart", "d", __OFFSETOFIVAR__(struct Camera, _targetMoveStart)}
	  ,{"_targetMoveStartPosition", "(_GLKVector3=\"\"{?=\"x\"f\"y\"f\"z\"f}\"\"{?=\"r\"f\"g\"f\"b\"f}\"\"{?=\"s\"f\"t\"f\"p\"f}\"v\"[3f])", __OFFSETOFIVAR__(struct Camera, _targetMoveStartPosition)}
	  ,{"_targetZoomStart", "f", __OFFSETOFIVAR__(struct Camera, _targetZoomStart)}
	 }
};

struct _objc_method {
	SEL _cmd;
	char *method_types;
	void *_imp;
};

static struct {
	struct _objc_method_list *next_method;
	int method_count;
	struct _objc_method method_list[23];
} _OBJC_INSTANCE_METHODS_Camera __attribute__ ((used, section ("__OBJC, __inst_meth")))= {
	0, 23
	,{{(SEL)"init", "@16@0:8", (void *)_I_Camera_init}
	  ,{(SEL)"rotateRadiansX:", "v20@0:8f16", (void *)_I_Camera_rotateRadiansX_}
	  ,{(SEL)"rotateRadiansY:", "v20@0:8f16", (void *)_I_Camera_rotateRadiansY_}
	  ,{(SEL)"rotateRadiansZ:", "v20@0:8f16", (void *)_I_Camera_rotateRadiansZ_}
	  ,{(SEL)"zoom:", "v20@0:8f16", (void *)_I_Camera_zoom_}
	  ,{(SEL)"setTarget:", "v28@0:8(_GLKVector3={?=fff}{?=fff}{?=fff}[3f])16", (void *)_I_Camera_setTarget_}
	  ,{(SEL)"target", "(_GLKVector3={?=fff}{?=fff}{?=fff}[3f])16@0:8", (void *)_I_Camera_target}
	  ,{(SEL)"update", "v16@0:8", (void *)_I_Camera_update}
	  ,{(SEL)"currentModelViewProjection", "(_GLKMatrix4={?=ffffffffffffffff}[16f])16@0:8", (void *)_I_Camera_currentModelViewProjection}
	  ,{(SEL)"currentModelView", "(_GLKMatrix4={?=ffffffffffffffff}[16f])16@0:8", (void *)_I_Camera_currentModelView}
	  ,{(SEL)"currentProjection", "(_GLKMatrix4={?=ffffffffffffffff}[16f])16@0:8", (void *)_I_Camera_currentProjection}
	  ,{(SEL)"cameraInObjectSpace", "(_GLKVector3={?=fff}{?=fff}{?=fff}[3f])16@0:8", (void *)_I_Camera_cameraInObjectSpace}
	  ,{(SEL)"applyModelViewToPoint:", "(_GLKVector3={?=fff}{?=fff}{?=fff}[3f])32@0:8{CGPoint=dd}16", (void *)_I_Camera_applyModelViewToPoint_}
	  ,{(SEL)"displaySize", "{CGSize=dd}16@0:8", (void *)_I_Camera_displaySize}
	  ,{(SEL)"setDisplaySize:", "v32@0:8{CGSize=dd}16", (void *)_I_Camera_setDisplaySize_}
	  ,{(SEL)"isMovingToTarget", "c16@0:8", (void *)_I_Camera_isMovingToTarget}
	  ,{(SEL)"setIsMovingToTarget:", "v20@0:8c16", (void *)_I_Camera_setIsMovingToTarget_}
	  ,{(SEL)"targetMoveStart", "d16@0:8", (void *)_I_Camera_targetMoveStart}
	  ,{(SEL)"setTargetMoveStart:", "v24@0:8d16", (void *)_I_Camera_setTargetMoveStart_}
	  ,{(SEL)"targetMoveStartPosition", "(_GLKVector3={?=fff}{?=fff}{?=fff}[3f])16@0:8", (void *)_I_Camera_targetMoveStartPosition}
	  ,{(SEL)"setTargetMoveStartPosition:", "v28@0:8(_GLKVector3={?=fff}{?=fff}{?=fff}[3f])16", (void *)_I_Camera_setTargetMoveStartPosition_}
	  ,{(SEL)"targetZoomStart", "f16@0:8", (void *)_I_Camera_targetZoomStart}
	  ,{(SEL)"setTargetZoomStart:", "v20@0:8f16", (void *)_I_Camera_setTargetZoomStart_}
	 }
};

struct _objc_class {
	struct _objc_class *isa;
	const char *super_class_name;
	char *name;
	long version;
	long info;
	long instance_size;
	struct _objc_ivar_list *ivars;
	struct _objc_method_list *methods;
	struct objc_cache *cache;
	struct _objc_protocol_list *protocols;
	const char *ivar_layout;
	struct _objc_class_ext  *ext;
};

static struct _objc_class _OBJC_METACLASS_Camera __attribute__ ((used, section ("__OBJC, __meta_class")))= {
	(struct _objc_class *)"NSObject", "NSObject", "Camera", 0,2, sizeof(struct _objc_class), 0, 0
	,0,0,0,0
};

static struct _objc_class _OBJC_CLASS_Camera __attribute__ ((used, section ("__OBJC, __class")))= {
	&_OBJC_METACLASS_Camera, "NSObject", "Camera", 0,1,sizeof(struct Camera), (struct _objc_ivar_list *)&_OBJC_INSTANCE_VARIABLES_Camera
	, (struct _objc_method_list *)&_OBJC_INSTANCE_METHODS_Camera, 0
	,0,0,0
};

struct _objc_symtab {
	long sel_ref_cnt;
	SEL *refs;
	short cls_def_cnt;
	short cat_def_cnt;
	void *defs[1];
};

static struct _objc_symtab _OBJC_SYMBOLS __attribute__((used, section ("__OBJC, __symbols")))= {
	0, 0, 1, 0
	,&_OBJC_CLASS_Camera
};


struct _objc_module {
	long version;
	long size;
	const char *name;
	struct _objc_symtab *symtab;
};

static struct _objc_module _OBJC_MODULES __attribute__ ((used, section ("__OBJC, __module_info")))= {
	7, sizeof(struct _objc_module), "", &_OBJC_SYMBOLS
};

