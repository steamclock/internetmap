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
#import "IndexBox.h"
#import <sys/socket.h>
#import <ifaddrs.h>
#import "ErrorInfoView.h"
#import "Nodes.h"
#import "NodeTooltipViewController.h"
#import "MapController.h"
#import "LabelNumberBoxView.h"

#define MIN_TIMELINE_YEAR 1993
#define MAX_TIMELINE_YEAR 2012

BOOL UIGestureRecognizerStateIsActive(UIGestureRecognizerState state) {
    return state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateRecognized;
}
@interface ViewController ()
@property (strong, nonatomic) ASNRequest* request;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapController* controller;
@property (strong, nonatomic) MapDisplay* display;
@property (strong, nonatomic) MapData* data;

@property (strong, nonatomic) NSMutableArray* tracerouteHops;

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
@property (nonatomic) int isCurrentlyFetchingASN;

@property (strong, nonatomic) SCTraceroute* tracer;


@property (nonatomic) NSTimeInterval updateTime;


@property (nonatomic) int cachedCurrentASN;

/* UIKit Overlay */
@property (weak, nonatomic) IBOutlet UIButton* searchButton;
@property (weak, nonatomic) IBOutlet UIButton* youAreHereButton;
@property (weak, nonatomic) IBOutlet UIButton* visualizationsButton;
@property (weak, nonatomic) IBOutlet UIButton* timelineButton;
@property (weak, nonatomic) IBOutlet UISlider* timelineSlider;
@property (weak, nonatomic) IBOutlet UIButton* playButton;
@property (weak, nonatomic) IBOutlet UILabel* timelineLabel;
@property (weak, nonatomic) IBOutlet UIImageView* logo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* searchActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* youAreHereActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* visualizationsActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* timelineActivityIndicator;


@property (strong, nonatomic) WEPopoverController* visualizationSelectionPopover;
@property (strong, nonatomic) WEPopoverController* nodeSearchPopover;
@property (strong, nonatomic) WEPopoverController* nodeInformationPopover;
@property (weak, nonatomic) NodeInformationViewController* nodeInformationViewController; //this is weak because it's enough for us that the popover retains the controller. this is only a reference to update the ui of the infoViewController on traceroute callbacks, not to signify ownership
@property (strong, nonatomic) WEPopoverController* nodeTooltipPopover;
@property (strong, nonatomic) NodeTooltipViewController* nodeTooltipViewController;

@property (strong, nonatomic) ErrorInfoView* errorInfoView;

@end

@implementation ViewController

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark - View Setup

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
    
    self.controller = [MapController new];
    
    self.display = self.controller.display;
    self.display.camera.displaySize = self.view.bounds.size;
    
    self.data = self.controller.data;
    
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
    
    //setting activityIndicator sizes (positions are set in IB, but sizes can only be set in code)
    self.searchActivityIndicator.frame = CGRectMake(self.searchActivityIndicator.frame.origin.x, self.searchActivityIndicator.frame.origin.y, 30, 30);
    self.youAreHereActivityIndicator.frame = CGRectMake(self.youAreHereActivityIndicator.frame.origin.x, self.youAreHereActivityIndicator.frame.origin.y, 30, 30);
    self.visualizationsActivityIndicator.frame = CGRectMake(self.visualizationsActivityIndicator.frame.origin.x, self.visualizationsActivityIndicator.frame.origin.y, 30, 30);
    self.timelineActivityIndicator.frame = CGRectMake(self.timelineActivityIndicator.frame.origin.x, self.timelineActivityIndicator.frame.origin.y, 30, 30);
    
    //create error info view
    self.errorInfoView = [[ErrorInfoView alloc] initWithFrame:CGRectMake(10, 40, 300, 40)];
    [self.view addSubview:self.errorInfoView];
    
    
    //customize timeline slider
    [self.timelineSlider setMinimumTrackImage:[[UIImage imageNamed:@"timeline-barleft"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 11, 0, 1)] forState:UIControlStateNormal];
    [self.timelineSlider setMaximumTrackImage:[[UIImage imageNamed:@"timeline-barright"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 11)] forState:UIControlStateNormal];
    [self.timelineSlider setThumbImage:[UIImage imageNamed:@"timeline-handle"] forState:UIControlStateNormal];

    
    //setup timeline slider values
    float diff = MAX_TIMELINE_YEAR-MIN_TIMELINE_YEAR;
    diff /= 10;
    self.timelineSlider.minimumValue = 0;
    self.timelineSlider.maximumValue = diff;
    self.timelineSlider.value = diff;
    
    //customize timeline label
    self.timelineLabel.textColor = UI_ORANGE_COLOR;
    self.timelineLabel.font = [UIFont fontWithName:FONT_NAME_REGULAR size:50];
    self.timelineLabel.backgroundColor = [UIColor clearColor];
    self.timelineLabel.textAlignment = UITextAlignmentRight;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInformationPopoverForCurrentNode) name:@"cameraMovementFinished" object:nil];
    
    [self.display.camera resetIdleTimer];
    
    self.cachedCurrentASN = NSNotFound;
    [self precacheCurrentASN];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.display.camera.allowIdleAnimation = [self shouldDoIdleAnimation];
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

