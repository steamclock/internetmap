//
//  Connection.h
//  InternetMap
//

#import <Foundation/Foundation.h>

class Node;

@interface Connection : NSObject
@property (nonatomic) NodePointer first;
@property (nonatomic) NodePointer second;

@end
