//
//  NodeTooltipViewController.h
//  InternetMap
//
//  Created by Alexander on 21.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "Node.hpp"

@interface NodeTooltipViewController : UIViewController

@property (nonatomic) NodePointer node;

- (id)initWithNode:(NodePointer)node;

@end
