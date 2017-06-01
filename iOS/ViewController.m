//
//  ViewController.m
//  InternetMap
//

#import "ViewController.h"
#import "StringListViewController.h"
#import "NodeSearchViewController.h"
#import "NodeInformationViewController.h"
#import "ASNRequest.h"
#import <dns_sd.h>
#import <sys/socket.h>
#import <ifaddrs.h>
#import "ErrorInfoView.h"
#import "NodeTooltipViewController.h"
#import "MapControllerWrapper.h"
#import "LabelNumberBoxView.h"
#import "NodeWrapper.h"
#import "TimelineInfoViewController.h"
#import "ExpandedSlider.h"
#import "FirstUseViewController.h"
#import "ContactFormViewController.h"
#import "CreditsViewController.h"

// Below import for testing BSD traceroute only
#import "main-traceroute.h"

//TODO: move this to a better place.
#define SELECTED_NODE_COLOR UIColorFromRGB(0xffa300)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

BOOL UIGestureRecognizerStateIsActive(UIGestureRecognizerState state) {
    return state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateRecognized;
}
@interface ViewController ()
@property (strong, nonatomic) ASNRequest* request;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapControllerWrapper* controller;
//@property (strong, nonatomic) MapData* data;

@property (nonatomic) NSMutableDictionary* tracerouteASNs;

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

@property (strong, nonatomic) SCTracerouteUtility* tracer;

@property (nonatomic) NSTimeInterval updateTime;

@property (nonatomic) NSString* cachedCurrentASN;

@property (nonatomic, strong) void (^afterViewReset)(void);

/* UIKit Overlay */
@property (weak, nonatomic) IBOutlet UIView* buttonContainerView;
@property (weak, nonatomic) IBOutlet UIButton* searchButton;
@property (weak, nonatomic) IBOutlet UIButton* infoButton;
@property (weak, nonatomic) IBOutlet UIButton* visualizationsButton;
@property (weak, nonatomic) IBOutlet UIButton* timelineButton;
@property (weak, nonatomic) IBOutlet UISlider* timelineSlider;
@property (weak, nonatomic) IBOutlet UIButton* playButton;
@property (weak, nonatomic) IBOutlet UIImageView* logo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* searchActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* visualizationsActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* timelineActivityIndicator;


@property (strong, nonatomic) WEPopoverController* visualizationSelectionPopover;
@property (strong, nonatomic) WEPopoverController* infoPopover;
@property (strong, nonatomic) WEPopoverController* nodeSearchPopover;
@property (strong, nonatomic) WEPopoverController* nodeInformationPopover;
@property (weak, nonatomic) NodeInformationViewController* nodeInformationViewController; //this is weak because it's enough for us that the popover retains the controller. this is only a reference to update the ui of the infoViewController on traceroute callbacks, not to signify ownership
@property (strong, nonatomic) WEPopoverController* timelinePopover;
@property (weak, nonatomic) TimelineInfoViewController* timelineInfoViewController;
@property (strong, nonatomic) WEPopoverController* nodeTooltipPopover;
@property (strong, nonatomic) NodeTooltipViewController* nodeTooltipViewController;

@property (strong, nonatomic) ErrorInfoView* errorInfoView;

@property (strong, nonatomic) NSArray* sortedYears;

@end

