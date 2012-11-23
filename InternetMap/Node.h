//
//  Node.h
//  InternetMap
//

#import <Foundation/Foundation.h>

enum
{
    AS_UNKNOWN,
    AS_T1,
    AS_T2,
    AS_COMP,
    AS_EDU,
    AS_IX,
    AS_NIC
};

@interface Node : NSObject

@property (strong, nonatomic) NSString* uid;
@property NSUInteger index;
@property float importance;
@property float positionX;
@property float positionY;
@property int type;

@end
