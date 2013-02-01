//
//  ExpandedSlider.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-01-30.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "ExpandedSlider.h"

#define THUMB_SIZE 10
#define EFFECTIVE_THUMB_SIZE 40

@implementation ExpandedSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent*)event {
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, -10, -30);
    return CGRectContainsPoint(bounds, point);
}

- (BOOL) beginTrackingWithTouch:(UITouch*)touch withEvent:(UIEvent*)event {
    CGRect bounds = self.bounds;
    float thumbPercent = (self.value - self.minimumValue) / (self.maximumValue - self.minimumValue);
    float thumbPos = THUMB_SIZE + (thumbPercent * (bounds.size.width - (2 * THUMB_SIZE)));
    CGPoint touchPoint = [touch locationInView:self];
    return (touchPoint.x >= (thumbPos - EFFECTIVE_THUMB_SIZE) && touchPoint.x <= (thumbPos + EFFECTIVE_THUMB_SIZE));
}

@end
