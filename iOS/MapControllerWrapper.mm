//
//  MapControllerWrapper.m
//  InternetMap
//
//  Created by Alexander on 11.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "MapControllerWrapper.h"
#include "MapController.hpp"
#include "Camera.hpp"
#include "DefaultVisualization.hpp"
#import "NodeWrapper+CPPHelpers.h"
#import "GlobeVisualization.hpp"

//TODO: move these to a better place

void cameraMoveFinishedCallback(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraMovementFinished" object:nil];
}


void cameraResetFinishedCallback(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraResetFinished" object:nil];
}


void lostSelectedNodeCallback(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lostSelectedNode" object:nil];
}

void loadTextResource(std::string* resource, const std::string& base, const std::string& extension) {
    NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithCString:base.c_str() encoding:NSUTF8StringEncoding] ofType:[NSString stringWithCString:extension.c_str() encoding:NSUTF8StringEncoding]];
    NSString* contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if(!contents) {
        *resource = "";
    }
    else {
        *resource = [contents UTF8String];
    }
}

bool deviceIsOld() {
    return [HelperMethods deviceIsOld];
}

Matrix4 Matrix4FromGLKMatrix4(GLKMatrix4 mat) {
    return Matrix4(Vector4(mat.m00, mat.m01, mat.m02, mat.m03), Vector4(mat.m10, mat.m11, mat.m12, mat.m13), Vector4(mat.m20, mat.m21, mat.m22, mat.m23), Vector4(mat.m30, mat.m31, mat.m32, mat.m33));
}

//end move

@interface MapControllerWrapper()

@property (nonatomic, readwrite, assign) MapController* controller;

@end


@implementation MapControllerWrapper

- (id)init {
    if (self = [super init]) {
        DefaultVisualization::setPortrait(![HelperMethods deviceIsiPad]);
        
        _controller = new MapController();

        if(![HelperMethods deviceIsiPad]) {
            _controller->display->camera->zoomByScale(-0.5);
        }
        
        _controller->display->setDisplayScale([[UIScreen mainScreen] scale]);
        _controller->updateDisplay(false);
        
    }
    
    return self;
}

- (void)dealloc {
    delete _controller;
}

#pragma mark - Custom properties

- (unsigned int)targetNode{
    return _controller->targetNode;
}

- (void)setTargetNode:(unsigned int)targetNode {
    _controller->targetNode = targetNode;
}

- (CGSize)displaySize {
    return CGSizeMake(_controller->display->camera->displayWidth(), _controller->display->camera->displayHeight());
}

- (void)setDisplaySize:(CGSize)displaySize {
    _controller->display->camera->setDisplaySize(displaySize.width, displaySize.height);
}

- (float)currentZoom {
    return _controller->display->camera->currentZoom();
}

- (NSString*)lastSearchIP {
    return [NSString stringWithUTF8String:_controller->lastSearchIP.c_str()];
}

- (void)setLastSearchIP:(NSString *)lastSearchIP {
    _controller->lastSearchIP = std::string([lastSearchIP UTF8String]);
}

#pragma mark - Display

- (void)draw{
    _controller->display->draw();
}

- (void)hoverNode:(int)index {
    _controller->hoverNode(index);
}

#pragma mark - Camera: Misc

- (void)update:(NSTimeInterval)now{
    _controller->update(now);
}

- (void)setAllowIdleAnimation:(BOOL)allow{
    _controller->display->camera->setAllowIdleAnimation(allow);
}

- (void)resetIdleTimer{
    _controller->display->camera->resetIdleTimer();
}

#pragma mark - Camera: View Manipulation

- (void)resetZoomAndRotationAnimatedForOrientation:(BOOL)isPortraitMode{
    _controller->display->camera->resetZoomAndRotationAnimated(isPortraitMode);
}

- (void)translateYAnimated:(float)translateY duration:(NSTimeInterval)duration {
    _controller->display->camera->translateYAnimated(translateY, duration);
}

- (void)zoomAnimated:(float)zoom duration:(NSTimeInterval)duration{
    _controller->display->camera->zoomAnimated(zoom, duration);
}

- (void)rotateAnimated:(GLKMatrix4)matrix duration:(NSTimeInterval)duration{
    _controller->display->camera->rotateAnimated(Matrix4FromGLKMatrix4(matrix), duration);
}

