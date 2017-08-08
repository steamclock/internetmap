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

@interface ViewController : GLKViewController <NodeSearchDelegate, SCTracerouteUtilityDelegate, UIGestureRecognizerDelegate, WEPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, NodeInformationViewControllerDelegate>

@end
