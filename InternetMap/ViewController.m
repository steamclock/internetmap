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
#import <dns_sd.h>

@interface ViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapDisplay* display;
@property (strong, nonatomic) MapData* data;

@property (strong, nonatomic) UITapGestureRecognizer* tapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* twoFingerTapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* doubleTapRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer* panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer* pinchRecognizer;

@property (nonatomic) CGPoint lastPanPosition;
@property (nonatomic) float lastScale;

@property (nonatomic) NSUInteger targetNode;
@property (nonatomic) int isCurrentlyFetchingASN;


/* UIKit Overlay */
@property (weak, nonatomic) IBOutlet UIButton* searchButton;
@property (weak, nonatomic) IBOutlet UIButton* youAreHereButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* youAreHereActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton* visualizationsButton;
@property (weak, nonatomic) IBOutlet UIButton* timelineButton;
@property (weak, nonatomic) IBOutlet UISlider* timelineSlider;
@property (strong, nonatomic) UIPopoverController* visualizationSelectionPopover;
@property (strong, nonatomic) UIPopoverController* nodeSearchPopover;
@property (strong, nonatomic) UIPopoverController* nodeInformationPopover;

@end

void callback (
               DNSServiceRef sdRef,
               DNSServiceFlags flags,
               uint32_t interfaceIndex,
               DNSServiceErrorType errorCode,
               const char *fullname,
               uint16_t rrtype,
               uint16_t rrclass,
               uint16_t rdlen,
               const void *rdata,
               uint32_t ttl,
               void *context ) {
    
    NSData* data = [NSData dataWithBytes:rdata length:strlen(rdata)+1];
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    int value;
    NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    BOOL success = [[NSScanner scannerWithString:[string stringByTrimmingCharactersInSet:nonDigits]] scanInteger:&value];
    if (success) {
        [[SCDispatchQueue mainQueue] dispatchAsync:^{
            [(__bridge ViewController*)context finishedFetchingCurrentASN:value];
        }];
    }else {
        [[SCDispatchQueue mainQueue] dispatchAsync:^{
            [(__bridge ViewController*)context failedFetchingCurrentASN:@"Couldn't resolve DNS."];
        }];
    }
    
}

@implementation ViewController

#pragma mark - Temporary! ASN fetching code, will move to Web fetching class

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
            }else {
                [self fetchASNForIP:ip];
            }
        }];
    }
}

- (void)fetchASNForIP:(NSString*)ip {
    NSArray* ipComponents = [ip componentsSeparatedByString:@"."];
    NSString* dnsString = [NSString stringWithFormat:@"origin.asn.cymru.com"];
    for (NSString* component in ipComponents) {
        dnsString = [NSString stringWithFormat:@"%@.%@", component, dnsString];
    }
    DNSServiceRef sdRef;
    DNSServiceErrorType res;
    
    res = DNSServiceQueryRecord(
                                &sdRef, 0, 0,
                                [dnsString cStringUsingEncoding:NSUTF8StringEncoding],
                                kDNSServiceType_TXT,
                                kDNSServiceClass_IN,
                                callback,
                                (__bridge void *)(self)
                                );
    
    if (res != kDNSServiceErr_NoError) {
        [[SCDispatchQueue mainQueue] dispatchAsync:^{
            [self failedFetchingCurrentASN:@"Couldn't resolve DNS."];
        }];
    }
    
    DNSServiceProcessResult(sdRef);
    DNSServiceRefDeallocate(sdRef);
}



