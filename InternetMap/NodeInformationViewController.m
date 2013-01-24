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

#define TOP_BACKGROUND_HEIGHT 44
#define VERTICAL_PADDING_IPAD 20
#define VERTICAL_PADDING_IPHONE 10
#define LABELS_HEIGHT 20
#define TRACEROUTE_BUTTON_HEIGHT 44

#define INFO_BOX_HEIGHT 75

@interface NodeInformationViewController ()

@property (nonatomic, strong) NodeWrapper* node;
@property (nonatomic, strong) UIButton* doneButton;
@property (nonatomic, assign) BOOL isDisplayingCurrentNode;
@property (nonatomic, strong) NSMutableArray* firstGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* secondGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* infoLabels;

@property (nonatomic, strong) UIView* tracerouteContainerView;

@property (nonatomic, strong) UIScrollView* scrollView;

@property (nonatomic, assign) float contentHeight;

@end

@implementation NodeInformationViewController

- (void)dealloc {
    if ([HelperMethods deviceIsiPad]) {
        [_tracerouteTextView removeObserver:self forKeyPath:@"text"];
    }
}

- (id)initWithNode:(NodeWrapper*)node isCurrentNode:(BOOL)isCurrent
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
        NSMutableString* textDescription = [self.node.textDescription mutableCopy];
        
        //most nodes have this format for their textdescription: "signet-as signet internet"
        //here, we strip the first word, if it has a dash in it, or it is the same as the second word
        //then, we capitalize the words after that.
        NSArray* components = [textDescription componentsSeparatedByString:@" "];
        if ([components count] > 1) {
            NSString* firstWord = components[0];
            if ([firstWord rangeOfString:@"-"].location != NSNotFound || [firstWord isEqualToString:components[1]]) {
                textDescription = [NSMutableString string];
                for (int i = 1; i<[components count]-1; i++) {
                    [textDescription appendFormat:@"%@ ", components[i]];
                }
                textDescription = [[textDescription capitalizedString] mutableCopy];
            }
        }

        if (self.isDisplayingCurrentNode) {
            self.title = @"You are here.";
            if (![HelperMethods isStringEmptyOrNil:textDescription]) {
                [self.firstGroupOfStrings addObject:textDescription];
            }
        }else {
            if (![HelperMethods isStringEmptyOrNil:textDescription]) {
                self.title = textDescription;
            }else {
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
        self.contentHeight = height;

        float width = [HelperMethods deviceIsiPad] ? 440 : [[UIScreen mainScreen] bounds].size.width;
        [self setContentSizeForViewInPopover:CGSizeMake(width, height)];


    }
    return self;
}

