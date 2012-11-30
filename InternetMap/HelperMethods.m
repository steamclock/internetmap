//
// Created by Alexander on 23.08.12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "HelperMethods.h"
#import <QuartzCore/QuartzCore.h>

void SCLogRect(CGRect rect) {

    NSLog(@"%@", NSStringFromCGRect(rect));

}

@implementation HelperMethods

+(BOOL)deviceIsiPad{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
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

@end