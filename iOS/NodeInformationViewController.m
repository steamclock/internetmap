//
//  NodeInformationViewController.m
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-04.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeInformationViewController.h"
#import "LabelNumberBoxView.h"
#import "NodeWrapper.h"
#import "ViewController.h"


#define TOP_BACKGROUND_HEIGHT 44
#define VERTICAL_PADDING_IPAD 20
#define VERTICAL_PADDING_IPHONE 20
#define LABELS_HEIGHT 20
#define TRACEROUTE_BUTTON_HEIGHT 44
#define TRACEROUTE_ENABLED 1
#define TRACEROUTE_MAX_TIMEOUT_MILLISECONDS 30 * 1000 // arbitary cap off at 40 seconds, otherwise it can run forever
#define INFO_BOX_HEIGHT 75

typedef NS_ENUM(NSInteger, MOINodeAction) {
    MOINodeActionTraceroute,
    MOINodeActionPing
};

@interface NodeInformationViewController ()

@property (nonatomic, strong) UIButton* doneButton;
@property (nonatomic, assign) BOOL isDisplayingCurrentNode;
@property (nonatomic, strong) NSMutableArray* firstGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* secondGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* infoLabels;

@property (nonatomic, strong) UIView* tracerouteContainerView;

@property (nonatomic, strong) UIScrollView* scrollView;

@property (nonatomic, assign) float contentHeight;

@property (nonatomic, assign) CGFloat safeAreaPadding;

@end

@implementation NodeInformationViewController

- (void)dealloc {
    if (![HelperMethods deviceIsiPad]) {
        [_tracerouteTextView removeObserver:self forKeyPath:@"text"];
    }
}

- (id)initWithNode:(NodeWrapper*)node isCurrentNode:(BOOL)isCurrent parent:(UIView*)parent
{
    self = [super init];
    if (self) {

        float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;

        self.node = node;
        self.isDisplayingCurrentNode = isCurrent;
        self.infoLabels = [[NSMutableArray alloc] init];
        
        CGFloat height = 0;
        //create the first group of strings, like ASN and text description
        NSString* asnText = [NSString stringWithFormat:@"AS%@", self.node.asn];
        self.firstGroupOfStrings = [NSMutableArray array];
        
        NSString* textDescription = self.node.friendlyDescription;


        if (self.isDisplayingCurrentNode) {
            self.title = NSLocalizedString(@"You Are Here", nil);
            if (![HelperMethods isStringEmptyOrNil:textDescription]) {
                [self.firstGroupOfStrings addObject:textDescription];
            }
        }else {
            if (![HelperMethods isStringEmptyOrNil:textDescription]) {
                self.title = textDescription;
            } else {
                self.title = asnText;
            }
        }
        
        height += TOP_BACKGROUND_HEIGHT+ verticalPad; //top label + padding to first group of labels
        
        if (![self.title isEqualToString:asnText]) {
            [self.firstGroupOfStrings addObject:asnText];
        }
        
        NSString* typeString = self.node.typeString;
        if (![HelperMethods isStringEmptyOrNil:typeString]) {
            [self.firstGroupOfStrings addObject:typeString];
        }
        
        if ([self.firstGroupOfStrings count] == 0) {
            [self.firstGroupOfStrings addObject:@"No additional data."];
        }
        
        height += LABELS_HEIGHT*[self.firstGroupOfStrings count]; //all label heights
        
        
        if ([HelperMethods deviceIsiPad]) {
            height += verticalPad; //padding between first group of labels and connection label
            
            height += LABELS_HEIGHT; //connections label
        }
        
        if (!self.isDisplayingCurrentNode) {
            height += verticalPad; //traceroute button top padding
            height += TRACEROUTE_BUTTON_HEIGHT; //traceroute button
        }
        
        height += verticalPad; //bottom margin

        if (@available(iOS 11.0, *)) {
            self.safeAreaPadding = parent.safeAreaInsets.bottom;
        } else {
            self.safeAreaPadding = 0;
        }

        height += self.safeAreaPadding;

        self.contentHeight = height;

        float width = [HelperMethods deviceIsiPad] ? 443 : [[UIScreen mainScreen] bounds].size.width;
        [self setPreferredContentSize:CGSizeMake(width, height)];


    }
    return self;
}

