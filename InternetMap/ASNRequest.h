//
//  ASNRequest.h
//  InternetMap
//
//  Created by Alexander on 12.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASNRequest;

@protocol ASNRequestDelegate <NSObject>

- (void)asnRequestFinished:(ASNRequest*)request;

@end


@interface ASNRequest : NSObject

- (void)finishedFetchingASN:(NSDictionary*)dict;
- (void)failedFetchingASN:(NSDictionary*)dict;
- (void)start;
- (void)setArrIPs:(NSArray*)arr;
- (void)setSingleIP:(NSString*)str;


@property (nonatomic, weak) id<ASNRequestDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray* result;


@end

