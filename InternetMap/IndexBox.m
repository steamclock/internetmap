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

- (void)setMinCorner:(GLKVector3)minCorner {
    _minCorner = minCorner;
    parameters[0] = minCorner;
}

- (void)setMaxCorner:(GLKVector3)maxCorner {
    _maxCorner = maxCorner;
    parameters[1] = maxCorner;
}

- (BOOL)doesLineIntersectOptimized:(GLKVector3)origin pointB:(GLKVector3)invertedDirection sign:(int *)sign {
    float tmin, tmax, tymin, tymax, tzmin, tzmax;
    
    tmin = (parameters[sign[0]].x - origin.x) * invertedDirection.x;
    tmax = (parameters[1-sign[0]].x - origin.x) * invertedDirection.x;
    tymin = (parameters[sign[1]].y - origin.y) * invertedDirection.y;
    tymax = (parameters[1-sign[1]].y - origin.y) * invertedDirection.y;
    if ( (tmin > tymax) || (tymin > tmax) )
        return false;
    if (tymin > tmin)
        tmin = tymin;
    if (tymax < tmax)
        tmax = tymax;
    tzmin = (parameters[sign[2]].z - origin.z) * invertedDirection.z;
    tzmax = (parameters[1-sign[2]].z - origin.z) * invertedDirection.z;
    if ( (tmin > tzmax) || (tzmin > tmax) )
        return false;
    
    
    return true;

}

@end
