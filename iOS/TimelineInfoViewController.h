//
//  TimelineInfoViewController.h
//  InternetMap
//
//  Created by Alexander on 18.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimelineInfoViewController : UIViewController

@property(nonatomic, strong) NSDictionary* jsonDict;
@property(nonatomic, assign) int year;

-(void)startLoad;

@end
