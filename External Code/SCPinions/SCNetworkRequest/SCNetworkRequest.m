//
//  SCNetworkRequest.m
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

#import "SCNetworkRequest.h"

//---------------------------------------------------------------------------------------------------------------------
@implementation SCNetworkRequestDefaults

@synthesize baseURL, headers, additionalQueryString, error, stripArrayNulls, stripDictionaryNulls;

@end

//---------------------------------------------------------------------------------------------------------------------
@interface SCNetworkRequest () 

@property (readwrite, strong) NSMutableDictionary* headers;

@property (strong) NSURL* url;
@property (strong) NSData* sentData;
@property (strong) NSMutableData* receivedData;
@property (strong) NSURLConnection* connection;
@property (strong) NSString* method;
@property (strong) void (^response)(NSData* data);
@property NSUInteger statusCode;
@end

static int sNumNetworkRequests;

@implementation SCNetworkRequest

@synthesize headers = _headers, error = _error, url = _url, sentData = _sentData, receivedData = _receivedData, connection = _connection, method = _method, response = _response, statusCode =_statusCode;

-(id)initWithURL:(NSString*)url 
        defaults:(SCNetworkRequestDefaults*)defaults
          method:(SCNetworkRequestMethod)method
         content:(NSData*)content 
       autoStart:(BOOL)start
        response:(void (^)(NSData* data))response {
    
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"SCNetworkRequest must be called on main thread");
    NSAssert(response, @"SCNetworkRequest: must have a response block");
    
    if((self = [super init])) {
        
        NSString* completeUrl;
        
        if (defaults.baseURL) {
            completeUrl = [NSString stringWithFormat:@"%@%@", defaults.baseURL, url];
        }
        else {
            completeUrl = url;
        }
        
        self.url = [NSURL URLWithString:completeUrl];
        
        // Tack on query string from defaults
        if (defaults.additionalQueryString) {
            NSString* merged = [[NSString alloc] initWithFormat:@"%@%@%@", [self.url absoluteString], 
                                                                           [self.url query] ? @"&" : @"?", 
                                                                           [defaults.additionalQueryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];     
            
            self.url = [NSURL URLWithString:merged];
        }
        
        // Invalid URL, error out
        if(!self.url) {
            if (defaults.error) {
                defaults.error(nil, 0, nil, nil);
            }
            
            response(nil);
            
            return nil;
        }
        
        self.sentData = content;
        self.response = response;
        
        switch (method) {
            case SCNetworkRequestMethod_Get:
                self.method = @"GET";
                break;
                
            case SCNetworkRequestMethod_Put:
                self.method = @"PUT";
                break;
                
            case SCNetworkRequestMethod_Post:
                self.method = @"POST";
                break;
                
            case SCNetworkRequestMethod_Delete:
                self.method = @"DELETE";
                break;
                
            default:
                NSAssert(FALSE, @"SCNetworkRequest : Unrecognized HTTP method in request creation");
                break;
        }
        
        if (defaults) {
            self.headers = [defaults.headers mutableCopy];
            self.error = defaults.error;
        }
        
        if(!self.headers) {
            self.headers = [NSMutableDictionary new];
        }
        
        if(!self.error) {
            self.error = ^(NSURL* url, NSUInteger httpResponse, NSError* error, NSData* data){
                NSLog(@"SCNetworkRequest Error: %@ - %d -%@", url, httpResponse, error);
            };
        }
        
        if (start) {
            [self start];
        }        
    }
    
    return self;
}

-(void)start {
    NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"SCNetworkRequest must be called on main thread");

    self.receivedData = [NSMutableData new];
    
    NSMutableURLRequest* request= [NSMutableURLRequest requestWithURL:self.url
                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                   timeoutInterval:30.0];
    
    [request setHTTPMethod:self.method];
    [request setHTTPShouldHandleCookies:YES];

    // fill headers
    [self.headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    
    // add in content (if needed)
    if(self.sentData) {

        if (![self.headers objectForKey:@"Content-Type"]) {
            NSLog(@"SCNetworkRequest: missing content type header");
        }
        
        NSString* requestDataLengthString = [[NSString alloc] initWithFormat:@"%d", self.sentData.length];
        [request setValue:requestDataLengthString forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:self.sentData];
    }
        
    // kick off request
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    // Connection could fail to initialize, not sure how exactly. Call error callback and 
    // response if it does to avoid breaking logic in the caller
    if(!self.connection) {
        NSLog(@"SCNetworkRequest: Connection failed to initialize: %@", self.url);
        
        if(self.error) {
            self.error(self.url, 0, nil, nil);
        }
        
        self.response(nil);
        
        return;
    }
    
    // track count of activation, so we can have multiple requests in flight and update indicator properly
    sNumNetworkRequests++;
    
    // turn on network activity indicator if this is the first request
    if (sNumNetworkRequests == 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES]; 
    }

}

-(void)cleanup {
    // turn off network activity indicator if this is the last request
    sNumNetworkRequests--;
    
    if (sNumNetworkRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO]; 
    }
    
    // need to clear out conneciton to shut everything down, otherwise we leak the connection and ourselves
    self.connection = nil;
}
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // If we get a second response, should truncate data rather than appending, probably doesn't matter
    // in practive since we don't handle redirects right now
    [self.receivedData setLength:0];
    
    // store HTTP response for possible inclusion in error later
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        self.statusCode = httpResponse.statusCode;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.error) {
        self.error(self.url, self.statusCode, error, self.receivedData); 
    }
    
    self.response(nil);
 
    [self cleanup];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // We aren't expecting any other status codes
    if (self.error && !((self.statusCode == 200) || (self.statusCode == 201) || (self.statusCode == 202))) {
        self.error(self.url, self.statusCode, nil, self.receivedData); 
        self.response(nil);
    }
    else {
        self.response(self.receivedData);
    }
        
    [self cleanup];
}

