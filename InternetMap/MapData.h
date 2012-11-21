//
//  MapData
//  InternetMap
//

@class MapDisplay;

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

@interface MapData : NSObject

-(void)loadFromFile:(NSString*)filename;
-(void)loadFromAttrFile:(NSString*)filename;
-(void)updateDisplay:(MapDisplay*)display;

@end
