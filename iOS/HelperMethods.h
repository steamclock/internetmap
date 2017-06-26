//
// Created by Alexander on 23.08.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

#define UI_WHITE_COLOR [UIColor whiteColor]
#define UI_ORANGE_COLOR [UIColor colorWithRed:252.0/255.0 green:161.0/255.0 blue:0 alpha:1]

#define UI_BLUE_COLOR [UIColor colorWithRed:68.0/255.0 green:144.0/255.0 blue:206.0/255.0 alpha:1.0]
#define UI_COLOR_DARK [UIColor colorWithRed:0.17 green:0.16 blue:0.16 alpha:1.0] // Dark grey
#define UI_COLOR_GREY_TRANSLUCENT [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:0.75] // Lighter grey

#define FONT_COLOR_GRAY [UIColor colorWithRed:0.17 green:0.16 blue:0.16 alpha:1.0]
#define FONT_COLOR_WHITE [UIColor whiteColor]

#define UI_PRIMARY_COLOR UI_BLUE_COLOR

#define FONT_NAME @"Nexa"
#define FONT_NAME_LIGHT @"NexaLight"
#define FONT_NAME_MEDIUM @"NexaBold"
#define FONT_NAME_REGULAR @"NexaLight"

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
