//
//  NodeInformationViewController.m
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-04.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeInformationViewController.h"
#import "Node.h"

@interface NodeInformationViewController ()

@property (nonatomic, strong) Node* node;
@property (nonatomic, strong) UIButton* doneButton;
@property (nonatomic, assign) BOOL isDisplayingCurrentNode;
@property (nonatomic, strong) NSMutableArray* firstGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* secondGroupOfStrings;
@property (nonatomic, strong) NSMutableArray* infoLabels;
@end

@implementation NodeInformationViewController

- (id)initWithNode:(Node*)node isCurrentNode:(BOOL)isCurrent
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
        if (self.isDisplayingCurrentNode) {
            self.title = @"You are here.";
            if (![HelperMethods isStringEmptyOrNil:self.node.textDescription]) {
                [self.firstGroupOfStrings addObject:self.node.textDescription];
            }
        }else {
            if (![HelperMethods isStringEmptyOrNil:self.node.textDescription]) {
                self.title = self.node.textDescription;
            }else {
                self.title = asnText;
            }
        }
        
        height += 20+35; //top margin and topLabel and white line
                
        if (![self.title isEqualToString:asnText]) {
            [self.firstGroupOfStrings addObject:asnText];
        }
        
        if (![HelperMethods isStringEmptyOrNil:self.node.typeString]) {
            [self.firstGroupOfStrings addObject:self.node.typeString];
        }
        
        if ([self.firstGroupOfStrings count] == 0) {
            [self.firstGroupOfStrings addObject:@"No additional data."];
        }
        
        height += 25*[self.firstGroupOfStrings count]; //all labels + margins
        
        
        height += 20+20; //number of connections label
        
        if (!self.isDisplayingCurrentNode) {
            height += 44; //traceroute button
            height += 10; //traceroute button top margin
        }
        
        height += 20; //bottom margin
        
        [self setContentSizeForViewInPopover:CGSizeMake(475, height)];


    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage* xImage = [UIImage imageNamed:@"x-icon"];

    UIView* orangeBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, 44)];
    orangeBackgroundView.backgroundColor = UI_ORANGE_COLOR;
    [self.view addSubview:orangeBackgroundView];
    
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, -2, self.contentSizeForViewInPopover.width-xImage.size.width-24, 44)];
    self.topLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:24];
    self.topLabel.textColor = [UIColor blackColor];
    self.topLabel.backgroundColor = [UIColor clearColor];
    self.topLabel.text = self.title;
    [self.view addSubview:self.topLabel];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.frame = CGRectMake(self.topLabel.x+self.topLabel.width+5, 12, xImage.size.width, xImage.size.height);
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
        [self.view addSubview:label];
        if (i == [self.firstGroupOfStrings count]-1) {
            lastLabelBottom = label.y+label.height;
        }
        [self.infoLabels addObject:label];
    }
    
    UILabel* connectionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, lastLabelBottom+25, 280, 20)];
    connectionsLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:18];
    connectionsLabel.textColor = FONT_COLOR_GRAY;
    connectionsLabel.backgroundColor = [UIColor clearColor];
    NSString* conn = [self.node.connections count] == 1 ? @"Connection" : @"Connections";
    connectionsLabel.text = [NSString stringWithFormat:@"%i %@", [self.node.connections count], conn];
    [self.view addSubview:connectionsLabel];
    [self.infoLabels addObject:connectionsLabel];
    
    self.tracerouteTextView = [[UITextView alloc] initWithFrame:CGRectMake(orangeBackgroundView.x, orangeBackgroundView.y+15, orangeBackgroundView.width, 500                                 )];
    self.tracerouteTextView.backgroundColor = [UIColor clearColor];
    self.tracerouteTextView.textColor = [UIColor whiteColor];
    self.tracerouteTextView.editable = NO;
    self.tracerouteTextView.userInteractionEnabled = YES;
    self.tracerouteTextView.scrollEnabled = YES;
    self.tracerouteTextView.hidden = YES;
    self.tracerouteTextView.font = [UIFont fontWithName:@"CourierNewPSMT" size:12];
    [self.view addSubview:self.tracerouteTextView];

    
    if (!self.isDisplayingCurrentNode) {
        self.tracerouteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.tracerouteButton.frame = CGRectMake(20, self.contentSizeForViewInPopover.height-44-20, 280, 44);
        [self.tracerouteButton setTitle:@"PERFORM TRACEROUTE" forState:UIControlStateNormal];
        [self.tracerouteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.tracerouteButton setTitleShadowColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.tracerouteButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
        [self.tracerouteButton setBackgroundImage:[[HelperMethods imageWithColor:UI_ORANGE_COLOR size:CGSizeMake(1, 1)] resizableImageWithCapInsets:UIEdgeInsetsZero] forState:UIControlStateNormal];
        [self.tracerouteButton addTarget:self action:@selector(tracerouteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.tracerouteButton];
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
        self.contentSizeForViewInPopover = CGSizeMake(340, 595);
        self.tracerouteTextView.alpha = 0;
        self.tracerouteTextView.hidden = NO;
        
        [UIView animateWithDuration:1 animations:^{
            self.tracerouteTextView.alpha = 1;
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

@end
