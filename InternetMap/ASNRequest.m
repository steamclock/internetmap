//
//  ASNRequest.m
//  InternetMap
//
//  Created by Alexander on 12.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "ASNRequest.h"
#import <dns_sd.h>

@interface ASNRequest()

@property (nonatomic, readwrite) NSMutableArray* result;
@property (nonatomic, strong) ASNResponseBlock response;

- (void)finishedFetchingASN:(int)asn forIndex:(int)index;
- (void)failedFetchingASNForIndex:(int)index error:(NSString*)error;

@end

void callbackCurrent (
               DNSServiceRef sdRef,
               DNSServiceFlags flags,
               uint32_t interfaceIndex,
               DNSServiceErrorType errorCode,
               const char *fullname,
               uint16_t rrtype,
               uint16_t rrclass,
               uint16_t rdlen,
               const void *rdata,
               uint32_t ttl,
               void *context ) {
    
    NSData* data = [NSData dataWithBytes:rdata length:strlen(rdata)+1];
    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    int value;
    NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    BOOL success = [[NSScanner scannerWithString:[string stringByTrimmingCharactersInSet:nonDigits]] scanInteger:&value];
    
    NSDictionary* dict = (__bridge NSDictionary*)context;
    
    ASNRequest* request = [dict objectForKey:@"request"];
    int index = [[dict objectForKey:@"index"] intValue];
    
    if (success) {
        [request finishedFetchingASN:value forIndex:index];
    }
    else {
        [request failedFetchingASNForIndex:index error: @"Couldn't resolve DNS."];
    }
}


@implementation ASNRequest

- (void)startFetchingASNsForIPs:(NSArray*)theIPs{
    self.result = [NSMutableArray arrayWithCapacity:theIPs.count];
    
    for (int i = 0; i < theIPs.count; i++) {
        [self.result addObject:[NSNull null]];
    }
    
    [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
        for (int i = 0; i < [theIPs count]; i++) {
            NSString* ip = [theIPs objectAtIndex:i];
            if (!ip || [ip isEqualToString:@""]) {
                [[SCDispatchQueue mainQueue] dispatchAsync:^{
                    [self failedFetchingASNForIndex:i error:@"Couldn't resolve DNS."];
                }];
            }else {
                [self fetchASNForIP:ip index:i];
            }
        }
        
        if (self.response) {
            self.response(self.result);
        }
    }];

}

- (void)fetchASNForIP:(NSString*)ip index:(int)index{
    NSArray* ipComponents = [ip componentsSeparatedByString:@"."];
    NSString* dnsString = [NSString stringWithFormat:@"origin.asn.cymru.com"];
    for (NSString* component in ipComponents) {
        dnsString = [NSString stringWithFormat:@"%@.%@", component, dnsString];
    }
    DNSServiceRef sdRef;
    DNSServiceErrorType res;
    
    NSDictionary* context = @{@"request" : self, @"index" : [NSNumber numberWithInt:index]};
    
    res = DNSServiceQueryRecord(
                                &sdRef, 0, 0,
                                [dnsString cStringUsingEncoding:NSUTF8StringEncoding],
                                kDNSServiceType_TXT,
                                kDNSServiceClass_IN,
                                callbackCurrent,
                                (__bridge void *)context
                                );
    
    if (res != kDNSServiceErr_NoError) {
        [[SCDispatchQueue mainQueue] dispatchAsync:^{
            [self failedFetchingASNForIndex:index error:@"Couldn't resolve DNS."];
        }];
    }
    
    DNSServiceProcessResult(sdRef);
    DNSServiceRefDeallocate(sdRef);
    
}

- (void)finishedFetchingASN:(int)asn forIndex:(int)index {
    NSLog(@"ASN fetched for index %i: %i", index, asn);
    [self.result replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:asn]];
}

- (void)failedFetchingASNForIndex:(int)index error:(NSString*)error {
    NSLog(@"Failed for index: %i, error: %@", index, error);
}

+(void)fetchForAddresses:(NSArray*)addresses responseBlock:(ASNResponseBlock)response {
    ASNRequest* request = [ASNRequest new];
    request.response = response;
    [request startFetchingASNsForIPs:addresses];
}

@end