- (void)rotateRadiansX:(float)rotate{
    _controller->display->camera->rotateRadiansX(rotate);
}

- (void)rotateRadiansY:(float)rotate{
    _controller->display->camera->rotateRadiansY(rotate);
}

- (void)rotateRadiansZ:(float)rotate{
    _controller->display->camera->rotateRadiansZ(rotate);
}

- (void)zoomByScale:(float)scale{
    _controller->display->camera->zoomByScale(scale);
}

- (void)startMomentumPanWithVelocity:(CGPoint)velocity{
    _controller->display->camera->startMomentumPanWithVelocity(Vector2(velocity.x, velocity.y));
}

- (void)startMomentumRotationWithVelocity:(float)velocity{
    _controller->display->camera->startMomentumRotationWithVelocity(velocity);
}

- (void)startMomentumZoomWithVelocity:(float)velocity{
    _controller->display->camera->startMomentumZoomWithVelocity(velocity);
}

- (void)stopMomentumPan{
    _controller->display->camera->stopMomentumPan();
}

- (void)stopMomentumRotation{
    _controller->display->camera->stopMomentumRotation();
}

- (void)stopMomentumZoom{
    _controller->display->camera->stopMomentumZoom();
}

#pragma mark - Data: Node retrieval

-(NSMutableArray*)allNodes {
    
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:_controller->data->nodes.size()];
    
    for (int i = 0; i<_controller->data->nodes.size(); i++) {
        NodePointer node = _controller->data->nodes[i];
        if(node->isActive()) {
            NodeWrapper* wrap = [[NodeWrapper alloc] initWithNodePointer:node];
            [array addObject:wrap];
        }
    }
    
    return array;
}

- (NodeWrapper*)nodeAtIndex:(int)index{
    NodePointer node = _controller->data->nodes[index];
    return [[NodeWrapper alloc] initWithNodePointer:node];
}

- (NodeWrapper*)nodeByASN:(NSString*)asn{
    if (asn == nil)
        return nil;

    NodePointer node = _controller->data->nodesByAsn[std::string([asn UTF8String])];

    if(node && node->isActive())
        return [[NodeWrapper alloc] initWithNodePointer:node];
    else
        return nil;
}

- (BOOL) isWithinMaxNodeIndex:(int)index {
    if (index >= _controller->data->nodes.size()) return NO;
    return YES;
}

#pragma mark - Controller: Event handling

- (void)handleTouchDownAtPoint:(CGPoint)point{
    _controller->handleTouchDownAtPoint(Vector2(point.x, point.y));
}

#pragma mark - Controller: Node Selection 

- (BOOL)selectHoveredNode{
    return _controller->selectHoveredNode();
}

- (void)unhoverNode{
    _controller->unhoverNode();
}

- (void)deselectCurrentNode {
    _controller->deselectCurrentNode();
}

- (int)indexForNodeAtPoint:(CGPoint)pointInView{
    return _controller->indexForNodeAtPoint(Vector2(pointInView.x, pointInView.y));
}

-(CGPoint)getCoordinatesForNodeAtIndex:(int)index{
    Vector2 vec = _controller->getCoordinatesForNodeAtIndex(index);
    return CGPointMake(vec.x, vec.y);
}

- (void)updateTargetForIndex:(int)index{
    _controller->updateTargetForIndex(index);
}

#pragma mark - Controller: Line highlighting

- (void)clearHighlightLines{
    _controller->clearHighlightLines();
}

-(void)highlightRoute:(NSArray*)nodeList{
    
    std::vector<NodePointer> newList;
    for (NodeWrapper* node in nodeList) {
        NodePointer pointer = _controller->data->nodeAtIndex(node.index);
        newList.push_back(pointer);
    }
    _controller->highlightRoute(newList);
}

#pragma mark - Timeline

- (void)setTimelinePoint:(NSString*)timelinePointName {
    _controller->setTimelinePoint(std::string([timelinePointName UTF8String]));
}

#pragma mark - Visualizaitons

- (NSArray*)visualizationNames {
    std::vector<std::string> names = _controller->visualizationNames();
    NSMutableArray* result = [NSMutableArray new];
    
    for(int i = 0; i < names.size(); i++) {
        [result addObject:[NSString stringWithCString:names[i].c_str() encoding:NSUTF8StringEncoding]];
    }
    
    return result;
}

- (void)setVisualization:(int)vis {
    _controller->setVisualization(vis);
}

@end
