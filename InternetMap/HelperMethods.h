//
// Created by Alexander on 23.08.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

extern void SCLogRect(CGRect rect);

@interface HelperMethods : NSObject

+ (BOOL)deviceIsiPad;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage*)imageFromView:(UIView*)view;

@end