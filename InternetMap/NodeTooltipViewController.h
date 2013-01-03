//
//  NodeTooltipViewController.h
//  InternetMap
//
//  Created by Alexander on 21.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Node;

@interface NodeTooltipViewController : UIViewController

@property (nonatomic, strong) Node* node;

- (id)initWithNode:(Node*)node;

@end
