//
//  Node.m
//  InternetMap
//

#import "Node.h"

@implementation Node


- (id)init {
    if (self = [super init]) {
        self.connections = [NSMutableArray array];
    }
    
    return self;
}

@end
