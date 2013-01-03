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

@property (strong, nonatomic) NSString* asn;
@property NSUInteger index;
@property float importance;
@property float positionX;
@property float positionY;
@property int type;

@property (strong, nonatomic) NSString* typeString;

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* textDescription;
@property (strong, nonatomic) NSString* dateRegistered;
@property (strong, nonatomic) NSString* address;
@property (strong, nonatomic) NSString* city;
@property (strong, nonatomic) NSString* state;
@property (strong, nonatomic) NSString* postalCode;
@property (strong, nonatomic) NSString* country;

@property (strong, nonatomic) NSMutableArray* connections;

@end
