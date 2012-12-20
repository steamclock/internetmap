//
//  Nodes.h
//  InternetMap
//
//  Created by Alexander on 17.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Nodes : NSObject

-(id)initWithNodeCount:(NSUInteger)count;

// Note: Must bracket calls to updateNode with beginUpdate/endUpdate
-(void)beginUpdate;
-(void)endUpdate;
-(void)updateNode:(NSUInteger)index position:(GLKVector3)pos size:(float)size color:(UIColor*)color;
-(void)updateNode:(NSUInteger)index position:(GLKVector3)pos;
-(void)updateNode:(NSUInteger)index size:(float)size;
-(void)updateNode:(NSUInteger)index color:(UIColor*)color;

-(void)display;

-(NSUInteger)count;

@end
