//
//  TimelineInfoViewController.m
//  InternetMap
//
//  Created by Alexander on 18.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "TimelineInfoViewController.h"

@interface TimelineInfoViewController ()

@property(nonatomic, strong) NSDictionary* jsonDict;

@end

@implementation TimelineInfoViewController

- (id)init {
    if (self = [super init]) {
        NSString* json = [[NSBundle mainBundle] pathForResource:@"history" ofType:@"json"];
        self.jsonDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:json] options:0 error:nil];
        self.contentSizeForViewInPopover = CGSizeMake(300, 200);
    }
    
    return self;
}

- (void)viewDidLoad
{
    
    UIView* divider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, 1)];
    divider.backgroundColor = UI_ORANGE_COLOR;
    [self.view addSubview:divider];
    
    
    
//    TTTAttributedLabel* label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 1, self.contentSizeForViewInPopover.width, self.contentSizeForViewInPopover.height)];
//    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:[self.jsonDict objectForKey:[NSString stringWithFormat:@"%i", 2003]]];

    [super viewDidLoad];
    
}

@end
