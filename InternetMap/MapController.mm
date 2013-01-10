//
//  MapController.m
//  InternetMap
//
//  Created by Alexander on 07.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "MapController.h"
#import "MapDisplay.h"
#import "MapData.h"
#import "DefaultVisualization.h"
#import "Nodes.h"
#import "Camera.hpp"
#import "Node.h"
#import "Lines.hpp"
#import "Connection.h"
#import "IndexBox.h"

// Temp conversion functions while not everything is converted TODO: remove
/// -----
static Point3 GLKVec3ToPoint(const GLKVector3& in) {
    return Point3(in.x, in.y, in.z);
};

static GLKVector3 Vec3ToGLK(const Vector3& in) {
    return GLKVector3Make(in.getX(), in.getY(), in.getZ());
};

void cameraMoveFinishedCallback(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"cameraMovementFinished" object:nil];
}
/// -----

@implementation MapController


- (id)init{
    
    if (self = [super init]) {
        self.display = [MapDisplay new];
        self.data = [MapData new];
        
        
        self.data.visualization = [DefaultVisualization new];
        
        [self.data loadFromFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"]];
        [self.data loadFromAttrFile:[[NSBundle mainBundle] pathForResource:@"as2attr" ofType:@"txt"]];
        [self.data loadAsInfo:[[NSBundle mainBundle] pathForResource:@"asinfo" ofType:@"json"]];
        [self.data updateDisplay:self.display];
        
        self.targetNode = NSNotFound;
        self.hoveredNodeIndex = NSNotFound;

    }
    
    return self;
}


#pragma mark - Event Handling

- (void)handleTouchDownAtPoint:(CGPoint)point {
    
    if (!self.display.camera->isMovingToTarget()) {
        //cancel panning/zooming momentum
        self.display.camera->stopMomentumPan();
        self.display.camera->stopMomentumZoom();
        self.display.camera->stopMomentumRotation();
        
        int i = [self indexForNodeAtPoint:point];
        if (i != NSNotFound) {
            self.hoveredNodeIndex = i;
            [self.display.nodes beginUpdate];
            [self.display.nodes updateNode:i color:SELECTED_NODE_COLOR];
            [self.display.nodes endUpdate];
        }
    }
}

#pragma mark - Selected Node handling

- (void)selectHoveredNode {
    if (self.hoveredNodeIndex != NSNotFound) {
        self.lastSearchIP = nil;
        [self updateTargetForIndex:self.hoveredNodeIndex];
        self.hoveredNodeIndex = NSNotFound;
    }
}

- (void)unhoverNode {
    
    if (self.hoveredNodeIndex != NSNotFound && self.hoveredNodeIndex != self.targetNode) {
        Node* node = [self.data nodeAtIndex:self.hoveredNodeIndex];
        
        [self.data.visualization updateDisplay:self.display forNodes:@[node]];
        self.hoveredNodeIndex = NSNotFound;
    }
}

- (void)updateTargetForIndex:(int)index {
    
    Vector3 target;
    // update current node to default state
    if (self.targetNode != NSNotFound) {
        Node* node = [self.data nodeAtIndex:self.targetNode];
        
        [self.data.visualization updateDisplay:self.display forNodes:@[node]];
    }
    
    //set new node as targeted and change camera anchor point
    if (index != NSNotFound) {
        
        self.targetNode = index;
        Node* node = [self.data nodeAtIndex:self.targetNode];
        GLKVector3 origTarget = [self.data.visualization nodePosition:node];
        target = Vector3(origTarget.x, origTarget.y, origTarget.z);
        
        [self.display.nodes beginUpdate];
        [self.display.nodes updateNode:node.index color:[UIColor clearColor]];
        [self.display.nodes endUpdate];
        
        [self.data.visualization resetDisplay:self.display forSelectedNodes:@[node]];
        
        [self highlightConnections:node];
        
    } else {
        target = Vector3(0, 0, 0);
    }
    
    self.display.camera->setTarget(target);
}

#pragma mark - Connection Highlighting

-(void)highlightConnections:(Node*)node {
    if(node == nil) {
        [self clearHighlightLines];
        return;
    }
    
    NSMutableArray* filteredConnections = [NSMutableArray new];
    
    for(Connection* connection in self.data.connections) {
        if ((connection.first == node) || (connection.second == node) ) {
            [filteredConnections addObject:connection];
        }
    }
    
    if(filteredConnections.count == 0 || filteredConnections.count > 100) {
        [self clearHighlightLines];
        return;
    }
    
    std::shared_ptr<Lines> lines(new Lines(filteredConnections.count));
    lines->beginUpdate();
        
    UIColor* brightColourUI = SELECTED_CONNECTION_COLOR_BRIGHT;
    UIColor* dimColourUI = SELECTED_CONNECTION_COLOR_DIM;
    Colour brightColour;
    [brightColourUI getRed:&brightColour.r green:&brightColour.g blue:&brightColour.b alpha:&brightColour.a];
    Colour dimColour;
    [dimColourUI getRed:&dimColour.r green:&dimColour.g blue:&dimColour.b alpha:&dimColour.a];
    
    for(int i = 0; i < filteredConnections.count; i++) {
        Connection* connection = filteredConnections[i];
        Node* a = connection.first;
        Node* b = connection.second;
        
        if(node == a) {
            lines->updateLine(i, GLKVec3ToPoint([self.data.visualization nodePosition:a]), brightColour, GLKVec3ToPoint([self.data.visualization nodePosition:b]), dimColour);
        }
        else {
            lines->updateLine(i, GLKVec3ToPoint([self.data.visualization nodePosition:a]), dimColour, GLKVec3ToPoint([self.data.visualization nodePosition:b]), brightColour);
        }
    }
    
    lines->endUpdate();
    lines->setWidth(((filteredConnections.count < 20) ? 2 : 1) * ([HelperMethods deviceIsRetina] ? 2 : 1));
    self.display.highlightLines = lines;
}


- (void)clearHighlightLines {
    [self.highlightedNodes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self.highlightedNodes count]];
        if (idx != self.targetNode) {
            Node* node = [self.data nodeAtIndex:idx];
            [array addObject:node];
        }
        [self.data.visualization updateDisplay:self.display forNodes:array];
    }];
    self.display.highlightLines = nil;
}

