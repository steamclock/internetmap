//
//  ViewController.m
//  InternetMap
//

#import "ViewController.h"
#import "MapDisplay.h"
#import "MapData.h"
#import "Camera.h"
#import "Node.h"
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
#import "WEPopoverController.h"
#import "ErrorInfoView.h"

@interface ViewController ()
@property (strong, nonatomic) ASNRequest* request;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapDisplay* display;
@property (strong, nonatomic) MapData* data;

@property (strong, nonatomic) NSDate* lastIntersectionDate;

@property (strong, nonatomic) UITapGestureRecognizer* tapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* twoFingerTapRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer* longPressGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* doubleTapRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer* panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer* pinchRecognizer;

@property (nonatomic) CGPoint lastPanPosition;
@property (nonatomic) float lastScale;

@property (nonatomic) NSUInteger targetNode;
@property (nonatomic) int isCurrentlyFetchingASN;

@property (strong, nonatomic) SCTraceroute* tracer;

@property (strong) NSString* lastSearchIP;


/* UIKit Overlay */
@property (weak, nonatomic) IBOutlet UIButton* searchButton;
@property (weak, nonatomic) IBOutlet UIButton* youAreHereButton;
@property (weak, nonatomic) IBOutlet UIButton* visualizationsButton;
@property (weak, nonatomic) IBOutlet UIButton* timelineButton;
@property (weak, nonatomic) IBOutlet UISlider* timelineSlider;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* searchActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* youAreHereActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* visualizationsActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* timelineActivityIndicator;

@property (strong, nonatomic) IBOutlet UITextView* tracerouteOutput;
@property (strong, nonatomic) WEPopoverController* visualizationSelectionPopover;
@property (strong, nonatomic) WEPopoverController* nodeSearchPopover;
@property (strong, nonatomic) WEPopoverController* nodeInformationPopover;

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

- (void)startFetchingCurrentASN {
    if (!self.isCurrentlyFetchingASN) {
        self.isCurrentlyFetchingASN = YES;
        self.youAreHereActivityIndicator.hidden = NO;
        [self.youAreHereActivityIndicator startAnimating];
        self.youAreHereButton.hidden = YES;
        
        [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
            NSString* ip = [self fetchGlobalIP];
            if (!ip || [ip isEqualToString:@""]) {
                [[SCDispatchQueue mainQueue] dispatchAsync:^{
                    [self failedFetchingCurrentASN:@"Couldn't get global IP address"];
                }];
            } else {
                [ASNRequest fetchForAddresses:@[ip] responseBlock:^(NSArray *asn) {
                    NSNumber* myASN = asn[0];
                    if([myASN isEqual:[NSNull null]]) {
                        [self failedFetchingCurrentASN:@"ASN lookup failed"];
                    }
                    else {
                        [self finishedFetchingCurrentASN:[myASN intValue]];
                    }
                }];
            }
        }];
    }
}

- (void)finishedFetchingCurrentASN:(int)asn {
    NSLog(@"ASN fetched: %i", asn);
    self.isCurrentlyFetchingASN = NO;
    [self.youAreHereActivityIndicator stopAnimating];
    self.youAreHereActivityIndicator.hidden = YES;
    self.youAreHereButton.hidden = NO;
    [self selectNodeForASN:asn];
}

- (void)failedFetchingCurrentASN:(NSString*)error {
    NSLog(@"ASN fetching failed with error: %@", error);
    self.isCurrentlyFetchingASN = NO;
    [self.youAreHereActivityIndicator stopAnimating];
    self.youAreHereActivityIndicator.hidden = YES;
    self.youAreHereButton.hidden = NO;
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error locating your node", nil) message:error delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
    [alert show];
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
    self.longPressGestureRecognizer.enabled = NO;
    
    self.tapRecognizer.delegate = self;
    self.doubleTapRecognizer.delegate = self;
    self.twoFingerTapRecognizer.delegate = self;
    self.panRecognizer.delegate = self;
    self.pinchRecognizer.delegate = self;
    self.longPressGestureRecognizer.delegate = self;
    
    [self.view addGestureRecognizer:self.tapRecognizer];
    [self.view addGestureRecognizer:self.doubleTapRecognizer];
    [self.view addGestureRecognizer:self.twoFingerTapRecognizer];
    [self.view addGestureRecognizer:self.panRecognizer];
    [self.view addGestureRecognizer:self.pinchRecognizer];
    [self.view addGestureRecognizer:self.longPressGestureRecognizer];
    
    self.searchActivityIndicator.frame = CGRectMake(self.searchActivityIndicator.frame.origin.x, self.searchActivityIndicator.frame.origin.y, 30, 30);
    self.youAreHereActivityIndicator.frame = CGRectMake(self.youAreHereActivityIndicator.frame.origin.x, self.youAreHereActivityIndicator.frame.origin.y, 30, 30);
    self.visualizationsActivityIndicator.frame = CGRectMake(self.visualizationsActivityIndicator.frame.origin.x, self.visualizationsActivityIndicator.frame.origin.y, 30, 30);
    self.timelineActivityIndicator.frame = CGRectMake(self.timelineActivityIndicator.frame.origin.x, self.timelineActivityIndicator.frame.origin.y, 30, 30);
    
    //create error info view
    self.errorInfoView = [[ErrorInfoView alloc] initWithFrame:CGRectMake(10, 40, 300, 40)];
    [self.view addSubview:self.errorInfoView];
    
    self.targetNode = NSNotFound;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.display.camera.displaySize = self.view.bounds.size;
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

-(void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint translation = [gestureRecognizer translationInView:self.view];
        self.lastPanPosition = translation;
    }
    
    if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        
        CGPoint translation = [gestureRecognizer translationInView:self.view];
        CGPoint delta = CGPointMake(translation.x - self.lastPanPosition.x, translation.y - self.lastPanPosition.y);
        self.lastPanPosition = translation;
        
        [self.display.camera rotateRadiansX:delta.x * 0.01];
        [self.display.camera rotateRadiansY:delta.y * 0.01];
    }
}

