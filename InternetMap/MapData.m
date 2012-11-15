//
//  MapData
//  InternetMap
//

#import "MapData.h"
#import "MapDisplay.h"

@interface MapData ()
@property (strong, nonatomic) NSString* filename;
@end

@implementation MapData

-(void)loadFromFile:(NSString*)filename {
    self.filename = filename;
}

-(void)updateDisplay:(MapDisplay*)display {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:self.filename encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    
    int numPoints = [[[[lines objectAtIndex:0] componentsSeparatedByString:@" "] objectAtIndex:0] intValue];
    display.numNodes = numPoints;
    
    UIColor* color = [UIColor colorWithRed:0.2 green:0.0 blue:0.2 alpha:0.2];
    
    for (int i = 0; i < numPoints; i++) {
        NSArray* pointDesc = [[lines objectAtIndex:1 + i] componentsSeparatedByString:@" "];
        DisplayNode* point = [display displayNodeAtIndex:i];
        
        point.x = log10f([[pointDesc objectAtIndex:1] floatValue]) + 2.0f;
        point.y = [[pointDesc objectAtIndex:2] floatValue];
        point.z = [[pointDesc objectAtIndex:3] floatValue];
        point.size = ([[UIScreen mainScreen] scale] == 2.00) ? 10.0f : 5.0f;
        point.color = color;
    }
    
    NSLog(@"load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

@end
