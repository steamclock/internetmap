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
#import "NodeTooltipViewController.h"
#import "MapControllerWrapper.h"
#import "LabelNumberBoxView.h"
#import "NodeWrapper.h"
#import "TimelineInfoViewController.h"
#import "ExpandedSlider.h"
#import "FirstUseViewController.h"
#import <SafariServices/SafariServices.h>
#import "ARKit/ARKit.h"

#import "internetmap-Swift.h"

// Below import for testing BSD traceroute only
#import "main-traceroute.h"

//TODO: move this to a better place.
#define SELECTED_NODE_COLOR UIColorFromRGB(0xffa300)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

BOOL UIGestureRecognizerStateIsActive(UIGestureRecognizerState state) {
    return state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateRecognized;
}
@interface ViewController () <PingLocationsDelegate, SCPingUtilityDelegate>
@property (strong, nonatomic) ASNRequest* request;
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapControllerWrapper* controller;
//@property (strong, nonatomic) MapData* data;

@property (nonatomic) NSMutableDictionary* tracerouteASNs;

@property (strong, nonatomic) NSDate* lastIntersectionDate;
@property (assign, nonatomic) BOOL isHandlingLongPress;
@property (nonatomic, strong) NSString *asnToPingAutomatically;

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
@property (strong, nonatomic) SCPingUtility* pingUtility;

@property (nonatomic) NSTimeInterval updateTime;

@property (nonatomic) NSString* cachedCurrentASN;

@property (nonatomic, strong) void (^afterViewReset)(void);

/* UIKit Overlay */
@property (weak, nonatomic) IBOutlet UIView* buttonContainerView;
@property (weak, nonatomic) IBOutlet UIButton* searchButton;
@property (weak, nonatomic) IBOutlet UIButton* infoButton;
@property (weak, nonatomic) IBOutlet UIButton* visualizationsButton;
@property (weak, nonatomic) IBOutlet UIButton* timelineButton;
@property (weak, nonatomic) IBOutlet UIButton* arButton;
@property (weak, nonatomic) IBOutlet UIButton* repositionButton;
@property (weak, nonatomic) IBOutlet UISlider* timelineSlider;
@property (weak, nonatomic) IBOutlet UIButton* playButton;
@property (weak, nonatomic) IBOutlet UIButton* placeButton;
@property (weak, nonatomic) IBOutlet UILabel *searchingText;
@property (weak, nonatomic) IBOutlet UIImageView* logo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* searchActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* visualizationsActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* timelineActivityIndicator;
@property (weak, nonatomic) IBOutlet UIView *helpPopView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *helpPopViewPosition;
@property (weak, nonatomic) IBOutlet UIImageView *helpPopBackImage;
@property (weak, nonatomic) IBOutlet UILabel *helpPopLabel;
@property (strong, nonatomic) IBOutlet TimedMessageLabel* errorInfoView;

@property (strong, nonatomic) WEPopoverController* visualizationSelectionPopover;
@property (strong, nonatomic) WEPopoverController* infoPopover;
@property (strong, nonatomic) WEPopoverController* nodeSearchPopover;
@property (strong, nonatomic) WEPopoverController* nodeInformationPopover;
@property (weak, nonatomic) NodeInformationViewController* nodeInformationViewController; //this is weak because it's enough for us that the popover retains the controller. this is only a reference to update the ui of the infoViewController on traceroute callbacks, not to signify ownership
@property (strong, nonatomic) WEPopoverController* timelinePopover;
@property (weak, nonatomic) TimelineInfoViewController* timelineInfoViewController;
@property (strong, nonatomic) WEPopoverController* nodeTooltipPopover;
@property (strong, nonatomic) NodeTooltipViewController* nodeTooltipViewController;

@property (strong, nonatomic) NSArray* sortedYears;
@property (strong, nonatomic) NSString* defaultYear;
@property (strong, nonatomic) NSSet* simulatedYears;
@property (strong, nonatomic) NSArray *popMenuInfo;

@property (nonatomic) BOOL suppressCameraReset;

@property (nonatomic) ARMode arMode;
@property (nonatomic) BOOL arEnabled;
@property (nonatomic) BOOL renderEnabled;

@end

@implementation ViewController

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController: (UIPresentationController * ) controller {
    return UIModalPresentationNone;
}

