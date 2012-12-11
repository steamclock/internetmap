//
//  SCDispatchQueue.h
//
//  A simple ObjC wrapper around the basic functionality of GCD / dispatch queues, for people who prefer
//  the GCD style to NSOperationQueue, but don't want to be calling the C GCD inteface everywhere,
//  and dealing with some of the warts of that interface
//
// -- Software License --
// 
// Copyright (C) 2011, Steam Clock Software, Ltd.
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
//
#import <Foundation/Foundation.h>

@interface SCDispatchQueue : NSObject

@property (readonly) dispatch_queue_t queue;

+(SCDispatchQueue*)mainQueue;
+(SCDispatchQueue*)backgroundPriorityQueue;
+(SCDispatchQueue*)lowPriorityQueue;
+(SCDispatchQueue*)defaultPriorityQueue;
+(SCDispatchQueue*)highPriorityQueue;

// create a new serial queue with a unique name
+(SCDispatchQueue*)queue;
-(id)init;

// create a new serial queue with supplied name
+(SCDispatchQueue*)queueWithName:(NSString*)name;
-(id)initWithName:(NSString*)name;

// Wrap an existing dispatch queue in a SCDispatchQueue
+(SCDispatchQueue*)queueWithDispatchQueue:(dispatch_queue_t)queue;
-(id)initWithDispatchQueue:(dispatch_queue_t)queue;

// Asynchronously dispatch the block on the queue, just like dispatch_async
-(void)dispatchAsync:(void(^)())block;

// Synchronously dispatch the block on the queue, unlike plain dispatch_sync, this won't 
// deadlock of you try to sync with the current queue (it will just run the block immediatly)
-(void)dispatchSync:(void(^)())block;

// Synchrnously dispatch the block on the queue, with a return value, safe to sync with current queue
-(id)dispatchSyncWithObjectReturn:(id(^)())block;
-(BOOL)dispatchSyncWithBoolReturn:(BOOL(^)())block;
-(int)dispatchSyncWithIntReturn:(int(^)())block;
-(double)dispatchSyncWithDoubleReturn:(double(^)())block;
-(float)dispatchSyncWithFloatReturn:(float(^)())block;

// Dispatch on the queue after a delay
-(void)dispatchAfter:(NSTimeInterval)time block:(void(^)())block;

// Dispatch on the queue with a given time period, until the called block returns FALSE
-(void)dispatchEvery:(NSTimeInterval)time block:(BOOL(^)())block;

// faster, but more dangerous version of dispatchSync, will deadlock if you try to sync 
// with the current queue (like raw dispatch_sync)
-(void)dispatchSyncFast:(void(^)())block;

// Are we currently executing on this queue?
-(BOOL)isCurrent;

@end

@interface SCDispatchGroup : NSObject

//Create a group associated with a particular queue
-(id)initWithQueue:(SCDispatchQueue*)queue;

// Asynchronously dispatch the block on the queue as part of this group
-(void)dispatchAsync:(void(^)())block;

// Wait for the group to complete
-(void)wait;

@end