- (void)viewDidLoad {
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.preferredContentSize.width, self.preferredContentSize.height)];
    self.scrollView.contentSize = CGSizeMake(self.preferredContentSize.width, self.contentHeight-TOP_BACKGROUND_HEIGHT);
    self.scrollView.scrollEnabled = ![HelperMethods deviceIsiPad];
    [self.view addSubview:self.scrollView];
    
    UIImage* xImage = [UIImage imageNamed:@"x-icon"];
    
    UIView* orangeBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.preferredContentSize.width, TOP_BACKGROUND_HEIGHT)];
    orangeBackgroundView.backgroundColor = UI_PRIMARY_COLOR;
    [self.view addSubview:orangeBackgroundView];
    
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.preferredContentSize.width-xImage.size.width-25, TOP_BACKGROUND_HEIGHT)];
    self.topLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:24];
    self.topLabel.textColor = [UIColor blackColor];
    self.topLabel.backgroundColor = [UIColor clearColor];
    self.topLabel.text = self.title;
    self.topLabel.minimumScaleFactor = 0.5;
    self.topLabel.adjustsFontSizeToFitWidth = YES;
    [orangeBackgroundView addSubview:self.topLabel];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.frame = CGRectMake(self.topLabel.x+self.topLabel.width-5, 2, xImage.size.width+20, xImage.size.height+20);
    self.doneButton.imageView.contentMode = UIViewContentModeCenter;
    [self.doneButton setImage:xImage forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
    
    float lastLabelBottom = 0;
    //create first group of labels
    for (int i = 0; i < [self.firstGroupOfStrings count]; i++) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, orangeBackgroundView.y+orangeBackgroundView.height+verticalPad+LABELS_HEIGHT*i, 280, LABELS_HEIGHT)];
        label.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
        label.textColor = FONT_COLOR_WHITE;
        label.backgroundColor = [UIColor clearColor];
        label.text = self.firstGroupOfStrings[i];
        [self.scrollView addSubview:label];
        if (i == [self.firstGroupOfStrings count]-1) {
            lastLabelBottom = label.y+label.height;
        }
        [self.infoLabels addObject:label];
    }
    
    float padding;
    #if TRACEROUTE_ENABLED
        padding = lastLabelBottom; // space for button
    #else
        padding = lastLabelBottom+verticalPad;
    #endif
    
    // connections
    UILabel* connectionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, padding, 280, LABELS_HEIGHT)];
    connectionsLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
    connectionsLabel.textColor = FONT_COLOR_WHITE;
    connectionsLabel.backgroundColor = [UIColor clearColor];
    NSString* conn = self.node.numberOfConnections == 1 ? @"Connection" : @"Connections";
    connectionsLabel.text = [NSString stringWithFormat:@"%d %@", self.node.numberOfConnections, conn];
    [self.scrollView addSubview:connectionsLabel];
    [self.infoLabels addObject:connectionsLabel];
    
    
    #if TRACEROUTE_ENABLED
    // traceroute button
    if (!self.isDisplayingCurrentNode) {
        self.tracerouteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        float buttonY = self.preferredContentSize.height - TRACEROUTE_BUTTON_HEIGHT - verticalPad - self.safeAreaPadding + 10;
        CGFloat buttonWidth = (self.scrollView.bounds.size.width - 40);
        self.tracerouteButton.frame = CGRectMake(20, buttonY, buttonWidth, TRACEROUTE_BUTTON_HEIGHT);
        self.tracerouteButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_REGULAR size:20];
        [self.tracerouteButton setTitle:NSLocalizedString(@"Perform Traceroute", nil) forState:UIControlStateNormal];
        [self.tracerouteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.tracerouteButton setBackgroundImage:[[UIImage imageNamed:@"traceroute-button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 22, 0, 22)] forState:UIControlStateNormal];
        [self.tracerouteButton addTarget:self action:@selector(tracerouteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:self.tracerouteButton];
    }

    self.tracerouteContainerView = [[UIView alloc] initWithFrame:CGRectMake(orangeBackgroundView.x, orangeBackgroundView.y, orangeBackgroundView.width, 500)];
    self.tracerouteContainerView.hidden = YES;
    [self.scrollView addSubview:self.tracerouteContainerView];

    #endif

    CGFloat boxWidth = (self.preferredContentSize.width-20-30-30-20)/3.0; //total width subtracted by outer and inner margins and divided by three
    
    self.box1 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, INFO_BOX_HEIGHT) labelText:@"" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box1];

    self.box2 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20+boxWidth+30, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, INFO_BOX_HEIGHT) labelText:@"" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box2];
    
    self.box3 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20+boxWidth+30+boxWidth+30, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, INFO_BOX_HEIGHT) labelText:@"" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box3];
    
    self.detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.box1.y+self.box1.height+verticalPad/2, self.tracerouteContainerView.width-20, LABELS_HEIGHT)];
    self.detailsLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
    self.detailsLabel.textColor = FONT_COLOR_WHITE;
    self.detailsLabel.backgroundColor = [UIColor clearColor];
    [self.tracerouteContainerView addSubview:self.detailsLabel];

    UIView* dividerView = [[UIView alloc] initWithFrame:CGRectMake(self.detailsLabel.x, self.detailsLabel.y+self.detailsLabel.height+verticalPad/2, self.detailsLabel.width, 1)];
    dividerView.backgroundColor = [UIColor grayColor];
    [self.tracerouteContainerView addSubview:dividerView];
    
    float tracerouteTvHeight = [HelperMethods deviceIsiPad] ? 450 : 250;
    self.tracerouteTextView = [[UITextView alloc] initWithFrame:CGRectMake(5, dividerView.y+dividerView.height, self.tracerouteContainerView.width-5, tracerouteTvHeight)];
    self.tracerouteTextView.backgroundColor = [UIColor clearColor];
    self.tracerouteTextView.textColor = [UIColor whiteColor];
    self.tracerouteTextView.editable = NO;
    self.tracerouteTextView.userInteractionEnabled = YES;
    self.tracerouteTextView.scrollEnabled =  YES;
    self.tracerouteTextView.font = [UIFont fontWithName:FONT_NAME_REGULAR size:12];
    [self.tracerouteContainerView addSubview:self.tracerouteTextView];
    
    if (![HelperMethods deviceIsiPad]) {
        [self.tracerouteTextView addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.delegate nodeInformationViewControllerAutomaticallyStartPing:self]) {
        // A small delay to make the zoom-in, zoom-out animations more palatable.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupUIAndTriggerAction:MOINodeActionPing];
        });
    }
}

