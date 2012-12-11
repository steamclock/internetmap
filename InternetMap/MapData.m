//
//  MapData
//  InternetMap
//

#import "MapData.h"
#import "MapDisplay.h"
#import "Node.h"
#import "Lines.h"
#import "Connection.h"

@interface MapData ()
@property (strong, nonatomic) NSMutableDictionary* nodesByAsn;
@end

@implementation MapData

-(Node*)nodeAtIndex:(NSUInteger)index {
    return [self.nodes objectAtIndex:index];
}

-(void)loadFromFile:(NSString*)filename {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    
    NSArray* header = [[lines objectAtIndex:0] componentsSeparatedByString:@"  "];
    int numNodes = [[header objectAtIndex:0] intValue];
    int numConnections = [[header objectAtIndex:1] intValue];
    
    self.nodes = [[NSMutableArray alloc] initWithCapacity:numNodes];
    self.nodesByAsn = [[NSMutableDictionary alloc] initWithCapacity:numNodes];

    for (int i = 0; i < numNodes; i++) {
        NSArray* nodeDesc = [[lines objectAtIndex:1 + i] componentsSeparatedByString:@" "];
        
        Node* node = [Node new];
        node.asn = [nodeDesc objectAtIndex:0];
        node.index = i;
        node.importance = [[nodeDesc objectAtIndex:1] floatValue];
        node.positionX = [[nodeDesc objectAtIndex:2] floatValue];
        node.positionY = [[nodeDesc objectAtIndex:3] floatValue];
        node.type = AS_UNKNOWN;
        
        [self.nodes addObject:node];
        [self.nodesByAsn setObject:node forKey:node.asn];
    }
    
    self.connections = [NSMutableArray new];
    
    for (int i = 0; i < numConnections; i++) {
        NSArray* connectionDesc = [[lines objectAtIndex:1 + numNodes + i] componentsSeparatedByString:@" "];
        
        Connection* connection = [Connection new];
        connection.first = [self.nodesByAsn valueForKey:[connectionDesc objectAtIndex:0]];
        connection.second = [self.nodesByAsn valueForKey:[connectionDesc objectAtIndex:1]];
        [self.connections addObject:connection];
    }
    
    NSLog(@"load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}




-(void)loadFromAttrFile:(NSString*)filename {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    NSDictionary *asTypeDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:AS_UNKNOWN], @"abstained",
                                [NSNumber numberWithInt:AS_T1], @"t1",
                                [NSNumber numberWithInt:AS_T2], @"t2",
                                [NSNumber numberWithInt:AS_COMP], @"comp",
                                [NSNumber numberWithInt:AS_EDU], @"edu",
                                [NSNumber numberWithInt:AS_IX], @"ix",
                                [NSNumber numberWithInt:AS_NIC], @"nic",
                                nil];

    NSString *fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];

    for(NSString *line in lines) {
        NSArray* asDesc = [line componentsSeparatedByString:@"\t"];
        
        Node* node = [self.nodesByAsn objectForKey:[asDesc objectAtIndex:0]];
        if(node){
            node.type = [[asTypeDict objectForKey: [asDesc objectAtIndex:7]] intValue];
            node.typeString = [asDesc objectAtIndex:7];
            node.textDescription = [asDesc objectAtIndex:1];
        }
    }
    
    
    NSLog(@"attr load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}


-(void)updateDisplay:(MapDisplay*)display {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    display.numNodes = self.nodes.count;
    [self.visualization updateDisplay:display forNodes:self.nodes];
    [self.visualization updateLineDisplay:display forConnections:self.connections];
        
    NSLog(@"update display : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

@end
