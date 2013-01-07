//
// Created by Alexander on 23.08.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

#define UI_ORANGE_COLOR [UIColor colorWithRed:252.0/255.0 green:161.0/255.0 blue:0 alpha:1]
#define FONT_NAME_LIGHT @"ARSMaquettePro-Light"

extern void SCLogRect(CGRect rect);

@interface HelperMethods : NSObject

+ (BOOL)deviceIsiPad;
+ (BOOL)deviceIsRetina;
+ (BOOL)deviceIsOld;
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage*)imageFromView:(UIView*)view;
+ (BOOL)deviceHasInternetConnection;
+ (BOOL)isStringEmptyOrNil:(NSString*)string;

@end