- (NSString*)fetchGlobalIP {
    NSString* address = @"http://stage.steamclocksw.com/ip.php";
    NSURL *url = [[NSURL alloc] initWithString:address];
    NSError* error;
    NSString *ip = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
    return ip;
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
    for (int i = 0; i < [self.data.nodes count]; i++) {
        Node* node = [self.data.nodes objectAtIndex:i];
        if ([node.asn intValue] == asn) {
            [self updateTargetForIndex:i];
            break;
        }
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
    [self.data updateDisplay:self.display];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    self.twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    
    self.doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTapRecognizer.numberOfTapsRequired = 2;
    [self.tapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    
    [self.view addGestureRecognizer:self.tapRecognizer];
    [self.view addGestureRecognizer:self.doubleTapRecognizer];
    [self.view addGestureRecognizer:self.twoFingerTapRecognizer];
    [self.view addGestureRecognizer:self.panRecognizer];
    [self.view addGestureRecognizer:self.pinchRecognizer];
    
    
    self.youAreHereActivityIndicator.frame = CGRectMake(self.youAreHereActivityIndicator.frame.origin.x, self.youAreHereActivityIndicator.frame.origin.y, 30, 30);
    
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
    
    //TODO: Someone please comment the code in this function :)
    
    NSDate* date = [NSDate date];
    CGPoint pointInView = [gestureRecognizer locationInView:self.view];
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
    GLKVector3 cameraInObjectSpace = [self.display.camera cameraInObjectSpace]; //A
    GLKVector3 pointOnClipPlaneInObjectSpace = [self.display.camera applyModelViewToPoint:pointInView]; //B
    float xA, yA, zA;
    float xB, yB, zB;
    float xC, yC, zC;
    float r;
    float maxDelta = -1;
    int foundI = NSNotFound;

    xA = cameraInObjectSpace.x;
    yA = cameraInObjectSpace.y;
    zA = cameraInObjectSpace.z;
    
    xB = pointOnClipPlaneInObjectSpace.x;
    yB = pointOnClipPlaneInObjectSpace.y;
    zB = pointOnClipPlaneInObjectSpace.z;
    
    for (int i = 0; i < [self.data.nodes count]; i++) {
        Node* node = [self.data nodeAtIndex:i];
        
        GLKVector3 nodePosition = [self.data.visualization nodePosition:node];
        xC = nodePosition.x;
        yC = nodePosition.y;
        zC = nodePosition.z;
        
        r = [self.data.visualization nodeSize:node]/2;
        
        float a = powf((xB-xA), 2)+powf((yB-yA), 2)+powf((zB-zA), 2);
        float b = 2*((xB-xA)*(xA-xC)+(yB-yA)*(yA-yC)+(zB-zA)*(zA-zC));
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
    }
    
    if (foundI != NSNotFound) {
        NSLog(@"selected node %i", foundI);
        [self updateTargetForIndex:foundI];
    }else {
        NSLog(@"No node found, will bring up onscreen controls");
    }
    
    NSLog(@"time for intersection calculation: %f", [date timeIntervalSinceNow]);
    
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

-(IBAction)youAreHereButtonPressed:(id)sender {
    [self startFetchingCurrentASN];

}

-(IBAction)nextTarget:(id)sender {
    if(self.targetNode == NSNotFound) {
        [self updateTargetForIndex:0];
    }
    else {
        [self updateTargetForIndex:self.targetNode+1];
    }
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

-(IBAction)selectVisualization:(id)sender {
    if (!self.visualizationSelectionPopover) {
        VisualizationsTableViewController *tableforPopover = [[VisualizationsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tableforPopover];
        self.visualizationSelectionPopover.delegate = self;
        self.visualizationSelectionPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        [self.visualizationSelectionPopover setPopoverContentSize:tableforPopover.contentSizeForViewInPopover];
    }
    [self.visualizationSelectionPopover presentPopoverFromRect:self.visualizationsButton.bounds inView:self.visualizationsButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)searchNodes:(id)sender {
    if (!self.nodeSearchPopover) {
        NodeSearchViewController *searchController = [[NodeSearchViewController alloc] initWithStyle:UITableViewStylePlain];
        searchController.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchController];
        self.nodeSearchPopover.delegate = self;
        self.nodeSearchPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        [self.nodeSearchPopover setPopoverContentSize:searchController.contentSizeForViewInPopover];
        searchController.allItems = self.data.nodes;
    }
    [self.nodeSearchPopover presentPopoverFromRect:self.searchButton.bounds inView:self.searchButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
    
    //NSLog(@"ASN:%@, Text Desc: %@", node.asn, node.textDescription);
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:nodeInfo];
    
    self.nodeInformationPopover.delegate = self;
    self.nodeInformationPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
    
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

#pragma mark - NodeSearch Delegate

-(void)nodeSelected:(Node*)node{
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    [self updateTargetForIndex:node.index];
}

#pragma mark - UIPopoverController Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    // Beep boop.
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController{
    return YES;
}

@end