- (void)viewDidLoad {
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, self.contentSizeForViewInPopover.height)];
    self.scrollView.contentSize = CGSizeMake(self.contentSizeForViewInPopover.width, self.contentHeight-TOP_BACKGROUND_HEIGHT);
    self.scrollView.scrollEnabled = ![HelperMethods deviceIsiPad];
    [self.view addSubview:self.scrollView];
    
    UIImage* xImage = [UIImage imageNamed:@"x-icon"];
    
    UIView* orangeBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, TOP_BACKGROUND_HEIGHT)];
    orangeBackgroundView.backgroundColor = UI_ORANGE_COLOR;
    [self.view addSubview:orangeBackgroundView];
    
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, -2, self.contentSizeForViewInPopover.width-xImage.size.width-25, TOP_BACKGROUND_HEIGHT)];
    self.topLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:24];
    self.topLabel.textColor = [UIColor blackColor];
    self.topLabel.backgroundColor = [UIColor clearColor];
    self.topLabel.text = self.title;
    self.topLabel.minimumFontSize = 14;
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
        label.textColor = FONT_COLOR_GRAY;
        label.backgroundColor = [UIColor clearColor];
        label.text = self.firstGroupOfStrings[i];
        [self.scrollView addSubview:label];
        if (i == [self.firstGroupOfStrings count]-1) {
            lastLabelBottom = label.y+label.height;
        }
        [self.infoLabels addObject:label];
    }
    
    if ([HelperMethods deviceIsiPad]) {
        UILabel* connectionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, lastLabelBottom+verticalPad, 280, LABELS_HEIGHT)];
        connectionsLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
        connectionsLabel.textColor = FONT_COLOR_GRAY;
        connectionsLabel.backgroundColor = [UIColor clearColor];
        NSString* conn = self.node.numberOfConnections == 1 ? @"Connection" : @"Connections";
        connectionsLabel.text = [NSString stringWithFormat:@"%i %@", self.node.numberOfConnections, conn];
        [self.scrollView addSubview:connectionsLabel];
        [self.infoLabels addObject:connectionsLabel];
    }
    
    if (!self.isDisplayingCurrentNode) {
        self.tracerouteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        float tracerouteButtonY = self.contentSizeForViewInPopover.height-TRACEROUTE_BUTTON_HEIGHT-verticalPad;
        self.tracerouteButton.frame = CGRectMake(20, tracerouteButtonY, 280, TRACEROUTE_BUTTON_HEIGHT);
        self.tracerouteButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_REGULAR size:20];
        [self.tracerouteButton setTitle:@"Perform Traceroute" forState:UIControlStateNormal];
        [self.tracerouteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.tracerouteButton setBackgroundImage:[[UIImage imageNamed:@"traceroute-button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 22, 0, 22)] forState:UIControlStateNormal];
        [self.tracerouteButton addTarget:self action:@selector(tracerouteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:self.tracerouteButton];
    }

    self.tracerouteContainerView = [[UIView alloc] initWithFrame:CGRectMake(orangeBackgroundView.x, orangeBackgroundView.y, orangeBackgroundView.width, 500)];
    self.tracerouteContainerView.hidden = YES;
    [self.scrollView addSubview:self.tracerouteContainerView];

    CGFloat boxWidth = (self.contentSizeForViewInPopover.width-20-30-30-20)/3.0; //total width subtracted by outer and inner margins and divided by three
    
    self.box1 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, INFO_BOX_HEIGHT) labelText:@"IP Hops" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box1];

    self.box2 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20+boxWidth+30, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, INFO_BOX_HEIGHT) labelText:@"ASN Hops" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box2];
    
    self.box3 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20+boxWidth+30+boxWidth+30, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, INFO_BOX_HEIGHT) labelText:@"Time (ms)" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box3];
    
    UILabel* detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.box1.y+self.box1.height+verticalPad/2, self.tracerouteContainerView.width-20, LABELS_HEIGHT)];
    detailsLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
    detailsLabel.textColor = FONT_COLOR_GRAY;
    detailsLabel.backgroundColor = [UIColor clearColor];
    detailsLabel.text = @"Details of Traceroute";
    [self.tracerouteContainerView addSubview:detailsLabel];

    UIView* dividerView = [[UIView alloc] initWithFrame:CGRectMake(detailsLabel.x, detailsLabel.y+detailsLabel.height+verticalPad/2, detailsLabel.width, 1)];
    dividerView.backgroundColor = [UIColor grayColor];
    [self.tracerouteContainerView addSubview:dividerView];
    
    float tracerouteTvHeight = [HelperMethods deviceIsiPad] ? 450 : 0;
    self.tracerouteTextView = [[UITextView alloc] initWithFrame:CGRectMake(5, dividerView.y+dividerView.height, self.tracerouteContainerView.width-5, tracerouteTvHeight)];
    self.tracerouteTextView.backgroundColor = [UIColor clearColor];
    self.tracerouteTextView.textColor = [UIColor whiteColor];
    self.tracerouteTextView.editable = NO;
    self.tracerouteTextView.userInteractionEnabled = YES;
    self.tracerouteTextView.scrollEnabled = [HelperMethods deviceIsiPad];
    self.tracerouteTextView.font = [UIFont fontWithName:FONT_NAME_REGULAR size:12];
    [self.tracerouteContainerView addSubview:self.tracerouteTextView];
    
}

