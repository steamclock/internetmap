//
// Created by Alexander on 23.08.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HelperMethods.h"
#import <QuartzCore/QuartzCore.h>
#import "Reachability.h"
#import <sys/types.h>
#import <sys/sysctl.h>

void SCLogRect(CGRect rect) {

    //NSLog(@"%@", NSStringFromCGRect(rect));

}

@implementation HelperMethods

+(BOOL)deviceIsiPad{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (BOOL)deviceIsRetina {
    return [[UIScreen mainScreen] scale] == 2.00;
}

+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (BOOL)deviceIsOld {
    NSString *systemName = [[self platform] componentsSeparatedByString:@","][0];
    
    if([systemName isEqualToString:@"iPad1"]) {
        return YES;
    }
    
    if([systemName isEqualToString:@"iPhone2"]) {
        return YES;
    }
    
    if([systemName isEqualToString:@"iPod3"]) {
        return YES;
    }
    
    return NO;
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size{
    
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage*)imageFromView:(UIView*)view {
    //0.0 scale means UIScreen scale, which takes retina/non retina into account
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

+(BOOL)deviceHasInternetConnection {

    return [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != kNotReachable;

}

+ (BOOL)isStringEmptyOrNil:(NSString*)string {
    return !string || [string isEqualToString:@""];
}


@end