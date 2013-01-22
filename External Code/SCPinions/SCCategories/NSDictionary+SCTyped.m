//
//  NSDictionary+SCTyped.m
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

#import "NSDictionary+SCTyped.h"

@implementation NSDictionary (SCTypedDictionary)

static inline id dynamicCast(id source, Class type) {
    return [source isKindOfClass:type] ? source : nil;
}

-(id)objectForKey:(id)key ofType:(Class)type {
    return dynamicCast([self objectForKey:key], type);
}

-(NSString*)stringForKey:(id)key {
    return dynamicCast([self objectForKey:key], [NSString class]);
}

-(NSArray*)arrayForKey:(id)key {
    return dynamicCast([self objectForKey:key], [NSArray class]);    
}

-(NSDictionary*)dictionaryForKey:(id)key {
    return dynamicCast([self objectForKey:key], [NSDictionary class]);        
}

-(NSNumber*)numberForKey:(id)key {
    return dynamicCast([self objectForKey:key], [NSNumber class]);
}

-(int)intForKey:(id)key {
    NSNumber* number = dynamicCast([self objectForKey:key], [NSNumber class]);
    return number ? [number intValue] : 0;
}

-(float)floatForKey:(id)key {
    NSNumber* number = dynamicCast([self objectForKey:key], [NSNumber class]);
    return number ? [number floatValue] : 0.0f;
}

-(BOOL)boolForKey:(id)key {
    NSNumber* number = dynamicCast([self objectForKey:key], [NSNumber class]);
    return number ? [number boolValue] : NO;
}

@end
