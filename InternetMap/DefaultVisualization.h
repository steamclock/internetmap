//
//  DefaultVisualization.h
//  InternetMap
//

#import <Foundation/Foundation.h>
#import "Visualization.h"

#define SELECTED_NODE_COLOR UIColorFromRGB(0xffa300)
#define SELECTED_CONNECTION_COLOR_BRIGHT UIColorFromRGB(0xE0E0E0)
#define SELECTED_CONNECTION_COLOR_DIM UIColorFromRGB(0x383838)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface DefaultVisualization : NSObject <Visualization>

@end