-(void)hideHelpPopUp
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

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

    self.renderEnabled = TRUE;
    self.placeButton.hidden = TRUE;
    self.repositionButton.hidden = TRUE;
    self.searchingText.hidden = TRUE;

    // globe
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.preferredFramesPerSecond = 60.0f;
    [self setGlobalSettings];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.backgroundColor = [UIColor clearColor];

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
    //[self.view addGestureRecognizer:self.doubleTapRecognizer];
    //[self.view addGestureRecognizer:self.twoFingerTapRecognizer];
    [self.view addGestureRecognizer:self.panRecognizer];
    [self.view addGestureRecognizer:self.pinchRecognizer];
    [self.view addGestureRecognizer:self.longPressGestureRecognizer];
    [self.view addGestureRecognizer:self.rotationGestureRecognizer];
    
    //setting activityIndicator sizes (positions are set in IB, but sizes can only be set in code)
    self.searchActivityIndicator.frame = CGRectMake(self.searchActivityIndicator.frame.origin.x, self.searchActivityIndicator.frame.origin.y, 30, 30);
    //self.youAreHereActivityIndicator.frame = CGRectMake(self.youAreHereActivityIndicator.frame.origin.x, self.youAreHereActivityIndicator.frame.origin.y, 30, 30);
    self.visualizationsActivityIndicator.frame = CGRectMake(self.visualizationsActivityIndicator.frame.origin.x, self.visualizationsActivityIndicator.frame.origin.y, 30, 30);
    self.timelineActivityIndicator.frame = CGRectMake(self.timelineActivityIndicator.frame.origin.x, self.timelineActivityIndicator.frame.origin.y, 30, 30);

    // logo position
    if ([HelperMethods deviceIsiPad]) {
        self.logo.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-self.logo.frame.size.width-30, 34, self.logo.frame.size.width, self.logo.frame.size.height);
    }
    
    //customize timeline slider
    if ([HelperMethods deviceIsiPad]) {
        CGFloat xPos = ([[UIScreen mainScreen] bounds].size.width - self.timelineSlider.frame.size.width)/2;
        CGFloat yPos = [[UIScreen mainScreen] bounds].size.height - 80;
        CGRect timelinePosition = CGRectMake(xPos, yPos, self.timelineSlider.frame.size.width, self.timelineSlider.frame.size.height);
        self.timelineSlider.frame = timelinePosition;
    }
    
    
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
            // prop.downArrowImageName = @"popupArrow-timeline";
            prop.downArrowImageName = @"popoverArrowDownSimple";
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
        if([year isEqualToString:self.defaultYear]) {
            self.timelineSlider.value = idx;
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayInformationPopoverForCurrentNode) name:@"cameraMovementFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewResetDone) name:@"cameraResetFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissNodeInfoPopover) name:@"lostSelectedNode" object:nil];
    
    [self.controller resetIdleTimer];
    
    self.cachedCurrentASN = nil;
    [self precacheCurrentASN];
    
    [self performSelector:@selector(fadeOutLogo) withObject:nil afterDelay:4];
        
    // help pop up
    [self helpPopCheckSetUp];
    self.helpPopView.hidden = YES;

    self.arButton.hidden = ![ARConfiguration isSupported];

    self.repositionButton.layer.borderWidth = 1.0f;
    self.repositionButton.layer.borderColor = UI_BLUE_COLOR.CGColor;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    bool shownFirstUse = [[NSUserDefaults standardUserDefaults] boolForKey:@"shownFirstUse"];
    
    if(!shownFirstUse) {
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"shownFirstUse"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self showFirstUse];
    } else {
        [self helpPopCheckOrMenuSelected:nil];
    }
    
    // When coming back from one of the modals (Help, credits, etc), we want to redisplay the info for the current node
    // because we hid it when we brought up the info menu popover
    [self displayInformationPopoverForCurrentNode];
    
}

- (void)fadeOutLogo {
    [UIView animateWithDuration:1 animations:^{
        self.logo.alpha = 0.45;
    }];
}

- (void)setGlobalSettings {
    NSString* json = [[NSBundle mainBundle] pathForResource:@"globalSettings" ofType:@"json"];
    NSDictionary* settingsDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:json] options:0 error:nil];
    self.defaultYear = [settingsDict objectForKey:@"defaultYear"];
    
    NSArray *simulatedYearArr = [settingsDict valueForKeyPath:@"simulatedYears"];
    self.simulatedYears = [NSSet setWithArray:simulatedYearArr];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.controller.logicalDisplaySize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height);
    [self.controller setAllowIdleAnimation:[self shouldDoIdleAnimation]];
    [self.controller update:[NSDate timeIntervalSinceReferenceDate]];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    self.controller.physicalDisplaySize = CGSizeMake(view.drawableWidth, view.drawableHeight);

    if(self.renderEnabled) {
        [self.controller draw];
    }
    else {
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
}

#pragma mark - AR

-(IBAction)arButtonPressed:(id)sender {
    if (self.timelineButton.selected) {
        [self leaveTimelineMode];
    }

    [((AppDelegate*)([UIApplication sharedApplication].delegate)).rootVC toggleAR];

    self.arButton.selected = self.arEnabled;
}

- (void)overrideCamera:(matrix_float4x4)transform projection:(matrix_float4x4)projection modelPos:(GLKVector3)modelPos {
    [self.controller overrideCameraTransform:transform projection:projection modelPos:modelPos];
}

