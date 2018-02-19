//
//  ViewController.h
//  InternetMap
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "NodeSearchViewController.h"
#import "SCTracerouteUtility.h"
#import "WEPopoverController.h"
#import "NodeInformationViewController.h"

typedef NS_ENUM(NSInteger, ARMode) {
    ARModeDisabled,
    ARModeSearching,
    ARModePlacing,
    ARModeViewing
};

@interface ViewController : GLKViewController <NodeSearchDelegate, SCTracerouteUtilityDelegate, UIGestureRecognizerDelegate, WEPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, NodeInformationViewControllerDelegate>

- (void)moreAboutCogeco;
- (void)overrideCamera:(matrix_float4x4)transform projection:(matrix_float4x4)projection modelPos:(GLKVector3)modelPos;
- (void)setARMode:(ARMode)mode;
@end
