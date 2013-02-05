//
//  ASNRequest.h
//  InternetMap
//
//  Created by Alexander on 12.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ASNArrayResponseBlock)(NSArray* result);
typedef void (^ASNStringResponseBlock)(NSString* result);

@interface ASNRequest : NSObject

+(void)fetchASNForIP:(NSString*)ip response:(ASNStringResponseBlock)result;
+(void)fetchIPsForASN:(NSString*)asn response:(ASNArrayResponseBlock)result;
+(void)fetchIPsForHostname:(NSString*)hostname response:(ASNArrayResponseBlock)result;
+(void)fetchCurrentASN:(ASNStringResponseBlock)response;

@end

