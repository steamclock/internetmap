//
//  ViewController.h
//  InternetMap
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "NodeSearchViewController.h"
#import "SCTraceroute.h"
#import "WEPopoverController.h"
#import "Camera.h"

@interface ViewController : GLKViewController <NodeSearchDelegate, SCTracerouteDelegate, UIGestureRecognizerDelegate, WEPopoverControllerDelegate>


@end