-(void)highlightRoute:(NSArray*)nodeList {
    if(nodeList.count <= 1) {
        [self clearHighlightLines];
        return;
    }

    std::shared_ptr<Lines> lines(new Lines(nodeList.count - 1));
    lines->beginUpdate();
    
    UIColor* lineColorUI = UIColorFromRGB(0xffa300);
    Colour lineColor;
    [lineColorUI getRed:&lineColor.r green:&lineColor.g blue:&lineColor.b alpha:&lineColor.a];

    [self.display.nodes beginUpdate];
    for(int i = 0; i < nodeList.count - 1; i++) {
        Node* a = nodeList[i];
        Node* b = nodeList[i+1];
        [self.display.nodes updateNode:a.index color:SELECTED_NODE_COLOR];
        [self.display.nodes updateNode:b.index color:SELECTED_NODE_COLOR];
        [self.highlightedNodes addIndex:a.index];
        [self.highlightedNodes addIndex:b.index];
        lines->updateLine(i, GLKVec3ToPoint([self.data.visualization nodePosition:a]), lineColor, GLKVec3ToPoint([self.data.visualization nodePosition:b]), lineColor);
    }
    
    [self.display.nodes endUpdate];
    
    
    lines->endUpdate();
    lines->setWidth([HelperMethods deviceIsRetina] ? 10.0 : 5.0);
    
    self.display.highlightLines = lines;
    
    //highlight nodes
    
    
}

#pragma mark - Index/Position calculations

