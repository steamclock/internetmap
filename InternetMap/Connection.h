//
//  Connection.h
//  InternetMap
//

#import <Foundation/Foundation.h>

@class Node;

@interface Connection : NSObject
@property (strong, nonatomic) Node* first;
@property (strong, nonatomic) Node* second;
@end
