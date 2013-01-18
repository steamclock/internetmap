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

@interface NodeInformationViewController ()

@property (nonatomic, strong) NodeWrapper* node;
@property (nonatomic, strong) UIButton* doneButton;
@property (nonatomic, assign) BOOL isDisplayingCurrentNode;
@property (nonatomic, strong) NSMutableArray* firstGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* secondGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* infoLabels;

@property (nonatomic, strong) UIView* tracerouteContainerView;
@property (nonatomic, strong) UIView* yourLocationContainerView;

@property (nonatomic, strong) UIScrollView* scrollView;

@property (nonatomic, assign) float contentHeight;

@end

@implementation NodeInformationViewController

- (id)initWithNode:(NodeWrapper*)node isCurrentNode:(BOOL)isCurrent
{
    self = [super init];
    if (self) {

        
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
        
        height += 20+35; //top margin and topLabel and white line
                
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
        
        height += 25*[self.firstGroupOfStrings count]; //all labels + margins
        
        
        height += 20+20; //number of connections label
        
        if (!self.isDisplayingCurrentNode) {
            height += 44; //traceroute button
            height += 20; //traceroute button top margin
        }
        
        height += 20; //bottom margin
        self.contentHeight = height;

        float width = [HelperMethods deviceIsiPad] ? 452 : [[UIScreen mainScreen] bounds].size.width;
        height = [HelperMethods deviceIsiPad] ? height : [[UIScreen mainScreen] bounds].size.height/2.0-20;
        [self setContentSizeForViewInPopover:CGSizeMake(width, height)];


    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, self.contentSizeForViewInPopover.height)];
    self.scrollView.contentSize = CGSizeMake(self.contentSizeForViewInPopover.width, self.contentHeight-88);
    self.scrollView.scrollEnabled = ![HelperMethods deviceIsiPad];
    [self.view addSubview:self.scrollView];
    
    UIImage* xImage = [UIImage imageNamed:@"x-icon"];
    
    UIView* orangeBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, 44)];
    orangeBackgroundView.backgroundColor = UI_ORANGE_COLOR;
    [self.view addSubview:orangeBackgroundView];
    
    float topLabelOffset = [HelperMethods deviceIsiPad] ? 34 : 24;
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, -2, self.contentSizeForViewInPopover.width-xImage.size.width-topLabelOffset, 44)];
    self.topLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:24];
    self.topLabel.textColor = [UIColor blackColor];
    self.topLabel.text = self.title;
    self.topLabel.minimumFontSize = 14;
    self.topLabel.adjustsFontSizeToFitWidth = YES;
    [self.view addSubview:self.topLabel];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.frame = CGRectMake(self.topLabel.x+self.topLabel.width-5, 2, xImage.size.width+20, xImage.size.height+20);
    self.doneButton.imageView.contentMode = UIViewContentModeCenter;
    self.doneButton.backgroundColor = [UIColor redColor];
    [self.doneButton setImage:xImage forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
    
    float lastLabelBottom = 0;
    //create first group of labels
    for (int i = 0; i < [self.firstGroupOfStrings count]; i++) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, orangeBackgroundView.y+orangeBackgroundView.height+10+25*i, 280, 20)];
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
    
    UILabel* connectionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, lastLabelBottom+25, 280, 20)];
    connectionsLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
    connectionsLabel.textColor = FONT_COLOR_GRAY;
    connectionsLabel.backgroundColor = [UIColor clearColor];
    NSString* conn = self.node.numberOfConnections == 1 ? @"Connection" : @"Connections";
    connectionsLabel.text = [NSString stringWithFormat:@"%i %@", self.node.numberOfConnections, conn];
    [self.scrollView addSubview:connectionsLabel];
    [self.infoLabels addObject:connectionsLabel];
    
    self.tracerouteContainerView = [[UIView alloc] initWithFrame:CGRectMake(orangeBackgroundView.x, orangeBackgroundView.y+15, orangeBackgroundView.width, 500)];
    self.tracerouteContainerView.hidden = YES;
    [self.scrollView addSubview:self.tracerouteContainerView];
    
    CGFloat boxWidth = (self.contentSizeForViewInPopover.width-20-30-30-20)/3.0; //total width subtracted by outer and inner margins and divided by three
    CGFloat boxHeight = 75;
    
    self.box1 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, boxHeight) labelText:@"IP Hops" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box1];

    self.box2 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20+boxWidth+30, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, boxHeight) labelText:@"ASN Hops" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box2];
    
    self.box3 = [[LabelNumberBoxView alloc] initWithFrame:CGRectMake(20+boxWidth+30+boxWidth+30, orangeBackgroundView.y+orangeBackgroundView.height+6, boxWidth, boxHeight) labelText:@"Time (ms)" numberText:@"0"];
    [self.tracerouteContainerView addSubview:self.box3];
    
    UILabel* detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.box1.y+self.box1.height+8, self.tracerouteContainerView.width-20, 18)];
    detailsLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
    detailsLabel.textColor = FONT_COLOR_GRAY;
    detailsLabel.backgroundColor = [UIColor clearColor];
    detailsLabel.text = @"Details of Traceroute";
    [self.tracerouteContainerView addSubview:detailsLabel];

    UIView* dividerView = [[UIView alloc] initWithFrame:CGRectMake(detailsLabel.x, detailsLabel.y+detailsLabel.height+10, detailsLabel.width, 1)];
    dividerView.backgroundColor = [UIColor grayColor];
    [self.tracerouteContainerView addSubview:dividerView];
    
    self.tracerouteTextView = [[UITextView alloc] initWithFrame:CGRectMake(5, dividerView.y+dividerView.height+5, self.tracerouteContainerView.width-5, 450)];
    self.tracerouteTextView.backgroundColor = [UIColor clearColor];
    self.tracerouteTextView.textColor = [UIColor whiteColor];
    self.tracerouteTextView.editable = NO;
    self.tracerouteTextView.userInteractionEnabled = YES;
    self.tracerouteTextView.scrollEnabled = [HelperMethods deviceIsiPad];
    self.tracerouteTextView.font = [UIFont fontWithName:FONT_NAME_REGULAR size:12];
    [self.tracerouteContainerView addSubview:self.tracerouteTextView];

    
    UIImage* yourLocationImage = [UIImage imageNamed:@"youarehere-icon"];
    self.yourLocationContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, 44)]; //position is not really set here, only size!
    self.yourLocationContainerView.backgroundColor = UI_BLUE_COLOR;
    self.yourLocationContainerView.alpha = 0;
    [self.view addSubview:self.yourLocationContainerView];
    
    UILabel* yourLocationLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, self.yourLocationContainerView.width-yourLocationImage.size.width-8-20, self.yourLocationContainerView.height)];
    yourLocationLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:28];
    yourLocationLabel.textColor = [UIColor blackColor];
    yourLocationLabel.backgroundColor = [UIColor clearColor];
    yourLocationLabel.text = @"To Your Location";
    [self.yourLocationContainerView addSubview:yourLocationLabel];
    
    UIImageView* yourLocationImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.yourLocationContainerView.width-yourLocationImage.size.width-25, 9, yourLocationImage.size.width, yourLocationImage.size.height)];
    yourLocationImageView.image = yourLocationImage;
    [self.yourLocationContainerView addSubview:yourLocationImageView];
    
    
    
    if (!self.isDisplayingCurrentNode) {
        self.tracerouteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.tracerouteButton.frame = CGRectMake(20, self.contentSizeForViewInPopover.height-44-20, 280, 44);
        self.tracerouteButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_REGULAR size:20];
        [self.tracerouteButton setTitle:@"Perform Traceroute" forState:UIControlStateNormal];
        [self.tracerouteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.tracerouteButton setBackgroundImage:[[UIImage imageNamed:@"traceroute-button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 22, 0, 22)] forState:UIControlStateNormal];
        [self.tracerouteButton addTarget:self action:@selector(tracerouteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:self.tracerouteButton];
    }
    
}

- (IBAction)doneTapped {
    if ([self.delegate respondsToSelector:@selector(doneTapped)]) {
        [self.delegate performSelector:@selector(doneTapped)];
    }

}

-(IBAction)tracerouteButtonTapped:(id)sender{
    if ([HelperMethods deviceHasInternetConnection]) {
        //UI setup
        if ([HelperMethods deviceIsiPad]) {
            self.contentSizeForViewInPopover = CGSizeMake(self.contentSizeForViewInPopover.width, 44+20+75+50+self.tracerouteTextView.height+20);
            self.scrollView.frame = CGRectMake(0, 0, self.scrollView.width, 44+20+75+50+self.tracerouteTextView.height+20);
        }
        self.scrollView.contentSize = CGSizeMake(self.contentSizeForViewInPopover.width, 44+20+75+50+self.tracerouteTextView.height+20);

        self.tracerouteContainerView.alpha = 0;
        self.tracerouteContainerView.hidden = NO;
        self.tracerouteTimer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(tracerouteTimerFired) userInfo:nil repeats:YES];
        self.topLabel.text = [NSString stringWithFormat:@"From %@", self.topLabel.text];
        
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

- (void)tracerouteTimerFired {
    [self.box3 incrementNumber];
}

- (void)tracerouteDone {
    CGSize size = [self.tracerouteTextView.text sizeWithFont:self.tracerouteTextView.font constrainedToSize:CGSizeMake(self.tracerouteTextView.width, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    if ([HelperMethods deviceIsiPad]) {
        self.contentSizeForViewInPopover = CGSizeMake(self.contentSizeForViewInPopover.width, 44+20+75+43+MIN(self.tracerouteTextView.height, size.height)+self.yourLocationContainerView.height+20);
        self.yourLocationContainerView.frame = CGRectMake(0, self.contentSizeForViewInPopover.height-self.yourLocationContainerView.height, self.yourLocationContainerView.width, self.yourLocationContainerView.height);
    }else {
        self.yourLocationContainerView.frame = CGRectMake(0, self.contentSizeForViewInPopover.height-self.yourLocationContainerView.height, self.yourLocationContainerView.width, self.yourLocationContainerView.height);
        self.scrollView.contentSize = CGSizeMake(self.contentSizeForViewInPopover.width, 44+20+75+43+MIN(self.tracerouteTextView.height, size.height)+10);
    }
    [UIView animateWithDuration:1 animations:^{
        self.yourLocationContainerView.alpha = 1;
        if (![HelperMethods deviceIsiPad]) {
            self.scrollView.frame = CGRectMake(0, 0, self.scrollView.width, self.contentSizeForViewInPopover.height-44);
        }
    }];

}

@end
