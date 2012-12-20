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

@end

@implementation NodeInformationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil node:(Node*)node
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Node Information";
        [self setContentSizeForViewInPopover:CGSizeMake(320, 200)];
        
        self.node = node;
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
    
    UIColor* tracerouteButtonColor = [UIColor colorWithRed:252.0/255.0 green:161.0/255.0 blue:0 alpha:1];
    [self.tracerouteButton setBackgroundImage:[[HelperMethods imageWithColor:tracerouteButtonColor size:CGSizeMake(1, 1)] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)] forState:UIControlStateNormal];

    UIView* whiteLine = [[UIView alloc] initWithFrame:CGRectMake(self.asnLabel.x, self.asnLabel.y+self.asnLabel.height+12, self.textDescriptionLabel.width, 1)];
    whiteLine.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:whiteLine];
    
    
    self.asnLabel.text = self.node.asn;
    self.textDescriptionLabel.text = self.node.textDescription;
    self.nodeTypeLabel.text = self.node.typeString;
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