- (IBAction)doneTapped {
    if ([self.delegate respondsToSelector:@selector(doneTapped)]) {
        [self.delegate performSelector:@selector(doneTapped)];
    }

}

-(IBAction)tracerouteButtonTapped:(id)sender{
    
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    float contentHeight = self.box1.height+verticalPad/2+LABELS_HEIGHT+verticalPad/2+self.tracerouteTextView.height+verticalPad;
    if ([HelperMethods deviceHasInternetConnection]) {
        //UI setup
        if ([HelperMethods deviceIsiPad]) {
            self.contentSizeForViewInPopover = CGSizeMake(self.contentSizeForViewInPopover.width, TOP_BACKGROUND_HEIGHT+contentHeight);
            self.scrollView.frame = CGRectMake(0, 0, self.scrollView.width, contentHeight);
        }
        self.scrollView.contentSize = CGSizeMake(self.contentSizeForViewInPopover.width, contentHeight);
        
        if (![HelperMethods deviceIsiPad]) {
            [self.tracerouteTextView addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
        }
        
        self.tracerouteContainerView.alpha = 0;
        self.tracerouteContainerView.hidden = NO;
        self.tracerouteTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(tracerouteTimerFired) userInfo:nil repeats:YES];
        self.topLabel.text = [NSString stringWithFormat:@"To %@", self.topLabel.text];
        
        [UIView animateWithDuration:1 animations:^{
            self.tracerouteContainerView.alpha = 1;
            for (UILabel* label in self.infoLabels) {
                label.alpha = 0;
            }
            self.tracerouteButton.alpha = 0;
        }];
        
        //tell delegate to perform actual traceroute
        if ([self.delegate respondsToSelector:@selector(tracerouteButtonTapped)]) {
            [self.delegate performSelector:@selector(tracerouteButtonTapped)];
        }
    }else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No Internet connection" message:@"Please connect to the internet." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    CGSize size = [self.tracerouteTextView.text sizeWithFont:self.tracerouteTextView.font constrainedToSize:CGSizeMake(self.tracerouteTextView.width, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    self.tracerouteTextView.height = size.height+verticalPad*2;
    float contentHeight = self.box1.height+verticalPad+LABELS_HEIGHT+verticalPad+MIN(self.tracerouteTextView.height, size.height)+verticalPad*3;
    self.scrollView.contentSize = CGSizeMake(self.contentSizeForViewInPopover.width, TOP_BACKGROUND_HEIGHT+contentHeight);
}

- (void)tracerouteTimerFired {
    [self.box3 incrementNumber];
}

- (void)tracerouteDone {
    CGSize size = [self.tracerouteTextView.text sizeWithFont:self.tracerouteTextView.font constrainedToSize:CGSizeMake(self.tracerouteTextView.width, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    float verticalPad = [HelperMethods deviceIsiPad] ? VERTICAL_PADDING_IPAD : VERTICAL_PADDING_IPHONE;
    float contentHeight = TOP_BACKGROUND_HEIGHT+self.box1.height+verticalPad+LABELS_HEIGHT+verticalPad+verticalPad;
    if ([HelperMethods deviceIsiPad]) {
        self.contentSizeForViewInPopover = CGSizeMake(self.contentSizeForViewInPopover.width, contentHeight+MIN(self.tracerouteTextView.height, size.height));
    }else {
        self.tracerouteTextView.height = size.height+verticalPad;
        self.scrollView.contentSize = CGSizeMake(self.contentSizeForViewInPopover.width, contentHeight+size.height+verticalPad);
    }
    [UIView animateWithDuration:1 animations:^{
        if (![HelperMethods deviceIsiPad]) {
            self.scrollView.frame = CGRectMake(0, 0, self.scrollView.width, self.contentSizeForViewInPopover.height);
        }
    }];

}

@end
