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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
    
    self.asnLabel.text = self.node.asn;
    self.textDescriptionLabel.text = self.node.textDescription;
    self.nodeTypeLabel.text = self.node.typeString;
}

- (void)doneTapped {
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
