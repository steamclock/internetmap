//
//  NSArray+SCTyped.m
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

#import "NSArray+SCTyped.h"

@implementation NSArray (SCTyped)

static inline id dynamicCast(id source, Class type) {
    return [source isKindOfClass:type] ? source : nil;
}

-(id)objectAtIndex:(NSUInteger)index ofType:(Class)type {
    return index < self.count ? dynamicCast([self objectAtIndex:index], type) : nil;
}

-(NSString*)stringAtIndex:(NSUInteger)index {
    return index < self.count ? dynamicCast([self objectAtIndex:index], [NSString class]) : nil;
}

-(NSArray*)arrayAtIndex:(NSUInteger)index {
    return index < self.count ? dynamicCast([self objectAtIndex:index], [NSArray class]) : nil;
}

-(NSDictionary*)dictionaryAtIndex:(NSUInteger)index {
    return index < self.count ? dynamicCast([self objectAtIndex:index], [NSDictionary class]) : nil;
}

-(NSNumber*)numberAtIndex:(NSUInteger)index {
    return index < self.count ? dynamicCast([self objectAtIndex:index], [NSNumber class]) : nil;
}

-(int)intAtIndex:(NSUInteger)index {
    NSNumber* number = index < self.count ? dynamicCast([self objectAtIndex:index], [NSNumber class]) : nil;
    return number ? [number intValue] : 0;
}

-(float)floatAtIndex:(NSUInteger)index {
    NSNumber* number = index < self.count ? dynamicCast([self objectAtIndex:index], [NSNumber class]) : nil;
    return number ? [number floatValue] : 0.0f;
}

-(BOOL)boolAtIndex:(NSUInteger)index {
    NSNumber* number = index < self.count ? dynamicCast([self objectAtIndex:index], [NSNumber class]) : nil;
    return number ? [number boolValue] : NO;
}

@end
