//
//  SCNetworkRequest.h
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

#import <Foundation/Foundation.h>

typedef enum {
    SCNetworkRequestMethod_Get,
    SCNetworkRequestMethod_Put,
    SCNetworkRequestMethod_Post,
    SCNetworkRequestMethod_Delete
} SCNetworkRequestMethod;

typedef void (^SCNetworkError)(NSURL* url, NSUInteger httpResponse, NSError* error, NSData* data);

//---------------------------------------------------------------------------------------------------------------------
// Store a set of default values to be used for the properties of the request, without having to set them individually
// all the time
@interface SCNetworkRequestDefaults : NSObject

// If set, this is prepended to the request URL. Note: does not try to do anything clever with slashes/ path components,
// just prepends the string
@property (strong) NSString* baseURL; 

// Set of HTTP headers, both keys and values should be strings
@property (strong) NSDictionary* headers;

// Set of a text fragment to be appended to the query string. i.e. @"val1=a&val2=b"
@property (strong) NSString* additionalQueryString;

// Control whether NSNulls are automatically stripped out for JSON related requests
@property BOOL stripDictionaryNulls;
@property BOOL stripArrayNulls; // more dangerous, because it will change the array indexes

// Error reporting block
@property (strong) SCNetworkError error;

@end

//---------------------------------------------------------------------------------------------------------------------
// Basic network request
@interface SCNetworkRequest : NSObject

// The set of headers to be sent with the current request 
@property (readonly, strong) NSMutableDictionary* headers;

// A block to call if the current request errors out
@property (strong) SCNetworkError error;

// Create a new request 
-(id)initWithURL:(NSString*)url 
        defaults:(SCNetworkRequestDefaults*)defaults
          method:(SCNetworkRequestMethod)method
         content:(NSData*)content 
       autoStart:(BOOL)start
        response:(void (^)(NSData* data))response;

-(void)start;

@end

//---------------------------------------------------------------------------------------------------------------------
// Network request for JSON APIs
@interface SCJSONRequest : SCNetworkRequest 

// Create a new request 
-(id)initWithURL:(NSString*)url 
        defaults:(SCNetworkRequestDefaults*)defaults
          method:(SCNetworkRequestMethod)method
     contentJSON:(NSObject*)content 
       autoStart:(BOOL)start
        response:(void (^)(NSObject* data))response;

@end
//---------------------------------------------------------------------------------------------------------------------
// Simple server exposing JSON APIS
@interface SCJSONServer : NSObject 

// Persistent properties for the server are just a network defaults object
@property (strong) SCNetworkRequestDefaults* defaults;

// Make api calls
-(void)get:(NSString*)apiPath response:(void (^)(NSObject* data))responseBlock; 
-(void)put:(NSString*)apiPath content:(NSObject*)content response:(void (^)(NSObject* data))responseBlock; 
-(void)post:(NSString*)apiPath content:(NSObject*)content response:(void (^)(NSObject* data))responseBlock;
-(void)delete:(NSString*)apiPath content:(NSObject*)content response:(void (^)(NSObject* data))responseBlock;

@end