-(void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        self.lastScale = gestureRecognizer.scale;
    }
    
    if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        float deltaZoom = gestureRecognizer.scale - self.lastScale;
        self.lastScale = gestureRecognizer.scale;
        [self.display.camera zoom:deltaZoom];
    }


}

-(void)handleTap:(UITapGestureRecognizer*)gestureRecognizer {
    
    [self handleSelectionAtPoint:[gestureRecognizer locationInView:self.view]];
    
}

- (void)handleSelectionAtPoint:(CGPoint)pointInView {
    NSDate* date = [NSDate date];
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
                
                float b = 2*((direction.x)*(xA-xC)+(direction.y)*(yA-yC)+(direction.z)*(zA-zC));
                float c = powf((xA-xC), 2)+powf((yA-yC), 2)+powf((zA-zC), 2)-powf(r, 2);
                float delta = powf(b, 2)-4*a*c;
                if (delta >= 0) {
                    NSLog(@"intersected node %i: %@, delta: %f", i, NSStringFromGLKVector3(nodePosition), delta);
                    GLKVector4 transformedNodePosition = GLKMatrix4MultiplyVector4(self.display.camera.currentModelView, GLKVector4MakeWithVector3(nodePosition, 1));
                    if ((delta > maxDelta) && (transformedNodePosition.z < -0.1)) {
                        maxDelta = delta;
                        foundI = i;
                    }
                }
                
            }];
        }
    }
    
    if (foundI != NSNotFound) {
        NSLog(@"selected node %i", foundI);
        self.lastSearchIP = nil;
        [self updateTargetForIndex:foundI];
    }else {
        NSLog(@"No node found, will bring up onscreen controls");
    }
    
    NSLog(@"time for intersection calculation: %f", [date timeIntervalSinceNow]);
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if(gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        if (!self.lastIntersectionDate || fabs([self.lastIntersectionDate timeIntervalSinceNow]) > 0.1) {
            [self handleSelectionAtPoint:[gesture locationInView:self.view]];
            self.lastIntersectionDate = [NSDate date];
        }
    }
}


