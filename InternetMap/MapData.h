//
//  MapData
//  InternetMap
//

@class MapDisplay;

@interface MapData : NSObject

-(void)loadFromFile:(NSString*)filename;
-(void)updateDisplay:(MapDisplay*)display;

@end