- (IBAction)doneTapped {
    if ([self.delegate respondsToSelector:@selector(doneTapped)]) {
        [self.delegate performSelector:@selector(doneTapped)];
    }
}

-(IBAction)tracerouteButtonTapped:(id)sender{
    [self setupUIAndTriggerAction:MOINodeActionTraceroute];
}

-(void)setupUIAndTriggerAction:(MOINodeAction)action {
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    float contentHeight = self.box1.height+verticalPad/2+LABELS_HEIGHT+verticalPad/2+self.tracerouteTextView.height+verticalPad;

    if ([HelperMethods deviceHasInternetConnection]) {
        //UI setup
        if ([HelperMethods deviceIsiPad]) {
            self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, TOP_BACKGROUND_HEIGHT+contentHeight);
            self.scrollView.frame = CGRectMake(0, 0, self.scrollView.width, contentHeight);
        }
        self.scrollView.contentSize = CGSizeMake(self.preferredContentSize.width, contentHeight);

        self.tracerouteContainerView.alpha = 0;
        self.tracerouteContainerView.hidden = NO;

        if (![HelperMethods deviceIsiPad]) {
            self.scrollView.frame = CGRectMake(0, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.scrollView.frame.size.height+250);
        }

        [UIView animateWithDuration:1 animations:^{
            self.tracerouteContainerView.alpha = 1;
            for (UILabel* label in self.infoLabels) {
                label.alpha = 0;
            }
            self.tracerouteButton.alpha = 0;
            self.pingButton.alpha = 0;
        }];

        int minDesiredHeight = 250;
        if (self.contentHeight < minDesiredHeight) {
            self.contentHeight = minDesiredHeight;
            float width = [HelperMethods deviceIsiPad] ? 443 : [[UIScreen mainScreen] bounds].size.width;
            [self setPreferredContentSize:CGSizeMake(width, minDesiredHeight)];
        }

        //tell delegate to perform actual action
        switch (action) {
            case MOINodeActionPing:
                self.topLabel.text = [NSString stringWithFormat:@"Pinging %@", self.topLabel.text];
                self.box1.textLabel.text = NSLocalizedString(@"Average", nil);
                self.box2.textLabel.text = NSLocalizedString(@"Best", nil);
                self.box3.textLabel.text = NSLocalizedString(@"Received", nil);
                self.detailsLabel.text = NSLocalizedString(@"Details of Ping", nil);
                if ([self.delegate respondsToSelector:@selector(nodeInformationViewControllerDidTriggerPingAction:)]) {
                    [self.delegate nodeInformationViewControllerDidTriggerPingAction:self];
                }
                break;
            case MOINodeActionTraceroute:
                self.topLabel.text = [NSString stringWithFormat:@"To %@", self.topLabel.text];
                self.tracerouteTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(tracerouteTimerFired) userInfo:nil repeats:YES];
                self.box1.textLabel.text = NSLocalizedString(@"IP Hops", nil);
                self.box2.textLabel.text = NSLocalizedString(@"ASN Hops", nil);
                self.box3.textLabel.text = NSLocalizedString(@"Time (ms)", nil);
                self.detailsLabel.text = NSLocalizedString(@"Details of Traceroute", nil);
                if ([self.delegate respondsToSelector:@selector(tracerouteButtonTapped)]) {
                    [self.delegate performSelector:@selector(tracerouteButtonTapped)];
                }
                break;
        }
    } else {
        [self showErrorAlert:NSLocalizedString(@"No Internet connection", nil) withMessage: NSLocalizedString(@"Please connect to the internet.", nil)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    // TODO: word wrap?
    CGSize size = [self.tracerouteTextView.text boundingRectWithSize:CGSizeMake(self.tracerouteTextView.width, CGFLOAT_MAX)
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName: self.tracerouteTextView.font}
                                                             context:nil].size;
    self.tracerouteTextView.height = size.height+verticalPad*2;
    float contentHeight = self.box1.height+verticalPad+LABELS_HEIGHT+verticalPad+MIN(self.tracerouteTextView.height, size.height)+verticalPad*3;
    self.scrollView.contentSize = CGSizeMake(self.preferredContentSize.width, TOP_BACKGROUND_HEIGHT+contentHeight);
}