- (void)setARMode:(ARMode)mode {
    BOOL wasEnabled = self.arEnabled;
    self.arEnabled = mode != ARModeDisabled;
    self.arMode = mode;

    if(wasEnabled != self.arEnabled) {
        if(self.arEnabled) {
            [self checkCameraAuthorization];
        }
        [self.controller clearCameraOverride];
        [self forceResetView];
        [self.controller enableAR:self.arEnabled];
    }

    self.renderEnabled = mode != ARModeSearching;
    self.placeButton.hidden = mode != ARModePlacing;
    self.searchingText.hidden = mode != ARModeSearching;
    self.repositionButton.hidden = mode != ARModeViewing;

    BOOL allowButtons = mode == ARModeViewing || mode == ARModeDisabled;
    self.searchButton.enabled = allowButtons;
    self.visualizationsButton.enabled = allowButtons;
    self.timelineButton.enabled = allowButtons;
    self.infoButton.enabled = allowButtons;
}

-(IBAction)placeButtonPressed:(id)sender {
    [((AppDelegate*)([UIApplication sharedApplication].delegate)).rootVC endPlacement];
}

-(IBAction)repositionButtonPressed:(id)sender {
    [((AppDelegate*)([UIApplication sharedApplication].delegate)).rootVC startPlacement];
}

- (float)nearPlane {
    return [self.controller nearPlane];
}

- (float)farPlane {
    return [self.controller farPlane];
}

-(void)checkCameraAuthorization {
    AVAuthorizationStatus auth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

    NSString* text = NSLocalizedString(@"Move the camera across a flat surface to place the map", nil);

    if(auth != AVAuthorizationStatusAuthorized) {
        text = NSLocalizedString(@"Please allow camera access for Internet Map in Settings", nil);
    }

    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    NSRange range = NSMakeRange(0, text.length);

    [paragraphStyle setLineHeightMultiple:1.15];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [attrString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"NexaLight" size:20] range:range];
    [attrString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];

    self.searchingText.attributedText = attrString;
}

#pragma mark - Touch and GestureRecognizer handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch* touch = [touches anyObject];
    if (touch.view == self.buttonContainerView) {
        return;
    }

    self.isHandlingLongPress = NO;

    if (self.arMode == ARModeSearching || self.arMode == ARModePlacing) {
        NSLog(@"Skipping touch handling due to current AR mode: %zd", self.arMode);
        return;
    }

    [self.controller handleTouchDownAtPoint:[touch locationInView:self.view]];
}

-(void)handleTap:(UITapGestureRecognizer*)gestureRecognizer {
    [self.controller resetIdleTimer];
    [self dismissNodeInfoPopover];
    [self helpPopCheckOrMenuSelected:nil];

    if (![self.controller selectHoveredNode]) { //couldn't select node
        if(self.controller.targetNode != INT_MAX) {
            [self.controller deselectCurrentNode];
            [self resetVisualization];
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
            if (i != NSNotFound && [self.controller isWithinMaxNodeIndex:i]) {

                NodeWrapper* node = [self.controller nodeAtIndex:i];

                if (self.nodeTooltipViewController.node != node) {
                    self.nodeTooltipViewController = [[NodeTooltipViewController alloc] initWithNode:node];
                    
                    NSString* year = self.sortedYears[(int)self.timelineSlider.value];
                    if([self.simulatedYears containsObject:year]) {
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
    } else if(gesture.state == UIGestureRecognizerStateEnded) {
        [self.nodeTooltipPopover dismissPopoverAnimated:NO];
        [self dismissNodeInfoPopover];
        [self.controller selectHoveredNode];
    }
     
}

// Clockwise ordering of the interface orientations, for calculating number of steps betwene two of them
-(int)orderedOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait: return 0;
        case UIInterfaceOrientationLandscapeLeft: return 1;
        case UIInterfaceOrientationPortraitUpsideDown: return 2;
        case UIInterfaceOrientationLandscapeRight: return 3;
        default: return 0;
    }
}

// Caclulate a rotation between one interface orientation and another
-(CGAffineTransform)rotationForOrientationChangeFrom:(UIInterfaceOrientation)from to:(UIInterfaceOrientation)to
{
    int quarterTurns = ([self orderedOrientation:to] + 4) - [self orderedOrientation:from];
    return CGAffineTransformMakeRotation((M_PI / 2) * (float)(quarterTurns));
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

            if(self.arEnabled) {
                // If device is rotated but UI hasn't (not all orientations are supported), transform the pan gesture to
                // the oriented device space, so the rotation will still make sense on the AR map that is a fixed orientation
                // in the real world
                UIDeviceOrientation device = [UIDevice currentDevice].orientation;
                UIInterfaceOrientation from = [UIApplication sharedApplication].statusBarOrientation;
                if(device != UIDeviceOrientationFaceUp && device != UIDeviceOrientationFaceDown) {
                    UIInterfaceOrientation to = (UIInterfaceOrientation)device;
                    CGAffineTransform rotate = [self rotationForOrientationChangeFrom:from to:to];
                    delta = CGPointApplyAffineTransform(delta, rotate);
                }

                delta.y = 0;
            }

            [self.controller rotateRadiansX:delta.x * 0.01];
            [self.controller rotateRadiansY:delta.y * 0.01];

        } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            if (isnan([gestureRecognizer velocityInView:self.view].x) || isnan([gestureRecognizer velocityInView:self.view].y)) {
                [self.controller stopMomentumPan];
            }else {
                CGPoint velocity = [gestureRecognizer velocityInView:self.view];
                [self.controller startMomentumPanWithVelocity:CGPointMake(velocity.x*0.002, self.arEnabled ? 0.0 : velocity.y*0.002)];
            }
        }
    }
}

- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
    if(self.arEnabled) {
        return;
    }

    [self.controller resetIdleTimer];

    if (!self.isHandlingLongPress) {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
            [self.controller unhoverNode];
            self.lastRotation = gestureRecognizer.rotation;
            [self.controller stopMomentumRotation];
        } else if([gestureRecognizer state] == UIGestureRecognizerStateChanged) {
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
    if(self.arEnabled) {
        return;
    }

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
    return !UIGestureRecognizerStateIsActive(self.longPressGestureRecognizer.state) && !UIGestureRecognizerStateIsActive(self.pinchRecognizer.state) && !UIGestureRecognizerStateIsActive(self.panRecognizer.state) && !self.arEnabled;
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
        [self showErrorAlert:NSLocalizedString(@"Error locating your node", nil) withMessage: NSLocalizedString(@"Couldn't find a node associated with your IP.", nil)];
    }
}

-(void)showErrorAlert:(NSString*)title withMessage:(NSString*)message {
    // Don't try presenting error if something else is already presented.
    if (self.presentedViewController) { return; }
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
                                                     [alert dismissViewControllerAnimated:YES completion:nil]; }];
    [alert addAction:okAA];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Action methods

-(IBAction)searchButtonPressed:(id)sender {
    //TODO: find out if we can make this work in timeline mode
    
    if (self.timelineButton.selected) {
        [self leaveTimelineMode];
    }
    
    [self helpPopCheckOrMenuSelected:_searchButton];
    
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
    self.searchButton.highlighted = YES;
    self.searchButton.selected = YES;
    
}

-(void)showFirstUse {
    FirstUseViewController* firstUse = [[FirstUseViewController alloc] initWithNibName:@"FirstUseViewController" bundle:[NSBundle mainBundle]];
    [self presentViewController:firstUse animated:YES completion:nil];
}

-(void)showCredits:(NSString *)informationType {
    CreditsViewController* credits = [[CreditsViewController alloc] initWithNibName:nil bundle:[NSBundle mainBundle]];
    credits.delegate = self;
    credits.informationType = informationType;
    [self presentViewController:credits animated:YES completion:nil];
}

-(void)showPingLocations {
    PingLocationsViewController *pingLocations = [[PingLocationsViewController alloc] init];
    pingLocations.delegate = self;
    [self presentViewController:pingLocations animated:YES completion:nil];
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
        [self showErrorAlert:NSLocalizedString(@"No Internet connection", nil) withMessage: NSLocalizedString(@"Please connect to the internet.", nil)];
    }
}

