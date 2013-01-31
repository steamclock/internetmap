//
//  ASNRequest.m
//  InternetMap
//
//  Created by Alexander on 12.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "ASNRequest.h"
#import <dns_sd.h>
#import "ASIFormDataRequest.h"
#import <arpa/inet.h>
#import <netdb.h>

@interface ASNRequest()

@property (nonatomic, readwrite) NSMutableArray* result;
@property (nonatomic, strong) ASNResponseBlock response;

- (void)finishedFetchingASN:(NSString*)asn forIndex:(int)index;
- (void)failedFetchingASNForIndex:(int)index error:(NSString*)error;

@end

@implementation ASNRequest

-(BOOL)isInvalidOrPrivate:(NSString*)ipAddress {
    NSArray* components = [ipAddress componentsSeparatedByString:@"."];
    
    if(components.count != 4) {
        return TRUE;
    }
    
    int a = [components[0] intValue];
    int b = [components[1] intValue];
    
    if (a == 10) {
        return TRUE;
    }
    
    if((a == 172) && ((b >= 16) && (b <= 31))) {
        return TRUE;
    }
    
    if((a == 192) && (b == 168)) {
        return TRUE;
    }
    
    return FALSE;
}

- (void)startFetchingASNsForIPs:(NSArray*)theIPs{
    self.result = [NSMutableArray arrayWithCapacity:theIPs.count];
    int numberOfIPs = [theIPs count];
    
    for (int i = 0; i < numberOfIPs; i++) {
        [self.result addObject:[NSNull null]];
    }
    
    for (int i = 0; i < numberOfIPs; i++) {
        
        NSString* ip = [theIPs objectAtIndex:i];
        
        if ([ip isEqual:[NSNull null]]) {
            [self failedFetchingASNForIndex:i error:@"No ASN needed, this was a timed out hop."];
        } else if ([self isInvalidOrPrivate:ip]){
            [self failedFetchingASNForIndex:i error:@"No ASN, this was an invalid or private address."];
        } else {
            [self fetchASNForIP:ip index:i];
        }
    }
    
}

- (void)fetchASNForIP:(NSString*)ip index:(int)index{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://72.51.24.24:8080/iptoasn"]];
    [request setShouldAttemptPersistentConnection:YES];
    [request setTimeOutSeconds:60];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    NSString *dataString = [NSString stringWithFormat:@"{\"ip\":\"%@\"}", ip];
    [request appendPostData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setCompletionBlock:^{
        NSError* error = request.error;
        NSDictionary* jsonResponse = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingAllowFragments error:&error];
        NSString* payload = [jsonResponse objectForKey:@"payload"];
        NSString* asnWithoutPrefix = [payload substringWithRange:NSMakeRange(2, payload.length -2)];
        [self finishedFetchingASN:asnWithoutPrefix forIndex:index];
        
    }];
    
    [request setFailedBlock:^{
        [self failedFetchingASNForIndex:index error:[NSString stringWithFormat:@"%@", request.error]];
    }];

    [request start];
}

- (void)finishedFetchingASN:(NSString*)asn forIndex:(int)index {
    [self.result replaceObjectAtIndex:index withObject:asn];
    if (self.response) {
        self.response(self.result);
    }
}

- (void)failedFetchingASNForIndex:(int)index error:(NSString*)error {
    // Really only need to print this for debugging
    // NSLog(@"Failed for index: %i, Error msg: %@", index, error);
}

+(void)fetchForAddresses:(NSArray*)addresses responseBlock:(ASNResponseBlock)response {
    ASNRequest* request = [ASNRequest new];
    request.response = response;
    [request startFetchingASNsForIPs:addresses];
}

+(void)fetchForASN:(NSString*)asn responseBlock:(ASNResponseBlock)response {
    __weak ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://bgp.he.net/AS%@", asn]]];
    [request setCompletionBlock:^{
        NSRange range = [[request responseString] rangeOfString:@"/net/.*?/" options:NSRegularExpressionSearch];
        if(range.location != NSNotFound) {
            NSString* string = [[request responseString] substringWithRange:NSMakeRange(range.location+5, range.length-6)];
            response(@[string]);
        } else {
            response(@[[NSNull null]]);
        }
        
    }];
    [request startAsynchronous];
}

// Get a set of IP addresses for a given host name
// Originally pulled from here: http://www.bdunagan.com/2009/11/28/iphone-tip-no-nshost/
// MIT License

+ (NSArray *)addressesForHostname:(NSString *)hostname {
    // Get the addresses for the given hostname.
    CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostname);
    
    BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostAddresses, nil);
    if (!isSuccess) {
        CFRelease(hostRef);
        return nil;
    }
    CFArrayRef addressesRef = CFHostGetAddressing(hostRef, nil);
    if (addressesRef == nil)  {
        CFRelease(hostRef);
        return nil;
    }
    // Convert these addresses into strings.
    char ipAddress[INET6_ADDRSTRLEN];
    NSMutableArray *addresses = [NSMutableArray array];
    CFIndex numAddresses = CFArrayGetCount(addressesRef);
    for (CFIndex currentIndex = 0; currentIndex < numAddresses; currentIndex++) {
        struct sockaddr *address = (struct sockaddr *)CFDataGetBytePtr(CFArrayGetValueAtIndex(addressesRef, currentIndex));
        
        if (address == nil) {
            CFRelease(hostRef);
            return nil;
        }
        
        getnameinfo(address, address->sa_len, ipAddress, INET6_ADDRSTRLEN, nil, 0, NI_NUMERICHOST);
        
        if (ipAddress == nil) {
            CFRelease(hostRef);
            return nil;
        }
        
        [addresses addObject:[NSString stringWithCString:ipAddress encoding:NSASCIIStringEncoding]];
    }
    
    CFRelease(hostRef);
    return addresses;
}


+ (void)fetchGlobalIPWithCompletionBlock:(void (^)(NSString* ip))completion failedBlock:(void(^)(void))failedBlock {
    __weak ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"http://stage.steamclocksw.com/ip.php"]];
    [request setCompletionBlock:^{
        completion([request responseString]);
    }];
    [request setFailedBlock:failedBlock];
    [request startAsynchronous];
}

+ (void)fetchCurrentASNWithResponseBlock:(ASNResponseBlock)response errorBlock:(void(^)(void))error{
    [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
        [self fetchGlobalIPWithCompletionBlock:^(NSString * ip) {
            if (!ip || [ip isEqualToString:@""]) {
                error();
            } else {
                [ASNRequest fetchForAddresses:@[ip] responseBlock:response];
            }
        } failedBlock:error];
        
    }];
}

@end