@end

//---------------------------------------------------------------------------------------------------------------------
@implementation SCJSONRequest

+(id)stripNulls:(id)container actOnDictionary:(BOOL)actOnDictionary actOnArray:(BOOL)actOnArray {
    if([container isEqual:[NSNull null]]) {
        return nil; 
    }
    else if([container isKindOfClass:[NSArray class]]) {
        
        NSMutableArray* newArray = [NSMutableArray array];
        
        [(NSArray*)container enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if(![obj isEqual:[NSNull null]]) {
                // recursivly strip this object
                [newArray addObject:[SCJSONRequest stripNulls:obj actOnDictionary:actOnDictionary actOnArray:actOnArray]];
            }
            else {
                // re-add NULL to array if we aren't supposed to strip them, otherwise drop it
                if (!actOnArray) {
                    [newArray addObject:obj];
                }
            }
        }];     
        return newArray;
    }
    else if([container isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
        
        [(NSDictionary*)container enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL*stop) {
            if(![obj isEqual:[NSNull null]]) {
                // recursivly strip this value
                [newDict setValue:[SCJSONRequest stripNulls:obj actOnDictionary:actOnDictionary actOnArray:actOnArray] forKey:key];
            }        
            else {
                // re-add null if we aren't supposed to strip them, otherwise drop it
                if (!actOnDictionary) {
                    [newDict setObject:obj forKey:key];
                }
            }
        }];
        
        return newDict;
    }
    
    return container;
}
// Create a new request 
-(id)initWithURL:(NSString*)url 
        defaults:(SCNetworkRequestDefaults*)defaults
          method:(SCNetworkRequestMethod)method
     contentJSON:(NSObject*)contentJSON
       autoStart:(BOOL)start
        response:(void (^)(NSObject* data))response 
{
    NSError* parseError;
    
    NSData* data = nil;
    
    // Turn content object into JSON
    if(contentJSON) {
        data = [NSJSONSerialization dataWithJSONObject:contentJSON options:0 error:&parseError];
        
        if (parseError) {
            if (defaults.error) {
                defaults.error(nil, 0, parseError, nil);
            }
            
            response(nil);
            
            return nil;
        }
    }
    
    // Block to do JSON deserialize for response
    __weak SCJSONRequest* weakSelf = self;
    
    void (^responseWrapper)(NSData*) = ^(NSData* responseData) {
        if (responseData == nil) {
            response(nil);
            return;
        }
        
        NSError* parseError;
        NSObject* deserialized = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];
        
        if(parseError && weakSelf.error) {
            weakSelf.error(nil, 0, parseError, nil);
        }
        
        // strip NSNull objects out of response, if requested
        if (defaults.stripArrayNulls || defaults.stripDictionaryNulls) {
            deserialized = [SCJSONRequest stripNulls:deserialized actOnDictionary:defaults.stripDictionaryNulls actOnArray:defaults.stripArrayNulls];
        }
        
        response(deserialized);
    };
    
    // Set up super class
    if ((self = [super initWithURL:url defaults:defaults method:method content:data autoStart:NO response:responseWrapper])) {
        // Let server know we ave and are looking for JSON
        [self.headers setObject:@"application/json" forKey:@"Accept"];
        
        if (data) {
            [self.headers setObject:@"application/json; charset=utf-8" forKey:@"Content-Type"];
        }
        
        if (start) {
            [self start];
        }
    }
    
    return self;
}

@end

//---------------------------------------------------------------------------------------------------------------------

// Simple server exposing JSON APIS
@implementation SCJSONServer

@synthesize defaults = _defaults;

-(id)init {
    if((self = [super init])) {
        self.defaults = [SCNetworkRequestDefaults new];
    }
    
    return self;
}

-(void)get:(NSString*)apiPath response:(void (^)(NSObject *))responseBlock {
    (void)[[SCJSONRequest alloc] initWithURL:apiPath defaults:self.defaults method:SCNetworkRequestMethod_Get contentJSON:nil autoStart:YES response:responseBlock];
}

-(void)put:(NSString*)apiPath content:(NSObject*)content response:(void (^)(NSObject* data))responseBlock {
    (void)[[SCJSONRequest alloc] initWithURL:apiPath defaults:self.defaults method:SCNetworkRequestMethod_Put contentJSON:content autoStart:YES response:responseBlock];
}

-(void)post:(NSString*)apiPath content:(NSObject*)content response:(void (^)(NSObject* data))responseBlock {
    (void)[[SCJSONRequest alloc] initWithURL:apiPath defaults:self.defaults method:SCNetworkRequestMethod_Post contentJSON:content autoStart:YES response:responseBlock];
}

-(void)delete:(NSString*)apiPath content:(NSObject*)content response:(void (^)(NSObject* data))responseBlock {
    (void)[[SCJSONRequest alloc] initWithURL:apiPath defaults:self.defaults method:SCNetworkRequestMethod_Delete contentJSON:content autoStart:YES response:responseBlock];
}

@end 