-(IBAction)visualizationsButtonPressed:(id)sender {
    //TODO: find out if we can make this work in timeline mode
    if (self.timelineButton.selected) {
        [self leaveTimelineMode];
    }
    [self updateTimelineWithPopoverDismiss:NO];
    [self helpPopCheckOrMenuSelected:_visualizationsButton];

    if (!self.visualizationSelectionPopover) {
        StringListViewController *tableforPopover = [[StringListViewController alloc] initWithStyle:UITableViewStylePlain];
        [tableforPopover setHighlightCurrentRow:YES];
        self.visualizationSelectionPopover = [[WEPopoverController alloc] initWithContentViewController:tableforPopover];
        self.visualizationSelectionPopover.delegate = self;
        tableforPopover.items = [self.controller visualizationNames];
        if (![HelperMethods deviceIsiPad]) {
            WEPopoverContainerViewProperties *prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.upArrowImageName = nil;
            self.visualizationSelectionPopover.containerViewProperties = prop;
            [self.visualizationSelectionPopover setPopoverContentSize:tableforPopover.preferredContentSize];
        } else {
            [self.visualizationSelectionPopover setPopoverContentSize:CGSizeMake(300, 87)];
        }
        
        __weak ViewController* weakSelf = self;
        
        tableforPopover.selectedBlock = ^(int vis){
            [weakSelf setVisualization:vis];
            [weakSelf.visualizationSelectionPopover dismissPopoverAnimated:YES];
            weakSelf.visualizationsButton.selected = NO;
            [self helpPopCheckOrMenuSelected:nil];
            
            // Reset view to recenter target
            [self resetVisualization];
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

    if (self.timelineButton.selected) {
        [self leaveTimelineMode];
    }

    self.nodeInformationPopover.view.hidden = YES;
    
    self.timelineButton.selected = NO;
    self.visualizationsButton.selected = NO;
    self.searchButton.selected = NO;

    if (!self.infoPopover) {
        StringListViewController *tableforPopover = [[StringListViewController alloc] initWithStyle:UITableViewStylePlain];
        [tableforPopover setHighlightCurrentRow:NO];
        self.infoPopover = [[WEPopoverController alloc] initWithContentViewController:tableforPopover];
        self.infoPopover.delegate = self;
        
        tableforPopover.items = @[ @"Introduction", @"About Cogeco Peer 1", @"Ping Cogeco Peer 1", @"Contact Cogeco Peer 1", @"Open Source", @"Privacy Policy", @"Credits" ];
                        
        if (![HelperMethods deviceIsiPad]) {
            WEPopoverContainerViewProperties *prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.upArrowImageName = nil;
            self.infoPopover.containerViewProperties = prop;
            [self.infoPopover setPopoverContentSize:tableforPopover.preferredContentSize];
        } else {
            [self.infoPopover setPopoverContentSize:CGSizeMake(340, 220)];
        }

        __weak ViewController* weakSelf = self;
        
        tableforPopover.selectedBlock = ^(int index){
            switch (index) {
                case 0: //introduction
                {
                    [weakSelf showFirstUse];
                    break;
                }
                case 1: //about
                {
                    [weakSelf showCredits:@"about"];
                    break;
                }
                case 2: //ping
                {
                    [weakSelf showPingLocations];
                    break;
                }
                case 3: //contact
                {
                    [weakSelf showCredits:@"contact"];
                    break;
                }
                case 4: //open source
                {
                    [weakSelf showInSafariWithURL:@"https://github.com/steamclock/internetmap"];
                    break;
                }
                case 5: //privacy policy
                {
                    [weakSelf showInSafariWithURL:@"https://www.cogecopeer1.com/legal/privacy-policy/"];
                    break;
                }
                case 6: //credits
                {
                    [weakSelf showCredits:@"credit"];
                    break;
                }
                default: //can't happen
                    NSLog(@"Unexpected info index %d!!", index);
            }

            [weakSelf.infoPopover dismissPopoverAnimated:YES];
            
            weakSelf.infoButton.selected = NO;
        };
    }
  
    [self.infoPopover presentPopoverFromRect:self.infoButton.bounds inView:self.infoButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    self.infoButton.highlighted = NO;
    self.infoButton.selected = YES;
   
}

- (void) showInSafariWithURL:(NSString *)urlstring {
    NSURL *url = [NSURL URLWithString:urlstring];
    SFSafariViewController *safariView = [[SFSafariViewController alloc] initWithURL:url];
    safariView.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:safariView animated:YES completion:nil];
}

- (void) moreAboutCogeco {
    [self showInSafariWithURL:@"http://cogecopeer1.com"];
}

-(IBAction)timelineButtonPressed:(id)sender {
    [self updateTimelineWithPopoverDismiss:NO];

    if (self.timelineSlider.hidden) {
        self.timelineSlider.hidden = NO;
        self.timelineButton.highlighted = NO;
        self.timelineButton.selected = YES;
        //self.playButton.hidden = NO;

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.logo.hidden = YES;
        }

        [self helpPopCheckOrMenuSelected:_timelineButton];
        [self updateTimelineWithPopoverDismiss:NO];

        // Give the timeline slider view a poke to reinitialize it with the current date
        self.timelineInfoViewController.year = 0;
        [self timelineSliderValueChanged:nil];

        self.repositionButton.hidden = true;
    } else {
        [self leaveTimelineMode];
    }
}

-(void)leaveTimelineMode {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.logo.hidden = NO;
    }

    self.repositionButton.hidden = self.arMode != ARModeViewing;

    self.timelineSlider.hidden = YES;
    self.timelineButton.selected = NO;
    self.playButton.hidden = YES;
    
    self.timelineSlider.value = self.sortedYears.count - 1;
    
    [self.sortedYears enumerateObjectsUsingBlock:^(NSString* year, NSUInteger idx, BOOL *stop) {
        if([year isEqualToString:self.defaultYear]) {
            self.timelineSlider.value = idx;
        }
    }];
    
    [self updateTimelineWithPopoverDismiss:NO];
    [self.timelinePopover dismissPopoverAnimated:NO];
}

