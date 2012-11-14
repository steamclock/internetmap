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
    NSString *fileContents = [NSString stringWithContentsOfFile:self.filename encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    
    int numPoints = [[[[lines objectAtIndex:0] componentsSeparatedByString:@" "] objectAtIndex:0] intValue];
    
    DisplayNode* points = malloc(numPoints * sizeof(DisplayNode));
    
    for (int i = 0; i < numPoints; i++) {
        NSArray* pointDesc = [[lines objectAtIndex:1 + i] componentsSeparatedByString:@" "];
        
        points[i].x = log10f([[pointDesc objectAtIndex:1] floatValue]) + 2.0f;
        points[i].y = [[pointDesc objectAtIndex:2] floatValue];
        points[i].z = [[pointDesc objectAtIndex:3] floatValue];
        points[i].size = ([[UIScreen mainScreen] scale] == 2.00) ? 10.0f : 5.0f;
    }
    
    [display setNodesToDisplay:points count:numPoints];
    
    free(points);
}

@end