@implementation ViewController

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    self.controller = [MapControllerWrapper new];
    
    
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
    //self.youAreHereActivityIndicator.frame = CGRectMake(self.youAreHereActivityIndicator.frame.origin.x, self.youAreHereActivityIndicator.frame.origin.y, 30, 30);
    self.visualizationsActivityIndicator.frame = CGRectMake(self.visualizationsActivityIndicator.frame.origin.x, self.visualizationsActivityIndicator.frame.origin.y, 30, 30);
    self.timelineActivityIndicator.frame = CGRectMake(self.timelineActivityIndicator.frame.origin.x, self.timelineActivityIndicator.frame.origin.y, 30, 30);
    
    //create error info view
    self.errorInfoView = [[ErrorInfoView alloc] initWithFrame:CGRectMake(10, 70, 300, 40)];
    [self.view addSubview:self.errorInfoView];
    
    
    //customize timeline slider
    float cap = 12;
    UIImage* trackImage = [[UIImage imageNamed:@"timeline-track"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, cap, 0, cap)];
    [self.timelineSlider setMinimumTrackImage:trackImage forState:UIControlStateNormal];
    [self.timelineSlider setMaximumTrackImage:trackImage forState:UIControlStateNormal];
    
    [self.timelineSlider setThumbImage:[UIImage imageNamed:@"timeline-handle"] forState:UIControlStateNormal];
    [self.timelineSlider addTarget:self action:@selector(timelineSliderTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    
    if (!self.timelinePopover) {
        TimelineInfoViewController* tlv = [[TimelineInfoViewController alloc] init];
        self.timelineInfoViewController = tlv;
        self.timelinePopover = [[WEPopoverController alloc] initWithContentViewController:self.timelineInfoViewController];
        if ([HelperMethods deviceIsiPad]) {
            WEPopoverContainerViewProperties* prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.downArrowImageName = @"popupArrow-timeline";
            self.timelinePopover.containerViewProperties = prop;
        }else {
            WEPopoverContainerViewProperties* prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.downArrowImageName = nil;
            self.timelinePopover.containerViewProperties = prop;
        }
        
        self.timelinePopover.userInteractionEnabled = NO;
    }
    
    //setup timeline slider values
    self.sortedYears = [self.timelineInfoViewController.jsonDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSAssert([self.sortedYears count] >= 2, @"There is not enough data in the history.json file! At least data for two years is required");
    self.timelineSlider.minimumValue = 0;
    self.timelineSlider.maximumValue = self.sortedYears.count - 1;
    
    self.timelineSlider.value = self.sortedYears.count - 1;

    [self.sortedYears enumerateObjectsUsingBlock:^(NSString* year, NSUInteger idx, BOOL *stop) {
        if([year isEqualToString:@"2017"]) {
            self.timelineSlider.value = idx;
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInformationPopoverForCurrentNode) name:@"cameraMovementFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewResetDone) name:@"cameraResetFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissNodeInfoPopover) name:@"lostSelectedNode" object:nil];
    
    [self.controller resetIdleTimer];
    
    self.cachedCurrentASN = nil;
    [self precacheCurrentASN];
    
    [self.timelineButton setImage:[UIImage imageNamed:@"travelback_selected.png"] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [self performSelector:@selector(fadeOutLogo) withObject:nil afterDelay:4];
    
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return [HelperMethods deviceIsiPad] ? UIInterfaceOrientationIsLandscape(interfaceOrientation) : UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    bool shownFirstUse = [[NSUserDefaults standardUserDefaults] boolForKey:@"shownFirstUse"];
    
    if(!shownFirstUse) {
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"shownFirstUse"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self showFirstUse];
    }
    
    // When coming back from one of the modals (Help, credits, etc), we want to redisplay the info for the current node
    // because we hid it when we brought up the info menu popover
    [self displayInformationPopoverForCurrentNode];
}

- (void)fadeOutLogo {
    [UIView animateWithDuration:1 animations:^{
        self.logo.alpha = 0.3;
    }];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.controller.displaySize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height);
    [self.controller setAllowIdleAnimation:[self shouldDoIdleAnimation]];
    [self.controller update:[NSDate timeIntervalSinceReferenceDate]];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self.controller draw];
}

#pragma mark - Touch and GestureRecognizer handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch* touch = [touches anyObject];
    if (touch.view == self.buttonContainerView) {
        return;
    }
    self.isHandlingLongPress = NO;

    [self.controller handleTouchDownAtPoint:[touch locationInView:self.view]];
}