-(void)displayInformationPopoverForCurrentNode {
    

    if (_suppressCameraReset) {
        _suppressCameraReset = false;
        return;
    }
    
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

        NSString* year = self.sortedYears[(int)self.timelineSlider.value];
        if([self.simulatedYears containsObject:year]) {
            simulated = YES;
        }

        [self.nodeInformationPopover dismissPopoverAnimated:NO];
        NodeTooltipViewController* content = [[NodeTooltipViewController alloc] initWithNode:node];
        self.nodeInformationPopover = [[WEPopoverController alloc] initWithContentViewController:content];

        if (self.arEnabled) {
            WEPopoverContainerViewProperties *properties = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            properties.downArrowImageName = nil;
            self.nodeInformationPopover.containerViewProperties = properties;
        }
        
        if(simulated) {
            content.text = @"Simulated data";
        }
        
        self.nodeInformationPopover.passthroughViews = @[self.view];
        UIPopoverArrowDirection dir = [self popoverArrowDirectionForNodeInformationPopover];
        [self.nodeInformationPopover presentPopoverFromRect:[self displayRectForTimelineNodeInfoPopover] inView:self.view permittedArrowDirections:dir animated:NO];
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
        NodeInformationViewController* controller = [[NodeInformationViewController alloc] initWithNode:node isCurrentNode:isSelectingCurrentNode parent: self.view];
        self.nodeInformationViewController = controller;
        self.nodeInformationViewController.delegate = self;

        //this line is important, in case the popover for another node is already visible and traceroute could be being performed
        self.nodeInformationPopover = [[WEPopoverController alloc] initWithContentViewController:self.nodeInformationViewController];
        self.nodeInformationPopover.delegate = self;
        self.nodeInformationPopover.passthroughViews = @[self.view];

        if (![HelperMethods deviceIsiPad] || self.arEnabled) {
            WEPopoverContainerViewProperties* prop = [WEPopoverContainerViewProperties defaultContainerViewProperties];
            prop.upArrowImageName = nil;
            self.nodeInformationPopover.containerViewProperties = prop;
        }

        UIPopoverArrowDirection dir = [self popoverArrowDirectionForNodeInformationPopover];
        [self.nodeInformationPopover presentPopoverFromRect:[self displayRectForNodeInfoPopover] inView:self.view permittedArrowDirections:dir animated:YES];

        self.repositionButton.hidden = true;
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

// Reset UI state, but only make changes to camera / rendering if not in AR mode
-(void) resetView {
    [self dismissNodeInfoPopover];
    [self.controller deselectCurrentNode];
    [self resetVisualization];

    if(self.arEnabled && self.afterViewReset) {
        // In AR mode we don't actually change the rotation on a view reset, so if there is a post reset callback,
        // call it now
        // TODO: should really find a better way to handle this
        self.afterViewReset();
        self.afterViewReset = nil;
    }
}

// Full reset of UI state, including rotating back to default. Used in cases where we do need a full reset (like switching visualizations)
-(void) forceResetView {
    [self dismissNodeInfoPopover];
    [self.controller deselectCurrentNode];
    [self forceResetVisualization];
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

-(void)selectNodeByHostLookup:(NSString *)host {
    [self selectNodeByHostLookup:host withLookupCompletion:nil];
}

-(void)selectNodeByHostLookup:(NSString*)host withLookupCompletion:(void (^)(NSString *asn))completion {

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
                        if (completion) completion(asn);
                    }
                    else {
                        [self.errorInfoView setErrorString:@"Couldn't find ASN for host."];
                        if (completion) completion(nil);
                    }
                }];
            } else {
                [self.errorInfoView setErrorString:@"Couldn't find IP address for host."];
                [self.searchActivityIndicator stopAnimating];
                self.searchButton.hidden = NO;
                if (completion) completion(nil);
            };
        }];
    } else {
        [self showErrorAlert:NSLocalizedString(@"No Internet connection", nil) withMessage: NSLocalizedString(@"Please connect to the internet.", nil)];
        if (completion) completion(nil);
    }
}

-(void)nodeSearchDelegateDone {

    [self.nodeSearchPopover dismissPopoverAnimated:YES];
    self.searchButton.selected = NO;
    [self helpPopCheckOrMenuSelected:nil];
}

#pragma mark - NodeInfo delegate

- (void)dismissNodeInfoPopover {
    self.repositionButton.hidden = (self.arMode != ARModeViewing) || (self.timelineSlider.hidden == NO);

    [self.tracer stop];
    self.tracer = nil;
    [self.nodeInformationPopover dismissPopoverAnimated:YES];
    [self.nodeInformationViewController.tracerouteTimer invalidate];
    if (self.tracerouteASNs) {
        self.tracerouteASNs = nil;
        [self.controller clearHighlightLines];
    }
    
    [self helpPopCheckOrMenuSelected:nil];
}

#pragma mark - Node Info View Delegate

- (CGRect)displayRectForNodeInfoPopover{
    CGRect displayRect;
    
    if (![HelperMethods deviceIsiPad] || self.arEnabled) {
        displayRect = CGRectMake([[UIScreen mainScreen] bounds].size.width/2, self.view.bounds.size.height-self.nodeInformationViewController.preferredContentSize.height, 1, 1);
    } else {
        displayRect = CGRectMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/2, 1, 1);
    }
    
    return displayRect;
}

- (CGRect)displayRectForTimelineNodeInfoPopover {
    if (self.arEnabled) {
        CGRect sliderFrame = self.timelineSlider.frame;
        NSInteger padding = 150;
        return CGRectMake([[UIScreen mainScreen] bounds].size.width/2, sliderFrame.origin.y - padding, 1, 1);
    } else {
        CGPoint center = [self.controller getCoordinatesForNodeAtIndex:self.controller.targetNode];
        CGRect displayRect = CGRectMake(center.x, center.y, 1, 1);
        return displayRect;
    }
}

