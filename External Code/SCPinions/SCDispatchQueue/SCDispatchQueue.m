//
//  SCDispatchQueue.m
//
// -- Software License --
//
// Copyright (C) 2013, Steam Clock Software, Ltd.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// ----------------------

#import "SCDispatchQueue.h"

@interface SCDispatchQueue ()
@property dispatch_queue_t queue;
@end

static SCDispatchQueue* mainQueue;
static SCDispatchQueue* backgroundPriorityQueue;
static SCDispatchQueue* lowPriorityQueue;
static SCDispatchQueue* defaultPriorityQueue;
static SCDispatchQueue* highPriorityQueue;

static int uniqueQueueId = 0;

@implementation SCDispatchQueue

@synthesize queue = _queue;

+(SCDispatchQueue*)mainQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainQueue = [[SCDispatchQueue alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    });
    
    return mainQueue;
}

+(SCDispatchQueue*)backgroundPriorityQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        backgroundPriorityQueue = [[SCDispatchQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    });
    
    return backgroundPriorityQueue;
}

+(SCDispatchQueue*)lowPriorityQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lowPriorityQueue = [[SCDispatchQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)];
    });
    
    return lowPriorityQueue;
}

+(SCDispatchQueue*)defaultPriorityQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultPriorityQueue = [[SCDispatchQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    });
    
    return defaultPriorityQueue;
}

+(SCDispatchQueue*)highPriorityQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        highPriorityQueue = [[SCDispatchQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    });
    
    return highPriorityQueue;
}

+(SCDispatchQueue*)queue {
    return [[SCDispatchQueue alloc] init];
}

+(SCDispatchQueue*)queueWithName:(NSString*)name {
    return [[SCDispatchQueue alloc] initWithName:name];
}

+(SCDispatchQueue*)queueWithDispatchQueue:(dispatch_queue_t)queue {
    return [[SCDispatchQueue alloc] initWithDispatchQueue:queue];
}

-(id)init {
    return [self initWithName:[NSString stringWithFormat:@"com.steamclocksw.scdispatch%.4d", uniqueQueueId++]];
}

-(id)initWithName:(NSString*)name
{
    if((self = [super init])) {
        self.queue = dispatch_queue_create([name cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        dispatch_queue_set_specific(self.queue, (__bridge void *)self, (__bridge void *)self.queue, NULL);
    }
    return self;
}

-(id)initWithDispatchQueue:(dispatch_queue_t)inQueue {
    if((self = [super init])) {
        self.queue = inQueue;
        dispatch_queue_set_specific(self.queue, (__bridge void *)self, (__bridge void *)self.queue, NULL);
    }
    return self;
}

-(void)dispatchAsync:(void(^)())block {
    dispatch_async(self.queue, block);
}

-(void)dispatchSync:(void(^)())block {
    if ([self isCurrent]) {
        block();
    }
    else {
        dispatch_sync(self.queue, block);
    }
}

#define DISPATCH_SYNC_RETURN_IMPLIMENTATION(type, block, queue) \
__block type ret;\
\
if ([self isCurrent]) {\
return block();\
}\
else {\
dispatch_sync(queue, ^{\
ret = block();\
});\
}\
\
return ret;

-(id)dispatchSyncWithObjectReturn:(id(^)())block {
    DISPATCH_SYNC_RETURN_IMPLIMENTATION(id, block, self.queue);
}

-(BOOL)dispatchSyncWithBoolReturn:(BOOL(^)())block {
    DISPATCH_SYNC_RETURN_IMPLIMENTATION(BOOL, block, self.queue);
}

-(int)dispatchSyncWithIntReturn:(int(^)())block {
    DISPATCH_SYNC_RETURN_IMPLIMENTATION(int, block, self.queue);
}

-(float)dispatchSyncWithFloatReturn:(float(^)())block {
    DISPATCH_SYNC_RETURN_IMPLIMENTATION(float, block, self.queue);
}

-(double)dispatchSyncWithDoubleReturn:(double(^)())block {
    DISPATCH_SYNC_RETURN_IMPLIMENTATION(double, block, self.queue);
}

-(void)dispatchAfter:(NSTimeInterval)time block:(void(^)())block {
    double delayInSeconds = time;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}

-(void)dispatchEvery:(NSTimeInterval)time block:(BOOL(^)())block {
    __block dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.queue);
    
    if(!timer) {
        return;
    }
    
    void (^wrapper)() = ^{
        BOOL shouldContinue = block();
        
        if(!shouldContinue) {
            timer = NULL;
        }
    };
    
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), time * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC); // TODO: selectable leeway?
    dispatch_source_set_event_handler(timer, wrapper);
    dispatch_resume(timer);
}

-(void)dispatchSyncFast:(void(^)())block {
    dispatch_sync(self.queue, block);
}

-(BOOL)isCurrent {
    return dispatch_get_specific((__bridge void *)self) == (__bridge void *)(self.queue);
}

@end

@interface SCDispatchGroup()
@property (strong) SCDispatchQueue* queue;
@property dispatch_group_t group;
@end

@implementation SCDispatchGroup : NSObject

-(id)initWithQueue:(SCDispatchQueue*)queue {
    if((self = [super init])) {
        self.queue = queue;
        self.group = dispatch_group_create();
    }
    
    return self;
}

-(void)dispatchAsync:(void(^)())block {
    dispatch_group_async(self.group, self.queue.queue, block);
}

// Wait for the group to complete
-(void)wait {
    dispatch_group_wait(self.group, DISPATCH_TIME_FOREVER);
}


@end