- (int)indexForNodeAtPoint:(CGPoint)pointInView {
    NSDate* date = [NSDate date];
    date = date;
    //get point in view and adjust it for viewport
    float xOld = pointInView.x;
    CGFloat xLoOld = 0;
    CGFloat xHiOld = self.display.camera->displayWidth();
    CGFloat xLoNew = -1;
    CGFloat xHiNew = 1;
    
    pointInView.x = (xOld-xLoOld) / (xHiOld-xLoOld) * (xHiNew-xLoNew) + xLoNew;
    
    float yOld = pointInView.y;
    CGFloat yLoOld = 0;
    CGFloat yHiOld = self.display.camera->displayHeight();
    CGFloat yLoNew = 1;
    CGFloat yHiNew = -1;
    
    pointInView.y = (yOld-yLoOld) / (yHiOld-yLoOld) * (yHiNew-yLoNew) + yLoNew;
    //transform point from screen- to object-space
    Vector3 cameraInObjectSpace = self.display.camera->cameraInObjectSpace(); //A
    Vector3 pointOnClipPlaneInObjectSpace = self.display.camera->applyModelViewToPoint(Vector2(pointInView.x, pointInView.y)); //B
    
    //do actual line-sphere intersection
    float xA, yA, zA;
    __block float xC, yC, zC;
    __block float r;
    __block float maxDelta = -1;
    __block int foundI = NSNotFound;
    
    xA = cameraInObjectSpace.getX();
    yA = cameraInObjectSpace.getY();
    zA = cameraInObjectSpace.getZ();
    
    Vector3 direction = pointOnClipPlaneInObjectSpace - cameraInObjectSpace; //direction = B - A
    Vector3 invertedDirection = Vector3(1.0f/direction.getX(), 1.0f/direction.getY(), 1.0f/direction.getZ());
    int sign[3];
    sign[0] = (invertedDirection.getX() < 0);
    sign[1] = (invertedDirection.getY() < 0);
    sign[2] = (invertedDirection.getZ() < 0);
    
    float a = powf((direction.getX()), 2)+powf((direction.getY()), 2)+powf((direction.getZ()), 2);
    
    IndexBox* box;
    for (int j = 0; j<[self.data.boxesForNodes count]; j++) {
        box = [self.data.boxesForNodes objectAtIndex:j];
        if ([box doesLineIntersectOptimized:Vec3ToGLK(cameraInObjectSpace) invertedDirection:Vec3ToGLK(invertedDirection) sign:sign]) {
            //            NSLog(@"intersects box %i at pos %@", j, NSStringFromGLKVector3(box.center));
            [box.indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                int i = idx;
                Node* node = [self.data nodeAtIndex:i];
                
                GLKVector3 nodePosition = [self.data.visualization nodePosition:node];
                xC = nodePosition.x;
                yC = nodePosition.y;
                zC = nodePosition.z;
                
                r = [self.data.visualization nodeSize:node]/2;
                r = MAX(r, 0.02);
                
                float b = 2*((direction.getX())*(xA-xC)+(direction.getY())*(yA-yC)+(direction.getZ())*(zA-zC));
                float c = powf((xA-xC), 2)+powf((yA-yC), 2)+powf((zA-zC), 2)-powf(r, 2);
                float delta = powf(b, 2)-4*a*c;
                if (delta >= 0) {
                    //                    NSLog(@"intersected node %i: %@, delta: %f", i, NSStringFromGLKVector3(nodePosition), delta);
                    Vector4 transformedNodePosition = self.display.camera->currentModelView() * Vector4(nodePosition.x, nodePosition.y, nodePosition.z, 1);
                    if ((delta > maxDelta) && (transformedNodePosition.getZ() < -0.1)) {
                        maxDelta = delta;
                        foundI = i;
                    }
                }
                
            }];
        }
    }
    
    //    NSLog(@"time for intersect: %f", [date timeIntervalSinceNow]);
    return foundI;
}


-(CGPoint)getCoordinatesForNodeAtIndex:(int)index {
    Node* node = [self.data nodeAtIndex:index];
    
    GLKVector3 nodePosition = [self.data.visualization nodePosition:node];
    
    Matrix4 mvp = self.display.camera->currentModelViewProjection();

    Vector4 proj = mvp * Vector4(nodePosition.x, nodePosition.y, nodePosition.z, 1.0f);
    proj /= proj.getW();

    Vector2 coordinates(((proj.getX() / 2.0f) + 1.0f) * self.display.camera->displayWidth(), ((proj.getY() / 2.0f) + 1.0f) * self.display.camera->displayHeight());
    
    CGPoint point = CGPointMake(coordinates.x,self.display.camera->displayHeight() - coordinates.y);
    
    //NSLog(@"%@", NSStringFromCGPoint(point));
    
    return point;
    
}

@end
