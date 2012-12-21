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
@property (nonatomic, strong) NSMutableArray* firstGroup;
@property (nonatomic, strong) NSMutableArray* secondGroup;

@end

@implementation NodeInformationViewController

- (id)initWithNode:(Node*)node isCurrentNode:(BOOL)isCurrent
{
    self = [super init];
    if (self) {

        
        self.node = node;
        self.isDisplayingCurrentNode = isCurrent;
        
        
        CGFloat height = 0;
        
        //create the first group of strings, like ASN and text description
        NSString* asnText = [NSString stringWithFormat:@"AS%@", self.node.asn];
        self.firstGroup = [NSMutableArray array];
        if (self.isDisplayingCurrentNode) {
            self.title = @"You are here.";
            if (![HelperMethods isStringEmptyOrNil:self.node.textDescription]) {
                [self.firstGroup addObject:self.node.textDescription];
            }
        }else {
            if (![HelperMethods isStringEmptyOrNil:self.node.textDescription]) {
                self.title = self.node.textDescription;
            }else {
                self.title = asnText;
            }
        }
        
        height += 20+55; //top margin and topLabel and white line
                
        if (![self.title isEqualToString:asnText]) {
            [self.firstGroup addObject:asnText];
        }
        
        if (![HelperMethods isStringEmptyOrNil:self.node.typeString]) {
            [self.firstGroup addObject:self.node.typeString];
        }
        
        if ([self.firstGroup count] == 0) {
            [self.firstGroup addObject:@"No additional data."];
        }
        
        height += 25*[self.firstGroup count]; //all labels + margins
        
        
        height += 20+20; //number of connections label
        
        if (!self.isDisplayingCurrentNode) {
            height += 44; //traceroute button
            height += 10; //traceroute button top margin
        }
        
        height += 20; //bottom margin
        
        [self setContentSizeForViewInPopover:CGSizeMake(320, height)];


    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 240, 27)];
    self.topLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25];
    self.topLabel.textColor = [UIColor whiteColor];
    self.topLabel.backgroundColor = [UIColor clearColor];
    self.topLabel.text = self.title;
    [self.view addSubview:self.topLabel];
    
    UIImage* xImage = [UIImage imageNamed:@"x-icon"];
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.frame = CGRectMake(self.topLabel.x+self.topLabel.width+10, 20, xImage.size.width, xImage.size.height);
    [self.doneButton setImage:xImage forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
    
    UIView* whiteLine = [[UIView alloc] initWithFrame:CGRectMake(self.topLabel.x, self.topLabel.y+self.topLabel.height+12, 280, 1)];
    whiteLine.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:whiteLine];
    
        
    float lastLabelBottom = 0;
    //create first group of labels
    for (int i = 0; i < [self.firstGroup count]; i++) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(20, whiteLine.y+whiteLine.height+10+25*i, 280, 20)];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = self.firstGroup[i];
        [self.view addSubview:label];
        if (i == [self.firstGroup count]-1) {
            lastLabelBottom = label.y+label.height;
        }
    }
    
    UILabel* connectionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, lastLabelBottom+25, 280, 20)];
    connectionsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    connectionsLabel.textColor = [UIColor whiteColor];
    connectionsLabel.backgroundColor = [UIColor clearColor];
    connectionsLabel.text = [NSString stringWithFormat:@"%i Connections", [self.node.connections count]];
    [self.view addSubview:connectionsLabel];
    
    if (!self.isDisplayingCurrentNode) {
        self.tracerouteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.tracerouteButton.frame = CGRectMake(20, self.contentSizeForViewInPopover.height-44-20, 280, 44);
        [self.tracerouteButton setTitle:@"PERFORM TRACEROUTE" forState:UIControlStateNormal];
        [self.tracerouteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.tracerouteButton setTitleShadowColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.tracerouteButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
        UIColor* tracerouteButtonColor = [UIColor colorWithRed:252.0/255.0 green:161.0/255.0 blue:0 alpha:1];
        [self.tracerouteButton setBackgroundImage:[[HelperMethods imageWithColor:tracerouteButtonColor size:CGSizeMake(1, 1)] resizableImageWithCapInsets:UIEdgeInsetsZero] forState:UIControlStateNormal];
        [self.view addSubview:self.tracerouteButton];
    }
}

- (IBAction)doneTapped {
    if ([self.delegate respondsToSelector:@selector(doneTapped)]) {
        [self.delegate performSelector:@selector(doneTapped)];
    }

}

-(IBAction)tracerouteButtonTapped:(id)sender{
    if ([self.delegate respondsToSelector:@selector(tracerouteButtonTapped)]) {
        [self.delegate performSelector:@selector(tracerouteButtonTapped)];
    }
}

@end
