//
//  ViewController.h
//  InternetMap
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "NodeSearchViewController.h"

@interface ViewController : GLKViewController <UIPopoverControllerDelegate, NodeSearchDelegate>

- (void)finishedFetchingCurrentASN:(int)asn;
- (void)failedFetchingCurrentASN:(NSString*)error;

@end
