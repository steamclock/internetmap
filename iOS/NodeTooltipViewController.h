//
//  NodeTooltipViewController.h
//  InternetMap
//
//  Created by Alexander on 21.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NodeWrapper;

@interface NodeTooltipViewController : UIViewController

@property (nonatomic) NodeWrapper* node;
@property (strong) NSString* text;

- (id)initWithNode:(NodeWrapper*)node;

@end
