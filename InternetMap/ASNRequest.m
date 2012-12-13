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

@property (nonatomic, assign) BOOL hasStarted;
@property (nonatomic, strong) NSArray* arrIPs;
@property (nonatomic, strong) NSString* singleIP;
@property (nonatomic, assign) int numberOfRequests;
@property (nonatomic, readwrite) NSMutableArray* result;

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
    //TODO: I believe this bridging will leak! Should use __bridge_transfer, but crashes for some reason
    NSDictionary* dict = (__bridge NSDictionary*)context;
    ASNRequest* request = [dict objectForKey:@"request"];
    if (success) {
        [request finishedFetchingASN:@{@"asn" : [NSNumber numberWithInt:value], @"index" : [dict objectForKey:@"index"]}];
    }else {
        [request failedFetchingASN:@{@"error" : @"Couldn't resolve DNS.", @"index" : [dict objectForKey:@"index"]}];
    }
}


@implementation ASNRequest

- (void)start {
    if (self.arrIPs && [self.arrIPs count]) {
        self.numberOfRequests = [self.arrIPs count];
        [self initResultsArray];
        [self startFetchingASNsForIPs:self.arrIPs];
    }else if(self.singleIP && ![self.singleIP isEqualToString:@""]) {
        self.numberOfRequests = 1;
        [self initResultsArray];
        [self startFetchingASNsForIPs:@[self.singleIP]];
    }else {
        self.numberOfRequests = 1;
        [self initResultsArray];
        [self startFetchingCurrentASN];
    }
}

- (void)initResultsArray {

    self.result = [NSMutableArray arrayWithCapacity:self.numberOfRequests];
    for (int i = 0; i < self.numberOfRequests; i++) {
        [self.result addObject:[NSNull null]];
    }

}

- (void)startFetchingASNsForIPs:(NSArray*)theIPs{
    [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
        for (int i = 0; i < [theIPs count]; i++) {
            NSString* ip = [theIPs objectAtIndex:i];
            if (!ip || [ip isEqualToString:@""]) {
                [[SCDispatchQueue mainQueue] dispatchAsync:^{
                    [self failedFetchingASN:@{@"error" : @"Couldn't resolve DNS.", @"index" : [NSNumber numberWithInt:i]}];
                }];
            }else {
                [self fetchASNForIP:ip index:i];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(asnRequestFinished:)]) {
            [self.delegate asnRequestFinished:self];
        }
    }];

}

- (void)startFetchingCurrentASN {
    [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
        NSString* ip = [self fetchGlobalIP];
        if (!ip || [ip isEqualToString:@""]) {
            [[SCDispatchQueue mainQueue] dispatchAsync:^{
                [self failedFetchingASN:@{@"error" : @"Couldn't resolve DNS.", @"index" : [NSNumber numberWithInt:-1]}];
            }];
        }else {
            [[SCDispatchQueue mainQueue] dispatchAsync:^{
                [self startFetchingASNsForIPs:@[ip]];
            }];
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
    
    res = DNSServiceQueryRecord(
                                &sdRef, 0, 0,
                                [dnsString cStringUsingEncoding:NSUTF8StringEncoding],
                                kDNSServiceType_TXT,
                                kDNSServiceClass_IN,
                                callbackCurrent,
                                (__bridge_retained void *)(@{@"request" : self, @"index" : [NSNumber numberWithInt:index]})
                                );
    
    if (res != kDNSServiceErr_NoError) {
        [[SCDispatchQueue mainQueue] dispatchAsync:^{
            [self failedFetchingASN:@{@"error" : @"Couldn't resolve DNS.", @"index" : [NSNumber numberWithInt:index]}];
        }];
    }
    
    DNSServiceProcessResult(sdRef);
    DNSServiceRefDeallocate(sdRef);
    
}

- (void)fetchASNForIP:(NSString*)ip {
    [self fetchASNForIP:ip index:-1];
}



- (NSString*)fetchGlobalIP {
    NSString* address = @"http://stage.steamclocksw.com/ip.php";
    NSURL *url = [[NSURL alloc] initWithString:address];
    NSError* error;
    NSString *ip = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
    return ip;
}

- (void)finishedFetchingASN:(NSDictionary*)dict {

    
    int asn = [[dict objectForKey:@"asn"] intValue];
    int index = [[dict objectForKey:@"index"] intValue];
    NSLog(@"ASN fetched for index %i: %i", index, asn);
    [self.result replaceObjectAtIndex:index withObject:[dict objectForKey:@"asn"]];
}

- (void)failedFetchingASN:(NSDictionary*)dict {
    NSString* error = [dict objectForKey:@"error"];
    int index = [[dict objectForKey:@"index"] intValue];
    NSLog(@"Failed for index: %i, error: %@", index, error);
}


@end
