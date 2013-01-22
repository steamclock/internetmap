//
//  NSObject+AssociatedObjects.m
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

#import "NSObject+SCAssociatedObjects.h"
#import <objc/runtime.h>

@implementation NSObject (SCAssociatedObjects)

- (void)setAssociatedObject:(id)value forKey:(NSString *)key
{
    
	objc_setAssociatedObject(self, (void*)[key hash], value, OBJC_ASSOCIATION_RETAIN);
}

- (void)setWeaklyAssociatedObject:(id)value forKey:(NSString *)key
{
	objc_setAssociatedObject(self, (void*)[key hash], value, OBJC_ASSOCIATION_ASSIGN);
}

- (void)clearAssociatedObjectForKey:(NSString*)key {
    objc_setAssociatedObject(self, (void*)[key hash], nil, OBJC_ASSOCIATION_ASSIGN);
}

- (id)associatedObjectForKey:(NSString *)key
{
	return objc_getAssociatedObject(self, (void*)[key hash]);
}

@end
