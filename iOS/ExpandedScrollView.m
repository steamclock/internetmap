//
//  ExpandedScrollView.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-15.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "ExpandedScrollView.h"

@implementation ExpandedScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    CGRect bounds = self.superview.bounds;
    bounds.origin.x -= self.frame.origin.x;
    bounds.origin.y -= self.frame.origin.y;
    
    point.x -= self.contentOffset.x;
    point.y -= self.contentOffset.y;

    return CGRectContainsPoint(bounds, point);
}

@end