-(void)handleTap:(UITapGestureRecognizer*)gestureRecognizer {
    [self.controller resetIdleTimer];
    [self dismissNodeInfoPopover];
    if (![self.controller selectHoveredNode]) { //couldn't select node
        if(self.controller.targetNode != INT_MAX) {
            [self.controller deselectCurrentNode];
            [self.controller resetZoomAndRotationAnimatedForOrientation:![HelperMethods deviceIsiPad]];
        }
    }	
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecongizer {
    [self.controller zoomAnimated:self.controller.currentZoom+1.5 duration:1];
    [self.controller unhoverNode];
}

- (void)handleTwoFingerTap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.numberOfTouches == 2) {
        [self.controller zoomAnimated:self.controller.currentZoom-1.5 duration:1];
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
                
                NodeWrapper* node = [self.controller nodeAtIndex:i];
                if (self.nodeTooltipViewController.node != node) {
                    self.nodeTooltipViewController = [[NodeTooltipViewController alloc] initWithNode:node];
                    
                    int year = [self.sortedYears[(int)self.timelineSlider.value] intValue];
                    if((year > 2013) || (year < 2000)) {
                        self.nodeTooltipViewController.text = @"Simulated data";
                    }
                    
                    [self.nodeTooltipPopover dismissPopoverAnimated:NO];
                    self.nodeTooltipPopover = [[WEPopoverController alloc] initWithContentViewController:self.nodeTooltipViewController];
                    self.nodeTooltipPopover.passthroughViews = @[self.view];
                    CGPoint center = [self.controller getCoordinatesForNodeAtIndex:i];
                    [self.nodeTooltipPopover presentPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:NO];
                    [self.controller hoverNode:i];
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
    [self.controller resetIdleTimer];
    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            CGPoint translation = [gestureRecognizer translationInView:self.view];
            self.lastPanPosition = translation;
            [self.controller stopMomentumPan];
            [self.controller unhoverNode];
        }else if([gestureRecognizer state] == UIGestureRecognizerStateChanged) {
            
            CGPoint translation = [gestureRecognizer translationInView:self.view];
            CGPoint delta = CGPointMake(translation.x - self.lastPanPosition.x, translation.y - self.lastPanPosition.y);
            self.lastPanPosition = translation;
            
            [self.controller rotateRadiansX:delta.x * 0.01];
            [self.controller rotateRadiansY:delta.y * 0.01];
        } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan([gestureRecognizer velocityInView:self.view].x) || isnan([gestureRecognizer velocityInView:self.view].y)) {
                [self.controller stopMomentumPan];
            }else {
                CGPoint velocity = [gestureRecognizer velocityInView:self.view];
                [self.controller startMomentumPanWithVelocity:CGPointMake(velocity.x*0.002, velocity.y*0.002)];
            }
        }
    }
}

- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
    [self.controller resetIdleTimer];
    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            [self.controller unhoverNode];
            self.lastRotation = gestureRecognizer.rotation;
            [self.controller stopMomentumRotation];
        }else if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
        {
            float deltaRotation = -gestureRecognizer.rotation - self.lastRotation;
            self.lastRotation = -gestureRecognizer.rotation;
            [self.controller rotateRadiansZ:deltaRotation];
        } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan(gestureRecognizer.velocity)) {
                [self.controller stopMomentumRotation];
            } else {
                [self.controller startMomentumRotationWithVelocity:-gestureRecognizer.velocity*0.5];
            }

        }
    }
}

-(void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    [self.controller resetIdleTimer];
    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            [self.controller unhoverNode];
            self.lastScale = gestureRecognizer.scale;
        } else if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
        {
            float deltaZoom = gestureRecognizer.scale - self.lastScale;
            self.lastScale = gestureRecognizer.scale;
            [self.controller zoomByScale:deltaZoom];
        } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan(gestureRecognizer.velocity)) {
                [self.controller stopMomentumZoom];
            } else {
                [self.controller startMomentumZoomWithVelocity:gestureRecognizer.velocity*0.5];
            }
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view == self.view || touch.view == self.errorInfoView || [self.errorInfoView.subviews containsObject:touch.view]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    
    NSArray* simultaneous = @[self.panRecognizer, self.pinchRecognizer, self.rotationGestureRecognizer, self.longPressGestureRecognizer];
    if ([simultaneous containsObject:gestureRecognizer] && [simultaneous containsObject:otherGestureRecognizer]) {
        return YES;
    }
    
    return NO;
}


- (BOOL)shouldDoIdleAnimation{
    return !UIGestureRecognizerStateIsActive(self.longPressGestureRecognizer.state) && !UIGestureRecognizerStateIsActive(self.pinchRecognizer.state) && !UIGestureRecognizerStateIsActive(self.panRecognizer.state);
}


#pragma mark - Update selected/active node

- (void)updateTargetForIndex:(int)index {
    [self dismissNodeInfoPopover];
    [self nodeSearchDelegateDone];
    [self.controller updateTargetForIndex:index];
}


- (void)selectNodeForASN:(NSString*)asn {
    NodeWrapper* node = [self.controller nodeByASN:asn];
    if (node) {
        [self updateTargetForIndex:node.index];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error locating your node", nil) message:@"Couldn't find a node associated with your IP." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        [alert show];
    }
}


#pragma mark - Action methods

