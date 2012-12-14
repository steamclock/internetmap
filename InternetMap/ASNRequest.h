//
//  ASNRequest.h
//  InternetMap
//
//  Created by Alexander on 12.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ASNResponseBlock)(NSArray* asn);

@interface ASNRequest : NSObject

+(void)fetchForAddresses:(NSArray*)addresses responseBlock:(ASNResponseBlock)result;
+(void)fetchForASN:(int)asn responseBlock:(ASNResponseBlock)result;

@end

