//
//  Node.h
//  InternetMap
//

#import <Foundation/Foundation.h>

@interface Node : NSObject

@property (strong, nonatomic) NSString* uid;
@property int index;
@property float importance;
@property float positionX;
@property float positionY;
@property int type;

@end
