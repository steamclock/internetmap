//
//  ViewController.m
//  InternetMap
//

#import "ViewController.h"
#import "MapDisplay.h"
#import "MapData.h"
#import "Node.h"
#import "Connection.h"
#import "DefaultVisualization.h"
#import "VisualizationsTableViewController.h"
#import "NodeSearchViewController.h"
#import "NodeInformationViewController.h"
#import "ASNRequest.h"
#import <dns_sd.h>
#import "Lines.h"
#import "IndexBox.h"
#import <sys/socket.h>
#import <netdb.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "ErrorInfoView.h"
#import "Nodes.h"
#import "NodeTooltipViewController.h"

BOOL UIGestureRecognizerStateIsActive(UIGestureRecognizerState state) {
    return state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateRecognized;
}
@interface ViewController ()
@property (strong, nonatomic) ASNRequest* request;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapDisplay* display;
@property (strong, nonatomic) MapData* data;

@property (strong, nonatomic) NSMutableArray* tracerouteHops;
@property (strong, nonatomic) NSMutableIndexSet* highlightedNodes;

@property (strong, nonatomic) NSDate* lastIntersectionDate;
@property (assign, nonatomic) BOOL isHandlingLongPress;

@property (strong, nonatomic) UITapGestureRecognizer* tapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* twoFingerTapRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer* longPressGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* doubleTapRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer* panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer* pinchRecognizer;
@property (strong, nonatomic) UIRotationGestureRecognizer* rotationGestureRecognizer;

@property (nonatomic) CGPoint lastPanPosition;
@property (nonatomic) float lastRotation;

@property (nonatomic) float lastScale;
@property (nonatomic) NSUInteger targetNode;
@property (nonatomic) int isCurrentlyFetchingASN;

@property (strong, nonatomic) SCTraceroute* tracer;

@property (strong) NSString* lastSearchIP;

@property (nonatomic) NSTimeInterval updateTime;

@property (nonatomic) int hoveredNodeIndex;

@property (nonatomic) int cachedCurrentASN;

/* UIKit Overlay */
@property (weak, nonatomic) IBOutlet UIButton* searchButton;
@property (weak, nonatomic) IBOutlet UIButton* youAreHereButton;
@property (weak, nonatomic) IBOutlet UIButton* visualizationsButton;
@property (weak, nonatomic) IBOutlet UIButton* timelineButton;
@property (weak, nonatomic) IBOutlet UISlider* timelineSlider;
@property (weak, nonatomic) IBOutlet UIImageView* logo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* searchActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* youAreHereActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* visualizationsActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* timelineActivityIndicator;


@property (strong, nonatomic) WEPopoverController* visualizationSelectionPopover;
@property (strong, nonatomic) WEPopoverController* nodeSearchPopover;
@property (strong, nonatomic) WEPopoverController* nodeInformationPopover;
@property (unsafe_unretained, nonatomic) NodeInformationViewController* nodeInformationViewController; //this is weak because it's enough for us that the popover retains the controller. this is only a reference to update the ui of the infoViewController on traceroute callbacks, not to signify ownership
@property (strong, nonatomic) WEPopoverController* nodeTooltipPopover;
@property (strong, nonatomic) NodeTooltipViewController* nodeTooltipViewController;

@property (strong, nonatomic) ErrorInfoView* errorInfoView;

@end

@implementation ViewController

- (NSString*)fetchGlobalIP {
    NSString* address = @"http://stage.steamclocksw.com/ip.php";
    NSURL *url = [[NSURL alloc] initWithString:address];
    NSError* error;
    NSString *ip = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
    return ip;
}

- (void)startFetchingCurrentASNForYouAreHereButton {
    if (!self.isCurrentlyFetchingASN) {
        self.isCurrentlyFetchingASN = YES;
        self.youAreHereActivityIndicator.hidden = NO;
        [self.youAreHereActivityIndicator startAnimating];
        self.youAreHereButton.hidden = YES;
        
        void (^error)(void) = ^{
            NSString* error = @"ASN lookup failed";
            NSLog(@"ASN fetching failed with error: %@", error);
            self.isCurrentlyFetchingASN = NO;
            [self.youAreHereActivityIndicator stopAnimating];
            self.youAreHereActivityIndicator.hidden = YES;
            self.youAreHereButton.hidden = NO;
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error locating your node", nil) message:error delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
            [alert show];
        };
        
        [self fetchCurrentASNWithResponseBlock:^(NSArray *asn) {
            NSNumber* myASN = asn[0];
            if([myASN isEqual:[NSNull null]]) {
                error();
            }
            else {
                int asn = [myASN intValue];
                NSLog(@"ASN fetched: %i", asn);
                self.isCurrentlyFetchingASN = NO;
                [self.youAreHereActivityIndicator stopAnimating];
                self.youAreHereActivityIndicator.hidden = YES;
                self.youAreHereButton.hidden = NO;
                self.cachedCurrentASN = asn;
                [self selectNodeForASN:asn];
            }
        } errorBlock:error];
    }
}

