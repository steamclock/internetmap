//
//  NodeTooltipViewController.m
//  InternetMap
//
//  Created by Alexander on 21.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeTooltipViewController.h"
#import "Node.hpp"

@interface NodeTooltipViewController ()
@end

@implementation NodeTooltipViewController

- (id)initWithNode:(NodePointer)node
{
    self = [super init];
    if (self) {
        self.node = node;
        self.contentSizeForViewInPopover = CGSizeMake(320, 44);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, self.contentSizeForViewInPopover.width-10, 26)];
    label.centerY = self.contentSizeForViewInPopover.height/2;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:22];
    if ([HelperMethods isStringEmptyOrNil:[NSString stringWithUTF8String:self.node->textDescription.c_str()]]) {
        label.text = [NSString stringWithFormat:@"AS%s", self.node->asn.c_str()];
    }else {
        label.text = [NSString stringWithUTF8String:self.node->textDescription.c_str()];
    }
    [self.view addSubview:label];
}

@end
