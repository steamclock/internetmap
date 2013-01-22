//
//  UIColor+SCHex.m
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

#import "UIColor+SCHex.h"

static NSUInteger integerFromHexString(NSString *string) {
	NSUInteger result = 0;
	sscanf([string UTF8String], "%x", &result);
	return result;
}

@implementation UIColor (SCHex)

// Adapted from https://github.com/Cocoanetics/NSAttributedString-Additions-for-HTML && SSToolkit

+ (UIColor *)colorWithHex:(NSString *)hex {
// Remove `#`
if ([[hex substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"#"]) {
    hex = [hex substringFromIndex:1];
}

// Invalid if not 3, or 6 characters
NSUInteger length = [hex length];
if (length != 3 && length != 6) {
    return nil;
}

NSUInteger digits = length / 3;
CGFloat maxValue = (digits == 1) ? 15.0f : 255.0f;

CGFloat red = integerFromHexString([hex substringWithRange:NSMakeRange(0, digits)]) / maxValue;
CGFloat green = integerFromHexString([hex substringWithRange:NSMakeRange(digits, digits)]) / maxValue;
CGFloat blue = integerFromHexString([hex substringWithRange:NSMakeRange(2 * digits, digits)]) / maxValue;

return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

@end