- (UIPopoverArrowDirection)popoverArrowDirectionForNodeInformationPopover {
    if (!self.timelineSlider.hidden) {
        return UIPopoverArrowDirectionDown;
    }

    if ([HelperMethods deviceIsiPad] && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return UIPopoverArrowDirectionLeft;
    }

    return UIPopoverArrowDirectionUp;
}

- (void)resizeNodeInfoPopover {
    self.nodeInformationPopover.popoverContentSize = CGSizeZero;
    UIPopoverArrowDirection dir = [self popoverArrowDirectionForNodeInformationPopover];
    [self.nodeInformationPopover repositionPopoverFromRect:[self displayRectForNodeInfoPopover] inView:self.view permittedArrowDirections:dir animated:YES];
}

-(void)tracerouteButtonTapped{
    [self prepareUIAndFetchAddress:^(NSString *ipAddress) {
        if (!ipAddress) {
            [self couldntResolveIP];
        } else {
            NSLog(@"Tracerouting %@", ipAddress);
            self.tracer = [SCTracerouteUtility tracerouteWithAddress:ipAddress];
            self.tracer.delegate = self;
            [self.tracer start];
        }
    }];
}

- (void)prepareUIAndFetchAddress:(void (^)(NSString *ipAddress))completion {
    [self resizeNodeInfoPopover];

    self.tracerouteASNs = [NSMutableDictionary new];

    if(!self.arEnabled) {
        _suppressCameraReset = YES;
        [self resetVisualization];
    }

    // On phones, translate up view so that we can more easily see it
    if (![HelperMethods deviceIsiPad] && !self.arEnabled) {
        [self.controller translateYAnimated:0.25f duration:3];
    }

    if(self.controller.lastSearchIP && ![self.controller.lastSearchIP isEqualToString:@""]) {
        completion(self.controller.lastSearchIP);
        return;
    } else {
        NodeWrapper* node = [self.controller nodeAtIndex:self.controller.targetNode];
        if (node.asn) {
            [ASNRequest fetchIPsForASN:node.asn response:^(NSArray *ips) {
                if ([ips count]) {
                    uint32_t rnd = arc4random_uniform((unsigned int)[ips count]);
                    NSString* arbitraryIP = [NSString stringWithFormat:@"%@", ips[rnd]];
                    completion(arbitraryIP);
                    return;
                } else {
                    completion(nil);
                    return;
                }
            }];

        } else {
            completion(nil);
            return;
        }
    }
}

- (void)nodeInformationViewControllerDidTriggerPingAction:(NodeInformationViewController *)nodeInformation {
    [self prepareUIAndFetchAddress:^(NSString *ipAddress) {
        if (!ipAddress) {
            [self couldntResolveIP];
        } else {
            self.pingUtility = [[SCPingUtility alloc] initWithIpAddress:ipAddress count:5 ttl:56 wait:1];
            self.pingUtility.delegate = self;
            [self.pingUtility start];
        }
    }];
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
    [self resetVisualization];
}

-(void)resetVisualization {
    if (!self.arEnabled) {
        [self forceResetVisualization];
    }
}

-(void)forceResetVisualization {
    [self.controller resetZoomAndRotationAnimatedForOrientation:![HelperMethods deviceIsiPad]];
    
    // On phones, translate up view so that we can more easily see it
    if (![HelperMethods deviceIsiPad] && !self.arEnabled) {
        [self.controller translateYAnimated:0.0f duration:1];
    }
}

-(void)forceTracerouteTimeout {
    [self.tracer forcedTimeout];
}

-(BOOL)nodeInformationViewControllerAutomaticallyStartPing:(NodeInformationViewController *)nodeInformation {
    return self.asnToPingAutomatically == nodeInformation.node.asn;
}

#pragma mark - help pop