- (void)handleTwoFingerTap:(UIGestureRecognizer*)gestureRecognizer {
    NSLog(@"Zoomed out");
    if (gestureRecognizer.numberOfTouches == 2) {
        float deltaZoom = -0.3;
        self.lastScale = self.lastScale+deltaZoom;
        
        [self.display.camera zoom:deltaZoom];
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecongizer {
    NSLog(@"Zoomed in");
    float deltaZoom = 0.3;
    self.lastScale = self.lastScale+deltaZoom;
    
    [self.display.camera zoom:deltaZoom];
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

-(void)highlightRoute:(NSArray*)nodeList {
    if(nodeList.count <= 1) {
        self.display.highlightLines = nil;
        
    }
    Lines* lines = [[Lines alloc] initWithLineCount:nodeList.count - 1];
    
    [lines beginUpdate];
    
    UIColor* lineColor = [UIColor redColor];
    
    for(int i = 0; i < nodeList.count - 2; i++) {
        Node* a = nodeList[i];
        Node* b = nodeList[i+1];
        
        [lines updateLine:i withStart:[self.data.visualization nodePosition:a] startColor:lineColor end:[self.data.visualization nodePosition:b] endColor:lineColor];
    }
    
    [lines endUpdate];
    
    self.display.highlightLines = lines;
}


- (void)updateTargetForIndex:(int)index {
    GLKVector3 target;

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
        [[self.display displayNodeAtIndex:node.index] setColor:[UIColor redColor]];
        
    } else {
        target = GLKVector3Make(0, 0, 0);
    }
    
    self.display.camera.target = target;
    
    [self displayInformationPopoverForCurrentNode];
}

//-(void)updateTargetforNode:(Node*)node {
//    
//    GLKVector3 target;
//    
//    NSLog(@"Node Index: %u", node.index);
//    
//    if (node) {
//        target = [self.data.visualization nodePosition:node];
//        [[self.display displayNodeAtIndex:node.index] setColor:[UIColor redColor]];
//    } else {
//        target = GLKVector3Make(0, 0, 0);
//    }
//    
//    self.display.camera.target = target;
//    [self displayInformationPopoverForCurrentNode];
//    
//}

-(CGPoint)getCoordinatesForNode{
    Node* node = [self.data nodeAtIndex:self.targetNode];
    
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
        NodeSearchViewController *searchController = [[NodeSearchViewController alloc] initWithStyle:UITableViewStylePlain];
        searchController.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchController];
        
        self.nodeSearchPopover = [[WEPopoverController alloc] initWithContentViewController:navController];
        [self.nodeSearchPopover setPopoverContentSize:searchController.contentSizeForViewInPopover];
        searchController.allItems = self.data.nodes;
    }
    [self.nodeSearchPopover presentPopoverFromRect:self.searchButton.bounds inView:self.searchButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)youAreHereButtonPressed:(id)sender {
    if ([HelperMethods deviceHasInternetConnection]) {
        [self startFetchingCurrentASN];
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
    Node* node = [self.data nodeAtIndex:self.targetNode];
    
    NodeInformationViewController *nodeInfo = [[NodeInformationViewController alloc] initWithNibName:@"NodeInformationViewController" bundle:nil];
    nodeInfo.delegate = self;
    //NSLog(@"ASN:%@, Text Desc: %@", node.asn, node.textDescription);
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nodeInfo];
    
    [self.nodeInformationPopover dismissPopoverAnimated:YES]; //this line is important, in case the popover for another node is already visible
    self.nodeInformationPopover = [[WEPopoverController alloc] initWithContentViewController:navController];
    self.nodeInformationPopover.passthroughViews = @[self.view];
    
    nodeInfo.asnLabel.text = node.asn;
    nodeInfo.textDescriptionLabel.text = node.textDescription;
    nodeInfo.nodeTypeLabel.text = node.typeString;
    
    
    // TODO: This should be called as a part of a camera object callback when the camera has finished zooming, not by 'waiting'
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
    {
        CGPoint center = [self getCoordinatesForNode];
       [self.nodeInformationPopover presentPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    });
    
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view != self.view) {
        return NO;
    }
    
    return YES;
}

#pragma mark - NodeSearch Delegate

-(void)nodeSelected:(Node*)node{
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    [self updateTargetForIndex:node.index];
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
}

#pragma mark - SCTraceroute Delegate

- (void)tracerouteDidFindHop:(NSString*)report{
    
    NSLog(@"%@", report);
    
    self.tracerouteOutput.text = [NSString stringWithFormat:@"%@\n%@", self.tracerouteOutput.text, report];
    
}
- (void)tracerouteDidComplete:(NSMutableArray*)hops{
    [self.tracer stop];
    self.tracer = nil;
    self.tracerouteOutput.text = [NSString stringWithFormat:@"%@\nTraceroute complete.", self.tracerouteOutput.text];
    
    [ASNRequest fetchForAddresses:hops responseBlock:^(NSArray *asns) {
        NSMutableArray* nodes = [NSMutableArray new];
        Node* last = nil;
        
        for(NSNumber* asn in asns) {
            if(![asn isEqual:[NSNull null]]) {
                Node* current = [self.data.nodesByAsn objectForKey:[NSString stringWithFormat:@"%i", [asn intValue]]];
                if(current && (current != last)) {
                    [nodes addObject:current];
                }
                
            }
        }
        
        [self highlightRoute:nodes];
    }];
}

#pragma mark - Node Info View Delegate

-(void)tracerouteButtonTapped{
    if ([HelperMethods deviceHasInternetConnection]) {
        self.tracerouteOutput.text = @"";
        self.tracerouteOutput.hidden = NO;
        
        if(self.lastSearchIP) {
            self.tracer = [SCTraceroute tracerouteWithAddress:self.lastSearchIP]; //we need ip for node!
            self.tracer.delegate = self;
            [self.tracer start];
        }
        else {
            Node* node = [self.data nodeAtIndex:self.targetNode];
            if ([node.asn intValue]) {
                [ASNRequest fetchForASN:[node.asn intValue] responseBlock:^(NSArray *asn) {
                    if (asn[0] != [NSNull null]) {
                        NSLog(@"starting tracerout with IP: %@", asn[0]);
                        self.tracer = [SCTraceroute tracerouteWithAddress:asn[0]];
                        self.tracer.delegate = self;
                        [self.tracer start];
                    }else {
                        NSLog(@"asn couldn't be resolved to IP");
                        //TODO: this error should be displayed in the actual traceroute interface
                        [self.errorInfoView setErrorString:@"ASN couldn't be resolved into IP"];
                    }
                }];
            }else {
                NSLog(@"asn is not an int");
                //TODO: this error should be displayed in the actual traceroute interface
                [self.errorInfoView setErrorString:@"The ASN associated with this node couln't be resolved into an integer."];
            }
        }
    }else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Internet connection" message:@"Please connect to the internet." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(void)doneTapped{
    [self.nodeInformationPopover dismissPopoverAnimated:YES];
    self.tracerouteOutput.hidden = YES;
}

@end
