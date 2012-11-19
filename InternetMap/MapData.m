//
//  MapData
//  InternetMap
//

#import "MapData.h"
#import "MapDisplay.h"
#import "Node.h"

@interface MapData ()
@property (strong, nonatomic) NSMutableArray* nodes;
@property (strong, nonatomic) NSMutableDictionary* nodesByUid;
@property (strong, nonatomic) NSMutableArray* connections;
@property (strong, nonatomic) NSString* filename;
@end

@implementation MapData

-(void)loadFromFile:(NSString*)filename {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    
    NSArray* header = [[lines objectAtIndex:0] componentsSeparatedByString:@"  "];
    int numNodes = [[header objectAtIndex:0] intValue];
    int numConnections = [[header objectAtIndex:1] intValue];
    
    self.nodes = [[NSMutableArray alloc] initWithCapacity:numNodes];
    self.nodesByUid = [[NSMutableDictionary alloc] initWithCapacity:numNodes];

    for (int i = 0; i < numNodes; i++) {
        NSArray* nodeDesc = [[lines objectAtIndex:1 + i] componentsSeparatedByString:@" "];
        
        Node* node = [Node new];
        node.uid = [nodeDesc objectAtIndex:0];
        node.index = i;
        node.importance = [[nodeDesc objectAtIndex:1] floatValue];
        node.positionX = [[nodeDesc objectAtIndex:2] floatValue];
        node.positionY = [[nodeDesc objectAtIndex:3] floatValue];
        
        [self.nodes addObject:node];
        [self.nodesByUid setObject:node forKey:node.uid];
    }
    
    self.connections = [NSMutableArray new];
    
    for (int i = 0; i < numConnections; i++) {
        NSArray* connectionDesc = [[lines objectAtIndex:1 + numNodes + i] componentsSeparatedByString:@" "];
        
        Node* first = [self.nodesByUid valueForKey:[connectionDesc objectAtIndex:0]];
        Node* second = [self.nodesByUid valueForKey:[connectionDesc objectAtIndex:1]];
        
        if((first.importance > 0.02) && (second.importance > 0.01)) {
            [self.connections addObject:[NSNumber numberWithInt:first.index]];
            [self.connections addObject:[NSNumber numberWithInt:second.index]];
        }
    }
    
    NSLog(@"load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

-(void)updateDisplay:(MapDisplay*)display {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    display.numNodes = self.nodes.count;
    
    UIColor* color = [UIColor colorWithRed:0.0 green:0.2 blue:0.2 alpha:0.2];
    
    [self.nodes enumerateObjectsUsingBlock:^(Node* obj, NSUInteger idx, BOOL *stop) {
        DisplayNode* point = [display displayNodeAtIndex:idx];
        
        point.x = log10f(obj.importance) + 2.0f;
        point.y = obj.positionX;
        point.z = obj.positionY;
        point.size = ([[UIScreen mainScreen] scale] == 2.00) ? 10.0f : 5.0f;
        point.color = color;
    }];
    
    [display setLineIndices:self.connections];
    
    NSLog(@"update display : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

@end