- (void)fetchCurrentASNWithResponseBlock:(ASNResponseBlock)response errorBlock:(void(^)(void))error{
    [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
        NSString* ip = [self fetchGlobalIP];
        if (!ip || [ip isEqualToString:@""]) {
            error();
        } else {
            [ASNRequest fetchForAddresses:@[ip] responseBlock:response];
        }
    }];
}

- (void)startPrecachingCurrentASN {
    
    void (^error)(void) = ^{
        //do nothing when precaching fails
    };
    
    
    [self fetchCurrentASNWithResponseBlock:^(NSArray *asn) {
        NSNumber* myASN = asn[0];
        if([myASN isEqual:[NSNull null]]) {
            error();
        }
        else {
            int asn = [myASN intValue];
            self.cachedCurrentASN = asn;
        }
    } errorBlock:error];
}


- (void)selectNodeForASN:(int)asn {
    Node* node = [self.data.nodesByAsn objectForKey:[NSString stringWithFormat:@"%i", asn]];
    if (node) {
        [self updateTargetForIndex:node.index];
    }else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error locating your node", nil) message:@"Couldn't finde a node associated with your IP." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        [alert show];
    }
}


- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.preferredFramesPerSecond = 60.0f;

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:self.context];
    
    self.display = [MapDisplay new];
    self.display.camera.displaySize = self.view.bounds.size;
    self.display.camera.delegate = self;
    
    self.data = [MapData new];
    self.data.visualization = [DefaultVisualization new];
    
    [self.data loadFromFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"]];
    [self.data loadFromAttrFile:[[NSBundle mainBundle] pathForResource:@"as2attr" ofType:@"txt"]];
    [self.data loadAsInfo:[[NSBundle mainBundle] pathForResource:@"asinfo" ofType:@"json"]];
    [self.data updateDisplay:self.display];
    
    
    //add gesture recognizers
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    self.twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    
    self.doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTapRecognizer.numberOfTapsRequired = 2;
    [self.tapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    
    self.rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    
    self.tapRecognizer.delegate = self;
    self.doubleTapRecognizer.delegate = self;
    self.twoFingerTapRecognizer.delegate = self;
    self.panRecognizer.delegate = self;
    self.pinchRecognizer.delegate = self;
    self.longPressGestureRecognizer.delegate = self;
    self.rotationGestureRecognizer.delegate = self;
    
    [self.view addGestureRecognizer:self.tapRecognizer];
    [self.view addGestureRecognizer:self.doubleTapRecognizer];
    [self.view addGestureRecognizer:self.twoFingerTapRecognizer];
    [self.view addGestureRecognizer:self.panRecognizer];
    [self.view addGestureRecognizer:self.pinchRecognizer];
    [self.view addGestureRecognizer:self.longPressGestureRecognizer];
    [self.view addGestureRecognizer:self.rotationGestureRecognizer];
    
    self.searchActivityIndicator.frame = CGRectMake(self.searchActivityIndicator.frame.origin.x, self.searchActivityIndicator.frame.origin.y, 30, 30);
    self.youAreHereActivityIndicator.frame = CGRectMake(self.youAreHereActivityIndicator.frame.origin.x, self.youAreHereActivityIndicator.frame.origin.y, 30, 30);
    self.visualizationsActivityIndicator.frame = CGRectMake(self.visualizationsActivityIndicator.frame.origin.x, self.visualizationsActivityIndicator.frame.origin.y, 30, 30);
    self.timelineActivityIndicator.frame = CGRectMake(self.timelineActivityIndicator.frame.origin.x, self.timelineActivityIndicator.frame.origin.y, 30, 30);
    
    //create error info view
    self.errorInfoView = [[ErrorInfoView alloc] initWithFrame:CGRectMake(10, 40, 300, 40)];
    [self.view addSubview:self.errorInfoView];
    
    self.targetNode = NSNotFound;
    
    self.hoveredNodeIndex = NSNotFound;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInformationPopoverForCurrentNode) name:@"cameraMovementFinished" object:nil];
    
    [self.display.camera resetIdleTimer];
    
    self.cachedCurrentASN = NSNotFound;
    [self startPrecachingCurrentASN];
}



