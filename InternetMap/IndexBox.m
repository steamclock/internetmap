//
//  IndexBox.m
//  InternetMap
//
//  Created by Alexander on 11.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "IndexBox.h"

@interface IndexBox()


@end

@implementation IndexBox

- (id)init {
    if (self = [super init]) {
        self.indices = [NSMutableIndexSet indexSet];
    }
    
    return self;
}

- (BOOL)isPointInside:(GLKVector3)point {
    return (point.x > self.center.x-boxSizeXWithoutOverlap) && (point.x < self.center.x+boxSizeXWithoutOverlap) &&
            (point.y > self.center.y-boxSizeYWithoutOverlap) && (point.y < self.center.y+boxSizeYWithoutOverlap) &&
            (point.z > self.center.z-boxSizeZWithoutOverlap) && (point.z < self.center.z+boxSizeZWithoutOverlap);
}


@end