-(void) helpPopCheckOrMenuSelected:(UIButton*)menuButton {

    NSString *shownMenusPopsString = [[NSUserDefaults standardUserDefaults] objectForKey:@"helpPopMenusShownDefault"];
    NSRange range = [shownMenusPopsString rangeOfString:@"0"];
    if (range.location == NSNotFound) return; // all help pops have been shown

    NSArray *orderOfMenuButtons = @[_searchButton, _visualizationsButton, _timelineButton];
    NSInteger helpLocation = range.location;

    if (menuButton == nil && self.helpPopView.isHidden) { // at a non menu shown state, show menu pop up

        UIButton *buttonForHelp = orderOfMenuButtons[helpLocation];
        CGPoint globalCoordinates = [buttonForHelp convertPoint:buttonForHelp.origin toView:self.view];
        CGFloat xPosition = globalCoordinates.x;
        NSInteger xPadding = 0;
        _helpPopBackImage.image = [UIImage imageNamed:@"callout_left.png"];

        if (xPosition + self.helpPopView.frame.size.width > CGRectGetMaxX(self.view.frame)) {
            // Readjust callout location if popover would clip
            xPadding = -112;
            _helpPopBackImage.image = [UIImage imageNamed:@"callout_right.png"];
        }

        self.helpPopViewPosition.constant = xPosition + xPadding;
        self.helpPopLabel.text = self.popMenuInfo[helpLocation];

        [self.helpPopView setAlpha:0.0f];
        [UIView animateWithDuration:0.5f animations:^{
            [self.helpPopView setAlpha:1.0f];
        } completion:^(BOOL finished) {
            self.helpPopView.hidden = NO;
        }];

    } else if (menuButton != nil) { // user viewing menu. is it menu with tooltip? If so mark, and now next menu show tool tip

        [self.helpPopView setAlpha:1.0f];
        [UIView animateWithDuration:0.5f animations:^{
            [self.helpPopView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            self.helpPopView.hidden = YES;
        }];

        NSInteger currentLocation = 0;
        for (UIButton *currentButton in orderOfMenuButtons) {
            if (currentButton == menuButton) {
                break;
            }
            currentLocation++;
        }

        // the menu with the tooltip has been viewed, mark as 1
        shownMenusPopsString = [shownMenusPopsString stringByReplacingCharactersInRange:NSMakeRange(currentLocation, 1) withString:@"1"];
        [[NSUserDefaults standardUserDefaults] setObject:shownMenusPopsString forKey:@"helpPopMenusShownDefault"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

}

- (void) helpPopCheckSetUp {

    if (! [[NSUserDefaults standardUserDefaults] objectForKey:@"helpPopMenusShownDefault"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"000" forKey:@"helpPopMenusShownDefault"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    self.popMenuInfo = @[@"You can search for companies and domains", @"You can also view the internet as a network", @"You can browse the history of the internet"];
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

    if (self.controller.targetNode != INT_MAX) {
        [self displayHops:hops withDestNode:[self.controller nodeAtIndex:self.controller.targetNode]];
    }
}

#pragma mark - Rotation and transitions

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self dismissNodeInfoPopover];
}

#pragma mark - PingLocationsDelegate

- (void)pingLocationsViewController:(PingLocationsViewController *)pingLocationsViewController selectedHostName:(NSString *)hostName {
    [self selectNodeByHostLookup:hostName withLookupCompletion:^(NSString *asn) {
        self.asnToPingAutomatically = asn;
    }];
}

#pragma mark - SCPingUtilityDelegate

- (void)pingUtility:(SCPingUtility *)pingUtility didFinishWithRecords:(NSArray<SCPacketRecord *> * _Nonnull)records {
    [self updatePingViewsWithRecords:records];
}

- (void)pingUtility:(SCPingUtility *)pingUtility didFailWithError:(NSError *)error {
    [self showErrorAlert:NSLocalizedString(@"Error Pinging Node", nil) withMessage:error.localizedDescription];
}

- (void)pingUtility:(SCPingUtility *)pingUtility didReceiveResponse:(NSArray<SCPacketRecord *> *)records {
    [self updatePingViewsWithRecords:records];
}

- (void)pingUtilityWillSendPing:(SCPingUtility *)pingUtility {
    [self updatePingViewsWithRecords:pingUtility.packetRecords];
    self.asnToPingAutomatically = nil;;
}

- (void)updatePingViewsWithRecords:(NSArray<SCPacketRecord *> *)records {
    NSString *resultText = @"";
    NSInteger received = 0;
    float totalRTT = 0;
    float bestRTT = 0;

    for (NSInteger i = 0; i < records.count; i++) {
        SCPacketRecord *record = records[i];
        NSString *recordMessage = @"";

        if (!record.timedOut && !record.arrival) {
            // This ping is in-flight.
            recordMessage = @"Ping sent...";
        } else if (record.timedOut) {
            recordMessage = @"Request timed out.";
        } else if (record.arrival) {
            received++;
            totalRTT = totalRTT + record.rtt;
            bestRTT = bestRTT > 0 ? MIN(bestRTT, record.rtt) : record.rtt;
            recordMessage = [NSString stringWithFormat:@"Reply from %@: %.00fms", record.responseAddress, record.rtt];
        } else {
            recordMessage = @"Unknown response";
        }

        resultText = [NSString stringWithFormat:@"%@%zd. %@\n", resultText, i + 1, recordMessage];
    }

    float receivedPercent = records.count > 0 ? received / (float) records.count : 0;
    NSInteger averagePingTime = received > 0 ? totalRTT / received : 0;
    NSString *averagePingTimeMessage = received > 0 ? [NSString stringWithFormat:@"%zdms", averagePingTime] : @"N/A";
    NSString *bestPingTime = bestRTT > 0 ? [NSString stringWithFormat:@"%.00fms", bestRTT] : @"N/A";

    self.nodeInformationViewController.tracerouteTextView.text = resultText;
    self.nodeInformationViewController.box1.numberLabel.text = [NSString stringWithFormat:@"%@", averagePingTimeMessage];
    self.nodeInformationViewController.box2.numberLabel.text = [NSString stringWithFormat:@"%@", bestPingTime];
    self.nodeInformationViewController.box3.numberLabel.text = [NSString stringWithFormat:@"%.00f%%", receivedPercent * 100];
}

@end