-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - GLKView and GLKViewController delegate methods
- (void)update
{
    [self.display update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    /*
    static int count = 0;
    count++;
    if(count == 30) {
        count = 0;
        NSLog(@"render: %.2fms", self.timeSinceLastDraw * 1000);
    }
     */
    
    [self.display draw];
}

- (void)unhoverNode {
    
    if (self.hoveredNodeIndex != NSNotFound && self.hoveredNodeIndex != self.targetNode) {
        Node* node = [self.data nodeAtIndex:self.hoveredNodeIndex];
        
        [self.data.visualization updateDisplay:self.display forNodes:@[node]];
        self.hoveredNodeIndex = NSNotFound;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    if (!self.display.camera.isMovingToTarget) {
            //cancel panning/zooming momentum
        [self.display.camera stopMomentumPan];
        [self.display.camera stopMomentumZoom];
        [self.display.camera stopMomentumRotation];
        self.isHandlingLongPress = NO;

        int i = [self indexForNodeAtPoint:[[touches anyObject] locationInView:self.view]];
        if (i != NSNotFound) {
            self.hoveredNodeIndex = i;
            [self.display.nodes beginUpdate];
            [self.display.nodes updateNode:i color:SELECTED_NODE_COLOR];
            [self.display.nodes endUpdate];
        }
    }
}

-(void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    [self.display.camera resetIdleTimer];
    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            CGPoint translation = [gestureRecognizer translationInView:self.view];
            self.lastPanPosition = translation;
            [self.display.camera stopMomentumPan];
            [self unhoverNode];
        }else if([gestureRecognizer state] == UIGestureRecognizerStateChanged) {
            
            CGPoint translation = [gestureRecognizer translationInView:self.view];
            CGPoint delta = CGPointMake(translation.x - self.lastPanPosition.x, translation.y - self.lastPanPosition.y);
            self.lastPanPosition = translation;
            
            [self.display.camera rotateRadiansX:delta.x * 0.01];
            [self.display.camera rotateRadiansY:delta.y * 0.01];
        } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan([gestureRecognizer velocityInView:self.view].x) || isnan([gestureRecognizer velocityInView:self.view].y)) {
                [self.display.camera stopMomentumPan];
            }else {
                CGPoint velocity = [gestureRecognizer velocityInView:self.view];
                [self.display.camera startMomentumPanWithVelocity:CGPointMake(velocity.x*0.002, velocity.y*0.002)];
            }        
        }
    }
}

- (BOOL)shouldDoIdleAnimation{
    return !self.tracerouteHops && !UIGestureRecognizerStateIsActive(self.longPressGestureRecognizer.state) && !UIGestureRecognizerStateIsActive(self.pinchRecognizer.state) && !UIGestureRecognizerStateIsActive(self.panRecognizer.state);
}

- (void)handleTouchDown:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (!self.display.camera.isMovingToTarget) {
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            //cancel panning/zooming momentum
            [self.display.camera stopMomentumPan];
            [self.display.camera stopMomentumZoom];
            [self.display.camera stopMomentumRotation];
            
            int i = [self indexForNodeAtPoint:[gestureRecognizer locationInView:self.view]];
            if (i != NSNotFound) {
                self.hoveredNodeIndex = i;
                [self.display.nodes beginUpdate];
                [self.display.nodes updateNode:i color:SELECTED_NODE_COLOR];
                [self.display.nodes endUpdate];
            }
        }
    }
}

- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
    [self.display.camera resetIdleTimer];
    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            [self unhoverNode];
            self.lastRotation = gestureRecognizer.rotation;
            [self.display.camera stopMomentumRotation];
        }else if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
        {
            float deltaRotation = -gestureRecognizer.rotation - self.lastRotation;
            self.lastRotation = -gestureRecognizer.rotation;
            [self.display.camera rotateRadiansZ:deltaRotation];
        } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan(gestureRecognizer.velocity)) {
                [self.display.camera stopMomentumRotation];
            }else {
                [self.display.camera startMomentumRotationWithVelocity:-gestureRecognizer.velocity*0.5];
            }

        }
    }
}