-(IBAction)searchButtonPressed:(id)sender {
    //TODO: find out if we can make this work in timeline mode
    if (self.timelineButton.selected) {
        [self leaveTimelineMode];
    }
    
    [self dismissNodeInfoPopover];
    
    if (!self.nodeSearchPopover) {
        NodeSearchViewController *searchController = [[NodeSearchViewController alloc] init];
        searchController.delegate = self;
        
        self.nodeSearchPopover = [[WEPopoverController alloc] initWithContentViewController:searchController];
        [self.nodeSearchPopover setPopoverContentSize:searchController.preferredContentSize];
        self.nodeSearchPopover.delegate = self;
        
        if (![HelperMethods deviceIsiPad]) {
            WEPopoverContainerViewProperties *prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.upArrowImageName = nil;
            self.nodeSearchPopover.containerViewProperties = prop;
        }
        searchController.allItems = [self.controller allNodes];
    }
    [self.nodeSearchPopover presentPopoverFromRect:self.searchButton.bounds inView:self.searchButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    self.searchButton.highlighted = NO;
    self.searchButton.selected = YES;
}

-(void)showFirstUse {
    FirstUseViewController* firstUse = [[FirstUseViewController alloc] initWithNibName:@"FirstUseViewController" bundle:[NSBundle mainBundle]];
    [self presentViewController:firstUse animated:YES completion:nil];
}

-(void)showContactForm {
    ContactFormViewController* contact = [[ContactFormViewController alloc] initWithNibName:@"ContactFormViewController" bundle:[NSBundle mainBundle]];
    [self presentViewController:contact animated:YES completion:nil];
}

-(void)showCredits {
    CreditsViewController* credits = [[CreditsViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
    [self presentViewController:credits animated:YES completion:nil];
}

-(void)selectYouAreHereNode {
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    self.searchButton.selected = NO;

    if ([HelperMethods deviceHasInternetConnection]) {
        //fetch current ASN and select node
        if (!self.isCurrentlyFetchingASN) {
            self.isCurrentlyFetchingASN = YES;
            self.searchActivityIndicator.hidden = NO;
            [self.searchActivityIndicator startAnimating];
            self.searchButton.hidden = YES;
                        
            [ASNRequest fetchCurrentASN:^(NSString *asn) {
                if(asn) {
                    self.cachedCurrentASN = asn;
                    [self selectNodeForASN:asn];
                }
                else {
                    [self.errorInfoView setErrorString:@"Couldn't look up current address."];
                }
                
                self.isCurrentlyFetchingASN = NO;
                [self.searchActivityIndicator stopAnimating];
                self.searchActivityIndicator.hidden = YES;
                self.searchButton.hidden = NO;
            }];
        }
    }else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Internet connection", nil) message:NSLocalizedString(@"Please connect to the internet.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(IBAction)visualizationsButtonPressed:(id)sender {
    //TODO: find out if we can make this work in timeline mode
    if (self.timelineButton.selected) {
        [self leaveTimelineMode];
    }
    
    [self dismissNodeInfoPopover];

    if (!self.visualizationSelectionPopover) {
        StringListViewController *tableforPopover = [[StringListViewController alloc] initWithStyle:UITableViewStylePlain];
        [tableforPopover setHighlightCurrentRow:YES];
        self.visualizationSelectionPopover = [[WEPopoverController alloc] initWithContentViewController:tableforPopover];
        self.visualizationSelectionPopover.delegate = self;
        tableforPopover.items = [self.controller visualizationNames];
        [self.visualizationSelectionPopover setPopoverContentSize:tableforPopover.preferredContentSize];
        if (![HelperMethods deviceIsiPad]) {
            WEPopoverContainerViewProperties *prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.upArrowImageName = nil;
            self.visualizationSelectionPopover.containerViewProperties = prop;
        }
        
        __weak ViewController* weakSelf = self;
        
        tableforPopover.selectedBlock = ^(int vis){
            [weakSelf setVisualization:vis];
            [weakSelf.visualizationSelectionPopover dismissPopoverAnimated:YES];
            weakSelf.visualizationsButton.selected = NO;
        };
    }
    [self.visualizationSelectionPopover presentPopoverFromRect:self.visualizationsButton.bounds inView:self.visualizationsButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    self.visualizationsButton.highlighted = NO;
    self.visualizationsButton.selected = YES;
}

-(void)setVisualization:(int) vis {
    __weak ViewController* weakSelf = self;
    self.afterViewReset = ^ {
        [weakSelf.controller setVisualization:vis];
    };
    
    [self resetView];
}

-(IBAction)infoButtonPressed:(id)sender {
    [self dismissNodeInfoPopover];

    if (!self.infoPopover) {
        StringListViewController *tableforPopover = [[StringListViewController alloc] initWithStyle:UITableViewStylePlain];
        [tableforPopover setHighlightCurrentRow:NO];
        self.infoPopover = [[WEPopoverController alloc] initWithContentViewController:tableforPopover];
        self.infoPopover.delegate = self;
        tableforPopover.items = @[ @"Help", @"Hosting & Cloud Services", @"Learn more at peer1.com", @"Credits" ];
        [self.infoPopover setPopoverContentSize:tableforPopover.preferredContentSize];
        if (![HelperMethods deviceIsiPad]) {
            WEPopoverContainerViewProperties *prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.upArrowImageName = nil;
            self.infoPopover.containerViewProperties = prop;
        }
        
        __weak ViewController* weakSelf = self;
        
        tableforPopover.selectedBlock = ^(int index){
            switch (index) {
                case 0: //help
                    [self showFirstUse];
                    break;
                case 1: //sales
                    [self showContactForm];
                    break;
                case 2: //URL
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.steamclock.com/blog/2013/03/mapping-the-internet/"]];
                    break;
                case 3: //credits
                    [self showCredits];
                    break;
                default: //can't happen
                    NSLog(@"Unexpected info index %zd!!", index);
            }
            
            [weakSelf.infoPopover dismissPopoverAnimated:YES];
            
            weakSelf.infoButton.selected = NO;
        };
    }
    [self.infoPopover presentPopoverFromRect:self.infoButton.bounds inView:self.infoButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    self.infoButton.highlighted = NO;
    self.infoButton.selected = YES;
}

-(IBAction)timelineButtonPressed:(id)sender {
    if (self.timelineSlider.hidden) {
        self.timelineSlider.hidden = NO;
        self.timelineButton.highlighted = NO;
        self.timelineButton.selected = YES;
        //self.playButton.hidden = NO;

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.logo.hidden = YES;
        }

        [self updateTimelineWithPopoverDismiss:NO];

        // Give the timeline slider view a poke to reinitialize it with the current date
        self.timelineInfoViewController.year = 0;
        [self timelineSliderValueChanged:nil];
    } else {
        [self leaveTimelineMode];
    }
}

-(void)leaveTimelineMode {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.logo.hidden = NO;
    }
    
    self.timelineSlider.hidden = YES;
    self.timelineButton.selected = NO;
    self.playButton.hidden = YES;
    
    self.timelineSlider.value = self.sortedYears.count - 1;
    
    [self.sortedYears enumerateObjectsUsingBlock:^(NSString* year, NSUInteger idx, BOOL *stop) {
        if([year isEqualToString:@"2017"]) {
            self.timelineSlider.value = idx;
        }
    }];
    
    [self updateTimelineWithPopoverDismiss:NO];
    [self.timelinePopover dismissPopoverAnimated:NO];
}

-(void)displayInformationPopoverForCurrentNode {
    NodeWrapper* node;
    
    if(self.controller.targetNode != INT_MAX) {
        node = [self.controller nodeAtIndex:self.controller.targetNode];
        if(!node) {
            return;
        }
    }
    else {
        return;
    }
    
    if (self.timelineSlider.hidden == NO) {
        BOOL simulated = NO;
        
        int year = [self.sortedYears[(int)self.timelineSlider.value] intValue];
        if((year > 2013) || (year < 2000)) {
            simulated = YES;
        }

        // in timeline mdoe, we just show tooltip-style popover
        [self.nodeInformationPopover dismissPopoverAnimated:NO];
        NodeTooltipViewController* content = [[NodeTooltipViewController alloc] initWithNode:node];
        self.nodeInformationPopover = [[WEPopoverController alloc] initWithContentViewController:content];
        
        if(simulated) {
            content.text = @"Simulated data";
        }
        
        self.nodeInformationPopover.passthroughViews = @[self.view];
        CGPoint center = [self.controller getCoordinatesForNodeAtIndex:self.controller.targetNode];
        [self.nodeInformationPopover presentPopoverFromRect:CGRectMake(center.x, center.y, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:NO];
    }
    else {
        //check if node is the current node
        BOOL isSelectingCurrentNode = NO;
        if (self.cachedCurrentASN) {
            NodeWrapper* node = [self.controller nodeByASN:[NSString stringWithFormat:@"%@", self.cachedCurrentASN]];
            if (node.index == self.controller.targetNode) {
                isSelectingCurrentNode = YES;
            }
        }

        NodeWrapper* node = [self.controller nodeAtIndex:self.controller.targetNode];
        
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
        UIPopoverArrowDirection dir = UIPopoverArrowDirectionLeft;

        if (![HelperMethods deviceIsiPad]) {
            WEPopoverContainerViewProperties* prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.upArrowImageName = nil;
            self.nodeInformationPopover.containerViewProperties = prop;
            dir = UIPopoverArrowDirectionUp;
        }
            
        [self.nodeInformationPopover presentPopoverFromRect:[self displayRectForNodeInfoPopover] inView:self.view permittedArrowDirections:dir animated:YES];
        
    }
}



- (IBAction)playButtonPressed:(id)sender{

}



- (IBAction)timelineSliderValueChanged:(id)sender {
    float snappedValue = roundf(self.timelineSlider.value);
    
    if(fabs(self.timelineSlider.value - snappedValue) > 0.01) {
        self.timelineSlider.value = snappedValue;
    }
        
    int year = [self.sortedYears[(int)snappedValue] intValue];
    
    CGRect thumbRect = [self.timelineSlider thumbRectForBounds:self.timelineSlider.bounds trackRect:[self.timelineSlider trackRectForBounds:self.timelineSlider.bounds] value:snappedValue];
    thumbRect = [self.view convertRect:thumbRect fromView:self.timelineSlider];
    if (![HelperMethods deviceIsiPad]) {
        thumbRect.origin.y -= 5;
    }
    
    if(year != self.timelineInfoViewController.year) {
        [self.timelinePopover dismissPopoverAnimated:NO];
        
        [self.timelineInfoViewController setYear:year];
        [self.timelinePopover setPopoverContentSize:self.timelineInfoViewController.preferredContentSize];
        [self.timelinePopover presentPopoverFromRect:thumbRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:NO];
    }
}

- (void)timelineSliderTouchUp:(id)sender {
    [self updateTimelineWithPopoverDismiss:YES];
}

//deselect node, reset zoom/rotate, and set the timeline point to match the slider.
-(void) updateTimelineWithPopoverDismiss:(BOOL)popoverDismiss {
    [self.timelineInfoViewController startLoad];
    
    __weak ViewController* weakSelf = self;
    self.afterViewReset = ^ {
        int year = [weakSelf.sortedYears[(int)weakSelf.timelineSlider.value] intValue];
        [weakSelf.controller setTimelinePoint:[NSString stringWithFormat:@"%d", year]];
        if(popoverDismiss) {
            [weakSelf.timelinePopover dismissPopoverAnimated:NO];
        }
    };
    
    [self resetView];
}

//deselect node and reset zoom/rotate. If you set the afterViewReset callback, it will be called when this finishes.
-(void) resetView {
    [self dismissNodeInfoPopover];
    [self.controller deselectCurrentNode];
    [self.controller resetZoomAndRotationAnimatedForOrientation:![HelperMethods deviceIsiPad]];
}

- (void)viewResetDone{
    if (self.afterViewReset) {
        [[SCDispatchQueue mainQueue] dispatchAfter:0.1 block:self.afterViewReset];
        self.afterViewReset = nil;
    }
}

#pragma mark - Helper Methods: Current ASN precaching

- (void)precacheCurrentASN {
    
    [ASNRequest fetchCurrentASN:^(NSString *asn) {
        if(asn) {
            self.cachedCurrentASN = asn;
        }
    }];
}


#pragma mark - NodeSearch Delegate

-(void)nodeSelected:(NodeWrapper*)node{
    [self updateTargetForIndex:node.index];
    [self nodeSearchDelegateDone];
}

-(void)selectNodeByHostLookup:(NSString*)host {
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    self.searchButton.selected = NO;

    if ([HelperMethods deviceHasInternetConnection]) {
        // TODO :detect when the host is an IP address and call fetchASNForIP directly rather than doing no-op lookup
        [self.searchActivityIndicator startAnimating];
        self.searchButton.hidden = YES;
        
        [ASNRequest fetchIPsForHostname:host response:^(NSArray *addresses) {
            if(addresses.count != 0) {
                self.controller.lastSearchIP = addresses[0];
                [ASNRequest fetchASNForIP:addresses[0] response:^(NSString *asn) {
                    [self.searchActivityIndicator stopAnimating];
                    self.searchButton.hidden = NO;
                    
                    if(asn) {
                        [self selectNodeForASN:asn];
                    }
                    else {
                        [self.errorInfoView setErrorString:@"Couldn't find ASN for host."];
                    }
                }];
            } else {
                [self.errorInfoView setErrorString:@"Couldn't find IP address for host."];
                [self.searchActivityIndicator stopAnimating];
                self.searchButton.hidden = NO;
            };
        }];
    } else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Internet connection", nil) message:NSLocalizedString(@"Please connect to the internet.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(void)nodeSearchDelegateDone {
    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    self.searchButton.selected = NO;
}

#pragma mark - NodeInfo delegate

- (void)dismissNodeInfoPopover {
    [self.tracer stop];
    self.tracer = nil;
    [self.nodeInformationPopover dismissPopoverAnimated:YES];
    [self.nodeInformationViewController.tracerouteTimer invalidate];
    if (self.tracerouteASNs) {
        self.tracerouteASNs = nil;
        [self.controller clearHighlightLines];
    }
}

#pragma mark - Node Info View Delegate

- (CGRect)displayRectForNodeInfoPopover{
    CGRect displayRect;
    
    if (![HelperMethods deviceIsiPad]) {
        displayRect = CGRectMake(160, self.controller.displaySize.height-self.nodeInformationViewController.preferredContentSize.height, 1, 1);
    }else {
        displayRect = CGRectMake(512.0f, 384.0f, 1, 1);
    }
        
    return displayRect;
}

- (void)resizeNodeInfoPopover {
    self.nodeInformationPopover.popoverContentSize = CGSizeZero;
    UIPopoverArrowDirection dir = [HelperMethods deviceIsiPad] ? UIPopoverArrowDirectionLeft : UIPopoverArrowDirectionUp;
    [self.nodeInformationPopover repositionPopoverFromRect:[self displayRectForNodeInfoPopover] inView:self.view permittedArrowDirections:dir animated:YES];
}

-(void)tracerouteButtonTapped{
    
    [self resizeNodeInfoPopover];
    
    self.tracerouteASNs = [NSMutableDictionary new];
    
    
    //zoom out and rotate camera to default orientation on app startup
    GLKMatrix4 zRotation = GLKMatrix4Identity;
    float zoom = -3;
    if (![HelperMethods deviceIsiPad]) {
        zRotation = GLKMatrix4MakeRotation(M_PI_2, 0, 0, 1);
        zoom = -8;
    }
    
    [self.controller zoomAnimated:zoom duration:3];
    
    NodeWrapper* node = [self.controller nodeAtIndex:self.controller.targetNode];
    if (node.importance > 0.006) {
        [self.controller rotateAnimated:zRotation duration:3];
    } else {
        [self.controller rotateAnimated:GLKMatrix4Multiply(GLKMatrix4MakeRotation(M_PI, 0, 1, 0), zRotation) duration:3];
    }
    
    if(self.controller.lastSearchIP && ![self.controller.lastSearchIP isEqualToString:@""]) {
        self.tracer = [SCTracerouteUtility tracerouteWithAddress:self.controller.lastSearchIP];
        self.tracer.delegate = self;
        [self.tracer start];
    } else {
        NodeWrapper* node = [self.controller nodeAtIndex:self.controller.targetNode];
        if (node.asn) {
            [ASNRequest fetchIPsForASN:node.asn response:^(NSArray *ips) {
                //We arbitrarily select any of the prefix IPs and try for a traceroute using it
                //We do this because we have no reliable way of knowing what machines will reslond to our ICMP packets
                //So, if we can contact even one machine within an ASN - any one at all - we know we travel through that ASN
                //We select randomly because why the heck not? It's all a guess as to which will respond. :)
                if ([ips count]) {
                    uint32_t rnd = arc4random_uniform((unsigned int)[ips count]);
                    NSString* arbitraryIP = [NSString stringWithFormat:@"%@", ips[rnd]];
                    NSLog(@"Starting traceroute with IP: %@", arbitraryIP );
                    self.tracer = [SCTracerouteUtility tracerouteWithAddress:arbitraryIP];
                    self.tracer.delegate = self;
                    [self.tracer start];
                } else {
                    [self couldntResolveIP];
                }
            }];
            
        } else {
            [self couldntResolveIP];
        }
    }
     
}

-(void)couldntResolveIP{
    self.nodeInformationViewController.tracerouteTextView.textColor = [UIColor redColor];
    self.nodeInformationViewController.tracerouteTextView.text = NSLocalizedString(@"Error: ASN couldn't be resolved into IP. Please try another node!", nil);
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.errorInfoView setErrorString:@"Failed to get IP for ASN."];
    }

    [self.nodeInformationViewController.tracerouteTimer invalidate];
    [self.nodeInformationViewController tracerouteDone];
    [self resizeNodeInfoPopover];
}

-(void)doneTapped{
    [self dismissNodeInfoPopover];
    [self.controller deselectCurrentNode];
    [self.controller resetZoomAndRotationAnimatedForOrientation:![HelperMethods deviceIsiPad]];
}

#pragma mark - WEPopover Delegate

//Pretty sure these don't get called for NodeInfoPopover, but will get called for other popovers if we set delegates, yo
- (void)popoverControllerDidDismissPopover:(WEPopoverController *)popoverController {
}

- (BOOL)popoverControllerShouldDismissPopover:(WEPopoverController *)popoverController{
    self.visualizationsButton.selected = NO;
    self.infoButton.selected = NO;
    self.searchButton.selected = NO;
    
    // Reshow the node info popover that we hid when the button was pressed
    [self displayInformationPopoverForCurrentNode];
    
    return YES;
}

#pragma mark - SCTracerouteUtility Delegate

-(void)displayHops:(NSArray*)ips withDestNode:(NodeWrapper*)destNode {
    NSMutableArray* mergedAsnHops = [NSMutableArray new];
    
    __block NSString* lastAsn = nil;
    __block NSInteger lastIndex = -1;
    
    // Put our ASN at the start of the list, just in case
    NodeWrapper* us = [self.controller nodeByASN:self.cachedCurrentASN];
    if(us) {
        [mergedAsnHops addObject:us];
        lastAsn = self.cachedCurrentASN;
    }
    
    [ips enumerateObjectsUsingBlock:^(NSString* ip, NSUInteger idx, BOOL *stop) {
        NSString* asn = self.tracerouteASNs[ip];
        if(asn && ![asn isEqual:[NSNull null]] && ![asn isEqualToString:lastAsn])  {
            lastAsn = asn;
            NodeWrapper* node = [self.controller nodeByASN:asn];
            if(node) {
                lastIndex = node.index;
                [mergedAsnHops addObject:node];
            }
        }
    }];
    
    if(destNode && (lastIndex != destNode.index)) {
        [mergedAsnHops addObject:destNode];
    }
    
    if ([mergedAsnHops count] >= 2) {
        [self.controller highlightRoute:mergedAsnHops];
    }
    
    self.nodeInformationViewController.box2.numberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[mergedAsnHops count]];
}

- (void)tracerouteDidFindHop:(NSString*)report withHops:(NSArray *)hops{
    
    NSLog(@"%@", report);
    
    self.nodeInformationViewController.tracerouteTextView.text = [[NSString stringWithFormat:@"%@\n%@", self.nodeInformationViewController.tracerouteTextView.text, report] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.nodeInformationViewController.box1 incrementNumber];
    
    if ([hops count] <= 0) {
        return;
    }
    
    [hops enumerateObjectsUsingBlock:^(NSString* ip, NSUInteger idx, BOOL *stop) {
        if(ip && ![ip isEqual:[NSNull null]] && (self.tracerouteASNs[ip] == nil)) {
            [ASNRequest fetchASNForIP:ip response:^(NSString *asn) {
                if(self.tracer == nil) {
                    // occasionally we get a rogue one after the trace is finished, we can probably ignore that
                    return;
                }
                
                if(asn && ![asn isEqual:[NSNull null]]) {
                    self.tracerouteASNs[ip] = asn;
                }
                else {
                    self.tracerouteASNs[ip] = [NSNull null];
                }
                
                [self displayHops:hops withDestNode:nil];
            }];
        }
    }];
}

- (void)tracerouteDidComplete:(NSMutableArray*)hops {
    [self.tracer stop];
    self.tracer = nil;
    self.nodeInformationViewController.tracerouteTextView.text = [[NSString stringWithFormat:@"%@\nTraceroute complete.", self.nodeInformationViewController.tracerouteTextView.text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.nodeInformationViewController.tracerouteTimer invalidate];
    [self.nodeInformationViewController tracerouteDone];
    [self resizeNodeInfoPopover];

    [self displayHops:hops withDestNode:[self.controller nodeAtIndex:self.controller.targetNode]];
}

-(void)tracerouteDidTimeout:(NSMutableArray*)hops {
    [self.tracer stop];
    self.tracer = nil;
    self.nodeInformationViewController.tracerouteTextView.text = [[NSString stringWithFormat:@"%@\nTraceroute completed with as many hops as we could contact.", self.nodeInformationViewController.tracerouteTextView.text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.nodeInformationViewController.tracerouteTimer invalidate];
    [self.nodeInformationViewController tracerouteDone];
    [self resizeNodeInfoPopover];

    [self displayHops:hops withDestNode:[self.controller nodeAtIndex:self.controller.targetNode]];
}

@end
