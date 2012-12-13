//
//  ViewController.h
//  InternetMap
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "NodeSearchViewController.h"
#import "SCTraceroute.h"
#import "ASNRequest.h"

@interface ViewController : GLKViewController <UIPopoverControllerDelegate, NodeSearchDelegate, SCTracerouteDelegate, ASNRequestDelegate>

- (void)finishedFetchingCurrentASN:(int)asn;
- (void)failedFetchingCurrentASN:(NSString*)error;

@end