-(void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    [self.display.camera resetIdleTimer];
    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            [self unhoverNode];
            self.lastScale = gestureRecognizer.scale;
        }else if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
        {
            float deltaZoom = gestureRecognizer.scale - self.lastScale;
            self.lastScale = gestureRecognizer.scale;
            [self.display.camera zoom:deltaZoom];
        }else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan(gestureRecognizer.velocity)) {
                [self.display.camera stopMomentumZoom];
            }else {
                [self.display.camera startMomentumZoomWithVelocity:gestureRecognizer.velocity*0.5];
            }
        }
    }
}

-(void)handleTap:(UITapGestureRecognizer*)gestureRecognizer {
    [self.display.camera resetIdleTimer];
    [self selectHoveredNode];
}

- (void)selectHoveredNode {
    if (self.hoveredNodeIndex != NSNotFound) {
        self.lastSearchIP = nil;
        [self updateTargetForIndex:self.hoveredNodeIndex];
        self.hoveredNodeIndex = NSNotFound;
    }
}

- (int)indexForNodeAtPoint:(CGPoint)pointInView {
    NSDate* date = [NSDate date];
    date = date;
    //get point in view and adjust it for viewport
    float xOld = pointInView.x;
    CGFloat xLoOld = 0;
    CGFloat xHiOld = self.display.camera.displaySize.width;
    CGFloat xLoNew = -1;
    CGFloat xHiNew = 1;
    
    pointInView.x = (xOld-xLoOld) / (xHiOld-xLoOld) * (xHiNew-xLoNew) + xLoNew;
    
    float yOld = pointInView.y;
    CGFloat yLoOld = 0;
    CGFloat yHiOld = self.display.camera.displaySize.height;
    CGFloat yLoNew = 1;
    CGFloat yHiNew = -1;
    
    pointInView.y = (yOld-yLoOld) / (yHiOld-yLoOld) * (yHiNew-yLoNew) + yLoNew;
    //transform point from screen- to object-space
    GLKVector3 cameraInObjectSpace = [self.display.camera cameraInObjectSpace]; //A
    GLKVector3 pointOnClipPlaneInObjectSpace = [self.display.camera applyModelViewToPoint:pointInView]; //B
    
    //do actual line-sphere intersection
    float xA, yA, zA;
    __block float xC, yC, zC;
    __block float r;
    __block float maxDelta = -1;
    __block int foundI = NSNotFound;
    
    xA = cameraInObjectSpace.x;
    yA = cameraInObjectSpace.y;
    zA = cameraInObjectSpace.z;
    
    GLKVector3 direction = GLKVector3Subtract(pointOnClipPlaneInObjectSpace, cameraInObjectSpace); //direction = B - A
    GLKVector3 invertedDirection = GLKVector3Make(1.0f/direction.x, 1.0f/direction.y, 1.0f/direction.z);
    int sign[3];
    sign[0] = (invertedDirection.x < 0);
    sign[1] = (invertedDirection.y < 0);
    sign[2] = (invertedDirection.z < 0);
    
    float a = powf((direction.x), 2)+powf((direction.y), 2)+powf((direction.z), 2);
    
    IndexBox* box;
    for (int j = 0; j<[self.data.boxesForNodes count]; j++) {
        box = [self.data.boxesForNodes objectAtIndex:j];
        if ([box doesLineIntersectOptimized:cameraInObjectSpace invertedDirection:invertedDirection sign:sign]) {
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
                
                float b = 2*((direction.x)*(xA-xC)+(direction.y)*(yA-yC)+(direction.z)*(zA-zC));
                float c = powf((xA-xC), 2)+powf((yA-yC), 2)+powf((zA-zC), 2)-powf(r, 2);
                float delta = powf(b, 2)-4*a*c;
                if (delta >= 0) {
//                    NSLog(@"intersected node %i: %@, delta: %f", i, NSStringFromGLKVector3(nodePosition), delta);
                    GLKVector4 transformedNodePosition = GLKMatrix4MultiplyVector4(self.display.camera.currentModelView, GLKVector4MakeWithVector3(nodePosition, 1));
                    if ((delta > maxDelta) && (transformedNodePosition.z < -0.1)) {
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

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if(gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        if ((!self.lastIntersectionDate || fabs([self.lastIntersectionDate timeIntervalSinceNow]) > 0.01)) {
            self.isHandlingLongPress = YES;
            int i = [self indexForNodeAtPoint:[gesture locationInView:self.view]];
            self.lastIntersectionDate = [NSDate date];
            if (i != NSNotFound) {

                Node* node = [self.data.nodes objectAtIndex:i];
                if (self.nodeTooltipViewController.node != node) {
                    self.nodeTooltipViewController = [[NodeTooltipViewController alloc] initWithNode:node];
                    
                    [self.nodeTooltipPopover dismissPopoverAnimated:NO];
                    self.nodeTooltipPopover = [[WEPopoverController alloc] initWithContentViewController:self.nodeTooltipViewController];
                    self.nodeTooltipPopover.passthroughViews = @[self.view];
                    CGPoint center = [self getCoordinatesForNodeAtIndex:i];
                    [self.nodeTooltipPopover presentPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:NO];
                    [self unhoverNode];
                    self.hoveredNodeIndex = i;
                    [self.display.nodes beginUpdate];
                    [self.display.nodes updateNode:i color:SELECTED_NODE_COLOR];
                    [self.display.nodes endUpdate];
                }
            }
        }
    }else if(gesture.state == UIGestureRecognizerStateEnded) {
        [self.nodeTooltipPopover dismissPopoverAnimated:NO];
        [self selectHoveredNode];
    }
}


- (void)handleTwoFingerTap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.numberOfTouches == 2) {
        [self.display.camera zoomAnimatedTo:self.display.camera.currentZoom-1.5 duration:1];
        [self unhoverNode];
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecongizer {
    [self.display.camera zoomAnimatedTo:self.display.camera.currentZoom+1.5 duration:1];
    [self unhoverNode];
}


#pragma mark - Update selected/active node



-(IBAction)nextTarget:(id)sender {
    if(self.targetNode == NSNotFound) {
        [self updateTargetForIndex:0];
    }
    else {
        [self updateTargetForIndex:self.targetNode+1];
    }
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
    Lines* lines = [[Lines alloc] initWithLineCount:nodeList.count - 1];
    
    [lines beginUpdate];
    
    UIColor* lineColor = UIColorFromRGB(0xffa300);
    
    [self.display.nodes beginUpdate];
    for(int i = 0; i < nodeList.count - 1; i++) {
        Node* a = nodeList[i];
        Node* b = nodeList[i+1];
        [self.display.nodes updateNode:a.index color:SELECTED_NODE_COLOR];
        [self.display.nodes updateNode:b.index color:SELECTED_NODE_COLOR];
        [self.highlightedNodes addIndex:a.index];
        [self.highlightedNodes addIndex:b.index];
        [lines updateLine:i withStart:[self.data.visualization nodePosition:a] startColor:lineColor end:[self.data.visualization nodePosition:b] endColor:lineColor];
    }
    
    [self.display.nodes endUpdate];

    
    [lines endUpdate];
    
    lines.width = [HelperMethods deviceIsRetina] ? 10.0 : 5.0;

    self.display.highlightLines = lines;
    
    //highlight nodes
    

}

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
    
    Lines* lines = [[Lines alloc] initWithLineCount:filteredConnections.count];
    
    [lines beginUpdate];
    
    UIColor* brightColour = SELECTED_CONNECTION_COLOR_BRIGHT;
    UIColor* dimColour = SELECTED_CONNECTION_COLOR_DIM;
    
    for(int i = 0; i < filteredConnections.count; i++) {
        Connection* connection = filteredConnections[i];
        Node* a = connection.first;
        Node* b = connection.second;
        
        if(node == a) {
            [lines updateLine:i withStart:[self.data.visualization nodePosition:a] startColor:brightColour end:[self.data.visualization nodePosition:b] endColor:dimColour];
        }
        else {
            [lines updateLine:i withStart:[self.data.visualization nodePosition:a] startColor:dimColour end:[self.data.visualization nodePosition:b] endColor:brightColour];
        }
    }
    
    [lines endUpdate];
    lines.width = ((filteredConnections.count < 20) ? 2 : 1) * ([HelperMethods deviceIsRetina] ? 2 : 1);
    self.display.highlightLines = lines;
}


- (void)updateTargetForIndex:(int)index {
   
    GLKVector3 target;
    [self dismissNodeInfoPopover];

    // update current node to default state
    if (self.targetNode != NSNotFound) {
        Node* node = [self.data nodeAtIndex:self.targetNode];
        
        [self.data.visualization updateDisplay:self.display forNodes:@[node]];
    }
    
    //set new node as targeted and change camera anchor point
    if (index != NSNotFound) {
        
        self.targetNode = index;
        Node* node = [self.data nodeAtIndex:self.targetNode];
        target = [self.data.visualization nodePosition:node];

        [self.display.nodes beginUpdate];
        [self.display.nodes updateNode:node.index color:[UIColor clearColor]];
        [self.display.nodes endUpdate];
        
        [self.data.visualization resetDisplay:self.display forSelectedNodes:@[node]];
        
        [self highlightConnections:node];
        
    } else {
        target = GLKVector3Make(0, 0, 0);
    }
    
    self.display.camera.target = target;
}

-(CGPoint)getCoordinatesForNodeAtIndex:(int)index {
    Node* node = [self.data nodeAtIndex:index];
    
    int viewport[4] = {0, 0, self.display.camera.displaySize.width, self.display.camera.displaySize.height};
    
    GLKVector3 nodePosition = [self.data.visualization nodePosition:node];
    
    GLKMatrix4 model = [self.display.camera currentModelView];
    
    GLKMatrix4 projection = [self.display.camera currentProjection];
    
    GLKVector3 coordinates = GLKMathProject(nodePosition, model, projection, viewport);
    
    CGPoint point = CGPointMake(coordinates.x,self.display.camera.displaySize.height - coordinates.y);
    
    //NSLog(@"%@", NSStringFromCGPoint(point));
    
    return point;
    
}

#pragma mark - UIKit Controls Overlay

-(IBAction)searchNodes:(id)sender {
    if (!self.nodeSearchPopover) {
        NodeSearchViewController *searchController = [[NodeSearchViewController alloc] init];
        searchController.delegate = self;
        
        self.nodeSearchPopover = [[WEPopoverController alloc] initWithContentViewController:searchController];
        [self.nodeSearchPopover setPopoverContentSize:searchController.contentSizeForViewInPopover];
        searchController.allItems = self.data.nodes;
    }
    [self.nodeSearchPopover presentPopoverFromRect:self.searchButton.bounds inView:self.searchButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

-(IBAction)youAreHereButtonPressed:(id)sender {
    if ([HelperMethods deviceHasInternetConnection]) {
        [self startFetchingCurrentASNForYouAreHereButton];
    }else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Internet connection" message:@"Please connect to the internet." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(IBAction)selectVisualization:(id)sender {
    if (!self.visualizationSelectionPopover) {
        VisualizationsTableViewController *tableforPopover = [[VisualizationsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tableforPopover];
        self.visualizationSelectionPopover = [[WEPopoverController alloc] initWithContentViewController:navController];
        [self.visualizationSelectionPopover setPopoverContentSize:tableforPopover.contentSizeForViewInPopover];
    }
    [self.visualizationSelectionPopover presentPopoverFromRect:self.visualizationsButton.bounds inView:self.visualizationsButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)toggleTimelineMode:(id)sender {
    if (self.timelineSlider.hidden) {
        self.timelineSlider.hidden = NO;
        
        self.searchButton.enabled = NO;
        self.youAreHereButton.enabled = NO;
        self.visualizationsButton.enabled = NO;
    } else {
        self.timelineSlider.hidden = YES;
        
        self.searchButton.enabled = YES;
        self.youAreHereButton.enabled = YES;
        self.visualizationsButton.enabled = YES;
    }
}

-(void)displayInformationPopoverForCurrentNode {
    //check if node is the current node
    BOOL isSelectingCurrentNode = NO;
    if (self.cachedCurrentASN != NSNotFound) {
        Node* node = [self.data.nodesByAsn objectForKey:[NSString stringWithFormat:@"%i", self.cachedCurrentASN]];
        if (node.index == self.targetNode) {
            isSelectingCurrentNode = YES;
        }
    }

    Node* node = [self.data nodeAtIndex:self.targetNode];
    
    //careful, the local assignment first is necessary, because the property is a weak reference
    NodeInformationViewController* controller = [[NodeInformationViewController alloc] initWithNode:node isCurrentNode:isSelectingCurrentNode];
    self.nodeInformationViewController = controller;
    self.nodeInformationViewController.delegate = self;
    //NSLog(@"ASN:%@, Text Desc: %@", node.asn, node.textDescription);
    
    [self dismissNodeInfoPopover];
    //this line is important, in case the popover for another node is already visible and traceroute could be being performed
    self.nodeInformationPopover = [[WEPopoverController alloc] initWithContentViewController:self.nodeInformationViewController];
    self.nodeInformationPopover.delegate = self;
    self.nodeInformationPopover.passthroughViews = @[self.view];
        
    CGPoint center = [self getCoordinatesForNodeAtIndex:self.targetNode];
    [self.nodeInformationPopover presentPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view != self.view) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

    
    NSArray* simultaneous = @[self.panRecognizer, self.pinchRecognizer, self.rotationGestureRecognizer, self.longPressGestureRecognizer];
    if ([simultaneous containsObject:gestureRecognizer] && [simultaneous containsObject:otherGestureRecognizer]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - NodeSearch Delegate

-(void)nodeSelected:(Node*)node{
    [self dismissNodeInfoPopover];
    [self updateTargetForIndex:node.index];
}

-(void)nodeSearchDelegateDone {
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
}

// Get a set of IP addresses for a given host name
// Originally pulled from here: http://www.bdunagan.com/2009/11/28/iphone-tip-no-nshost/
// MIT License

+ (NSArray *)addressesForHostname:(NSString *)hostname {
    // Get the addresses for the given hostname.
    CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostname);
    
    BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostAddresses, nil);
    if (!isSuccess) {
        CFRelease(hostRef);
        return nil;
    }
    CFArrayRef addressesRef = CFHostGetAddressing(hostRef, nil);
    if (addressesRef == nil)  {
        CFRelease(hostRef);
        return nil;
    }
    // Convert these addresses into strings.
    char ipAddress[INET6_ADDRSTRLEN];
    NSMutableArray *addresses = [NSMutableArray array];
    CFIndex numAddresses = CFArrayGetCount(addressesRef);
    for (CFIndex currentIndex = 0; currentIndex < numAddresses; currentIndex++) {
        struct sockaddr *address = (struct sockaddr *)CFDataGetBytePtr(CFArrayGetValueAtIndex(addressesRef, currentIndex));
        
        if (address == nil) {
            CFRelease(hostRef);
            return nil;
        }

        getnameinfo(address, address->sa_len, ipAddress, INET6_ADDRSTRLEN, nil, 0, NI_NUMERICHOST);
        
        if (ipAddress == nil) {
            CFRelease(hostRef);
            return nil;
        }
        
        [addresses addObject:[NSString stringWithCString:ipAddress encoding:NSASCIIStringEncoding]];
    }
    
    CFRelease(hostRef);
    return addresses;
}

-(void)selectNodeByHostLookup:(NSString*)host {
    [self.nodeSearchPopover dismissPopoverAnimated:YES];

    if ([HelperMethods deviceHasInternetConnection]) {
        // TODO :detect an IP address and call fetchASNForIP directly rather than doing no-op lookup
        [self.searchActivityIndicator startAnimating];
        self.searchButton.hidden = YES;
        [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
            NSArray* addresses = [ViewController addressesForHostname:host];
            if(addresses.count != 0) {
                self.lastSearchIP = addresses[0];
                [ASNRequest fetchForAddresses:@[addresses[0]] responseBlock:^(NSArray *asn) {
                    [self.searchActivityIndicator stopAnimating];
                    self.searchButton.hidden = NO;
                    NSNumber* myASN = asn[0];
                    if([myASN isEqual:[NSNull null]]) {
                        [self.errorInfoView setErrorString:@"Couldn't resolve address for hostname."];
                    }
                    else {
                        [self selectNodeForASN:[myASN intValue]];
                    }
                }];
            }
        }];
    }else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Internet connection" message:@"Please connect to the internet." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
    
}

#pragma mark - NodeInfo delegate
- (void)dismissNodeInfoPopover {
    [self.nodeInformationPopover dismissPopoverAnimated:YES];
    [self.tracer stop];
    self.tracer = nil;
    if (self.tracerouteHops) {
        self.tracerouteHops = nil;
        [self clearHighlightLines];
    }
    
}

#pragma mark - SCTraceroute Delegate

- (void)tracerouteDidFindHop:(NSString*)report withHops:(NSArray *)hops{
    
    NSLog(@"%@", report);
    
    self.nodeInformationViewController.tracerouteTextView.text = [NSString stringWithFormat:@"%@\n%@", self.nodeInformationViewController.tracerouteTextView.text, report];
//    NSLog(@"%@", hops);

    [ASNRequest fetchForAddresses:@[[hops lastObject]] responseBlock:^(NSArray *asns) {
        Node* last = nil;
        
        for(NSNumber* asn in asns) {
            if(![asn isEqual:[NSNull null]]) {
                Node* current = [self.data.nodesByAsn objectForKey:[NSString stringWithFormat:@"%i", [asn intValue]]];
                if(current && (current != last)) {
                    [self.tracerouteHops addObject:current];
                }
            }
        }
        
        if ([self.tracerouteHops count] >= 2) {
            [self highlightRoute:self.tracerouteHops];
        }
        
    }];
}

- (void)tracerouteDidComplete:(NSMutableArray*)hops{
    [self.tracer stop];
    self.tracer = nil;
    self.nodeInformationViewController.tracerouteTextView.text = [NSString stringWithFormat:@"%@\nTraceroute complete.", self.nodeInformationViewController.tracerouteTextView.text];
    
    //highlight last node if not already highlighted
    Node* node = [self.tracerouteHops lastObject];
    if (node.index != self.targetNode) {
        [self.tracerouteHops addObject:[self.data nodeAtIndex:self.targetNode]];
        [self highlightRoute:self.tracerouteHops];
    }

}

-(void)tracerouteDidTimeout{
    [self.tracer stop];
    self.tracer = nil;
    self.nodeInformationViewController.tracerouteTextView.text = [NSString stringWithFormat:@"%@\nTraceroute completed with as many hops as we could contact.", self.nodeInformationViewController.tracerouteTextView.text];
    
    //highlight last node if not already highlighted
    Node* node = [self.tracerouteHops lastObject];    
    if (node.index != self.targetNode) {
        Node* targetNode = [self.data nodeAtIndex:self.targetNode];
        [self.tracerouteHops addObject:targetNode];
        [self highlightRoute:self.tracerouteHops];
    }
}

#pragma mark - Node Info View Delegate

-(void)tracerouteButtonTapped{
    CGPoint center = [self getCoordinatesForNodeAtIndex:self.targetNode];
    self.nodeInformationPopover.popoverContentSize = CGSizeZero;
    [self.nodeInformationPopover repositionPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    self.tracerouteHops = [NSMutableArray array];
    self.highlightedNodes = [[NSMutableIndexSet alloc] init];
    [self.display.camera zoomAnimatedTo:-3 duration:3];
    [self.display.camera rotateAnimatedTo:GLKMatrix4MakeRotation(M_PI, 0, 1, 0) duration:3];

    if(self.lastSearchIP) {
        self.tracer = [SCTraceroute tracerouteWithAddress:self.lastSearchIP ofType:kICMP]; //we need ip for node!
        self.tracer.delegate = self;
        [self.tracer start];
    }
    else {
        Node* node = [self.data nodeAtIndex:self.targetNode];
        if ([node.asn intValue]) {
            [ASNRequest fetchForASN:[node.asn intValue] responseBlock:^(NSArray *asn) {
                if (asn[0] != [NSNull null]) {
                    NSLog(@"starting tracerout with IP: %@", asn[0]);
                    self.tracer = [SCTraceroute tracerouteWithAddress:asn[0] ofType:kICMP];
                    self.tracer.delegate = self;
                    [self.tracer start];
                }else {
                    NSLog(@"asn couldn't be resolved to IP");
                    self.nodeInformationViewController.tracerouteTextView.textColor = [UIColor redColor];
                    self.nodeInformationViewController.tracerouteTextView.text = @"Error: ASN couldn't be resolved into IP.";
                }
            }];
        } else {
            NSLog(@"asn is not an int");
            self.nodeInformationViewController.tracerouteTextView.textColor = [UIColor redColor];
            self.nodeInformationViewController.tracerouteTextView.text = @"Error: ASN couldn't be resolved into IP.";
        }
    }
}

-(void)doneTapped{
    [self.nodeInformationPopover dismissPopoverAnimated:YES];
    [self.tracer stop];
    self.tracer = nil;
    if (self.tracerouteHops) {
        self.tracerouteHops = nil;
        [self clearHighlightLines];
    }
}

#pragma mark - WEPopover Delegate

//Pretty sure these don't get called for NodeInfoPopover, but will get called for other popovers if we set delegates, yo
- (void)popoverControllerDidDismissPopover:(WEPopoverController *)popoverController{
    
}
- (BOOL)popoverControllerShouldDismissPopover:(WEPopoverController *)popoverController{
    return YES;
}

@end