#pragma mark - Touch and GestureRecognizer handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.isHandlingLongPress = NO;

    [self.controller handleTouchDownAtPoint:[[touches anyObject] locationInView:self.view]];
}

-(void)handleTap:(UITapGestureRecognizer*)gestureRecognizer {
    [self.display.camera resetIdleTimer];
    [self dismissNodeInfoPopover];
    [self.controller selectHoveredNode];
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecongizer {
    [self.display.camera zoomAnimatedTo:self.display.camera.currentZoom+1.5 duration:1];
    [self.controller unhoverNode];
}

- (void)handleTwoFingerTap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.numberOfTouches == 2) {
        [self.display.camera zoomAnimatedTo:self.display.camera.currentZoom-1.5 duration:1];
        [self.controller unhoverNode];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture
{
    if(gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        if ((!self.lastIntersectionDate || fabs([self.lastIntersectionDate timeIntervalSinceNow]) > 0.01)) {
            self.isHandlingLongPress = YES;
            int i = [self.controller indexForNodeAtPoint:[gesture locationInView:self.view]];
            self.lastIntersectionDate = [NSDate date];
            if (i != NSNotFound) {
                
                Node* node = [self.data.nodes objectAtIndex:i];
                if (self.nodeTooltipViewController.node != node) {
                    self.nodeTooltipViewController = [[NodeTooltipViewController alloc] initWithNode:node];
                    
                    [self.nodeTooltipPopover dismissPopoverAnimated:NO];
                    self.nodeTooltipPopover = [[WEPopoverController alloc] initWithContentViewController:self.nodeTooltipViewController];
                    self.nodeTooltipPopover.passthroughViews = @[self.view];
                    CGPoint center = [self.controller getCoordinatesForNodeAtIndex:i];
                    [self.nodeTooltipPopover presentPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:NO];
                    [self.controller unhoverNode];
                    self.controller.hoveredNodeIndex = i;
                    [self.display.nodes beginUpdate];
                    [self.display.nodes updateNode:i color:SELECTED_NODE_COLOR];
                    [self.display.nodes endUpdate];
                }
            }
        }
    }else if(gesture.state == UIGestureRecognizerStateEnded) {
        [self.nodeTooltipPopover dismissPopoverAnimated:NO];
        [self dismissNodeInfoPopover];
        [self.controller selectHoveredNode];
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
            [self.controller unhoverNode];
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

- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
    [self.display.camera resetIdleTimer];
    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            [self.controller unhoverNode];
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
            [self.controller unhoverNode];
            self.lastScale = gestureRecognizer.scale;
        }else if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
        {
            float deltaZoom = gestureRecognizer.scale - self.lastScale;
            self.lastScale = gestureRecognizer.scale;
            [self.display.camera zoomByScale:deltaZoom];
        }else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan(gestureRecognizer.velocity)) {
                [self.display.camera stopMomentumZoom];
            }else {
                [self.display.camera startMomentumZoomWithVelocity:gestureRecognizer.velocity*0.5];
            }
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

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


- (BOOL)shouldDoIdleAnimation{
    return !self.tracerouteHops && !UIGestureRecognizerStateIsActive(self.longPressGestureRecognizer.state) && !UIGestureRecognizerStateIsActive(self.pinchRecognizer.state) && !UIGestureRecognizerStateIsActive(self.panRecognizer.state);
}


#pragma mark - Update selected/active node

- (void)updateTargetForIndex:(int)index {
    [self dismissNodeInfoPopover];
    [self.controller updateTargetForIndex:index];
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


#pragma mark - Action methods

-(IBAction)searchButtonPressed:(id)sender {
    if (!self.nodeSearchPopover) {
        NodeSearchViewController *searchController = [[NodeSearchViewController alloc] init];
        searchController.delegate = self;
        
        self.nodeSearchPopover = [[WEPopoverController alloc] initWithContentViewController:searchController];
        [self.nodeSearchPopover setPopoverContentSize:searchController.contentSizeForViewInPopover];
        self.nodeSearchPopover.delegate = self;
        searchController.allItems = self.data.nodes;
    }
    [self.nodeSearchPopover presentPopoverFromRect:self.searchButton.bounds inView:self.searchButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    self.searchButton.selected = YES;
}

-(IBAction)youAreHereButtonPressed:(id)sender {
    if ([HelperMethods deviceHasInternetConnection]) {
        //fetch current ASN and select node
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
            
            [ASNRequest fetchCurrentASNWithResponseBlock:^(NSArray *asn) {
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
    }else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Internet connection" message:@"Please connect to the internet." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(IBAction)visualizationsButtonPressed:(id)sender {
    if (!self.visualizationSelectionPopover) {
        VisualizationsTableViewController *tableforPopover = [[VisualizationsTableViewController alloc] initWithStyle:UITableViewStylePlain];
        self.visualizationSelectionPopover = [[WEPopoverController alloc] initWithContentViewController:tableforPopover];
        self.visualizationSelectionPopover.delegate = self;
        [self.visualizationSelectionPopover setPopoverContentSize:tableforPopover.contentSizeForViewInPopover];
    }
    [self.visualizationSelectionPopover presentPopoverFromRect:self.visualizationsButton.bounds inView:self.visualizationsButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    self.visualizationsButton.selected = YES;
}

-(IBAction)timelineButtonPressed:(id)sender {
    if (self.timelineSlider.hidden) {
        self.timelineSlider.hidden = NO;
        self.timelineButton.selected = YES;
        self.playButton.hidden = NO;
        self.timelineLabel.hidden = NO;

        self.searchButton.enabled = NO;
        self.youAreHereButton.enabled = NO;
        self.visualizationsButton.enabled = NO;
    } else {
        self.timelineSlider.hidden = YES;
        self.timelineButton.selected = NO;
        self.playButton.hidden = YES;
        self.timelineLabel.hidden = YES;

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
        if (node.index == self.controller.targetNode) {
            isSelectingCurrentNode = YES;
        }
    }

    Node* node = [self.data nodeAtIndex:self.controller.targetNode];
    
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
        
    CGPoint center = [self.controller getCoordinatesForNodeAtIndex:self.controller.targetNode];
    [self.nodeInformationPopover presentPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    
    if(isSelectingCurrentNode) {
        self.youAreHereButton.selected = YES;
    }
}

- (IBAction)playButtonPressed:(id)sender{

}

- (IBAction)timelineSliderValueChanged:(id)sender {
    self.timelineLabel.text = [NSString stringWithFormat:@"%i", (int)(MIN_TIMELINE_YEAR+self.timelineSlider.value*10)];

}

#pragma mark - Helper Methods: Current ASN precaching

- (void)precacheCurrentASN {
    
    void (^error)(void) = ^{
        //do nothing when precaching fails
    };
    
    
    [ASNRequest fetchCurrentASNWithResponseBlock:^(NSArray *asn) {
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


#pragma mark - NodeSearch Delegate

-(void)nodeSelected:(Node*)node{
    [self updateTargetForIndex:node.index];
}

-(void)selectNodeByHostLookup:(NSString*)host {
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    self.searchButton.selected = NO;

    if ([HelperMethods deviceHasInternetConnection]) {
        // TODO :detect an IP address and call fetchASNForIP directly rather than doing no-op lookup
        [self.searchActivityIndicator startAnimating];
        self.searchButton.hidden = YES;
        [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
            NSArray* addresses = [ASNRequest addressesForHostname:host];
            if(addresses.count != 0) {
                self.controller.lastSearchIP = addresses[0];
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

-(void)nodeSearchDelegateDone {
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    self.searchButton.selected = NO;
}

#pragma mark - NodeInfo delegate

- (void)dismissNodeInfoPopover {
    self.youAreHereButton.selected = NO;
    [self.nodeInformationPopover dismissPopoverAnimated:YES];
    [self.tracer stop];
    self.tracer = nil;
    [self.nodeInformationViewController.tracerouteTimer invalidate];
    if (self.tracerouteHops) {
        self.tracerouteHops = nil;
        [self.controller clearHighlightLines];
    }
}

#pragma mark - Node Info View Delegate

- (void)resizeNodeInfoPopover {

    CGPoint center = [self.controller getCoordinatesForNodeAtIndex:self.controller.targetNode];
    self.nodeInformationPopover.popoverContentSize = CGSizeZero;
    [self.nodeInformationPopover repositionPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

-(void)tracerouteButtonTapped{
    [self resizeNodeInfoPopover];
    
    self.tracerouteHops = [NSMutableArray array];
    self.controller.highlightedNodes = [[NSMutableIndexSet alloc] init];
    [self.display.camera zoomAnimatedTo:-3 duration:3];
    Node* node = [self.data nodeAtIndex:self.controller.targetNode];
    if (node.importance > 0.006) {
        [self.display.camera setRotationAnimatedTo:GLKMatrix4Identity duration:3];
    }else {
        [self.display.camera setRotationAnimatedTo:GLKMatrix4MakeRotation(M_PI, 0, 1, 0) duration:3];
    }
    
    if(self.controller.lastSearchIP) {
        self.tracer = [SCTraceroute tracerouteWithAddress:self.controller.lastSearchIP ofType:kICMP]; //we need ip for node!
        self.tracer.delegate = self;
        [self.tracer start];
    }
    else {
        Node* node = [self.data nodeAtIndex:self.controller.targetNode];
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
    [self dismissNodeInfoPopover];
}

#pragma mark - WEPopover Delegate

//Pretty sure these don't get called for NodeInfoPopover, but will get called for other popovers if we set delegates, yo
- (void)popoverControllerDidDismissPopover:(WEPopoverController *)popoverController{

}

- (BOOL)popoverControllerShouldDismissPopover:(WEPopoverController *)popoverController{
    self.visualizationsButton.selected = NO;
    self.searchButton.selected = NO;
    return YES;
}

#pragma mark - SCTraceroute Delegate

- (void)tracerouteDidFindHop:(NSString*)report withHops:(NSArray *)hops{
    
    NSLog(@"%@", report);
    
    self.nodeInformationViewController.tracerouteTextView.text = [[NSString stringWithFormat:@"%@\n%@", self.nodeInformationViewController.tracerouteTextView.text, report] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.nodeInformationViewController.box1 incrementNumber];
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
            [self.controller highlightRoute:self.tracerouteHops];
        }
        
        //update node info label for number of unique ASN Hops
        NSMutableSet* asnSet = [NSMutableSet set];
        for (Node* node in self.tracerouteHops) {
            [asnSet addObject:node.asn];
        }
        self.nodeInformationViewController.box2.numberLabel.text = [NSString stringWithFormat:@"%i", [asnSet count]];

    }];
}

- (void)tracerouteDidComplete:(NSMutableArray*)hops{
    [self.tracer stop];
    self.tracer = nil;
    self.nodeInformationViewController.tracerouteTextView.text = [[NSString stringWithFormat:@"%@\nTraceroute complete.", self.nodeInformationViewController.tracerouteTextView.text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.nodeInformationViewController.tracerouteTimer invalidate];
    [self.nodeInformationViewController tracerouteDone];
    [self resizeNodeInfoPopover];

    //highlight last node if not already highlighted
    Node* node = [self.tracerouteHops lastObject];
    if (node.index != self.controller.targetNode) {
        [self.tracerouteHops addObject:[self.data nodeAtIndex:self.controller.targetNode]];
        [self.controller highlightRoute:self.tracerouteHops];
    }

}

-(void)tracerouteDidTimeout{
    [self.tracer stop];
    self.tracer = nil;
    self.nodeInformationViewController.tracerouteTextView.text = [[NSString stringWithFormat:@"%@\nTraceroute completed with as many hops as we could contact.", self.nodeInformationViewController.tracerouteTextView.text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.nodeInformationViewController.tracerouteTimer invalidate];
    [self.nodeInformationViewController tracerouteDone];
    [self resizeNodeInfoPopover];

    //highlight last node if not already highlighted
    Node* node = [self.tracerouteHops lastObject];    
    if (node.index != self.controller.targetNode) {
        Node* targetNode = [self.data nodeAtIndex:self.controller.targetNode];
        [self.tracerouteHops addObject:targetNode];
        [self.controller highlightRoute:self.tracerouteHops];
    }
}

@end