- (void)tracerouteTimerFired {

    if ([self.box3.numberLabel.text intValue] < TRACEROUTE_MAX_TIMEOUT_MILLISECONDS) {
        [self.box3 incrementNumber];
    } else {
        // force traceroute end after MAX_TIMEOUT, or it spins forever and never shows the traceroute IPs
        [self.tracerouteTimer invalidate];
        
        if ([self.delegate respondsToSelector:@selector(forceTracerouteTimeout)]) {
            [self.delegate performSelector:@selector(forceTracerouteTimeout)];
        }
        
        [self tracerouteDone];
    }
}

- (void)tracerouteDone {
    // TODO: word wrap?
    CGSize size = [self.tracerouteTextView.text boundingRectWithSize:CGSizeMake(self.tracerouteTextView.width, CGFLOAT_MAX)
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:@{NSFontAttributeName: self.tracerouteTextView.font}
                                                              context:nil].size;
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    float contentHeight = TOP_BACKGROUND_HEIGHT+self.box1.height+verticalPad+LABELS_HEIGHT+verticalPad+verticalPad;
    if ([HelperMethods deviceIsiPad]) {
        self.preferredContentSize = CGSizeMake(self.preferredContentSize.width, contentHeight+MIN(self.tracerouteTextView.height, size.height));
    }else {
        self.tracerouteTextView.height = size.height+verticalPad;
        self.scrollView.contentSize = CGSizeMake(self.preferredContentSize.width, contentHeight+size.height+verticalPad);
    }
    [UIView animateWithDuration:1 animations:^{
        if (![HelperMethods deviceIsiPad]) {
            self.scrollView.frame = CGRectMake(0, 0, self.scrollView.width, self.preferredContentSize.height);
        }
    }];

}

-(void)showErrorAlert:(NSString*)title withMessage:(NSString*)message {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:title
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
                                                     [alert dismissViewControllerAnimated:YES completion:nil]; }];
    [alert addAction:okAA];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
