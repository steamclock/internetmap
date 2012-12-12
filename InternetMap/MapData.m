//
//  MapData
//  InternetMap
//

#import "MapData.h"
#import "MapDisplay.h"
#import "Node.h"
#import "Lines.h"
#import "Connection.h"
#import "IndexBox.h"

@interface MapData ()
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
    
    [self createNodeBoxes];
    
    NSLog(@"load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

- (void)createNodeBoxes {
    
    self.boxesForNodes = [NSMutableArray array];
    
    for (int k = 0; k < numberOfCellsZ; k++) {
        float z = IndexBoxMinZ + boxSizeZWithoutOverlap*k;
        for (int j = 0; j < numberOfCellsY; j++) {
            float y = IndexBoxMinY + boxSizeYWithoutOverlap*j;
            for(int i = 0; i < numberOfCellsX; i++) {
                float x = IndexBoxMinX + boxSizeXWithoutOverlap*i;
                IndexBox* box = [[IndexBox alloc] init];
                box.center = GLKVector3Make(x+boxSizeXWithoutOverlap/2, y+boxSizeYWithoutOverlap/2, z+boxSizeZWithoutOverlap/2);
                
                [self.boxesForNodes addObject:box];
            }
        }
    }
    
    for (int i = 0; i < [self.nodes count]; i++) {
        Node* node = [self.nodes objectAtIndex:i];
        GLKVector3 pos = [self.visualization nodePosition:node];
        IndexBox* box = [self indexBoxForPoint:pos];
        [box.indices addIndex:i];
    }
}

- (IndexBox*)indexBoxForPoint:(GLKVector3)point {
    GLKVector3 pos = point;
    
    //assumes all boxes have the same size
    float x = pos.x;
    if (x >= 0) {
        x += fabsf(IndexBoxMinX);
    }
    
    float y = pos.y;
    if (y >= 0) {
        y += fabsf(IndexBoxMinY);
    }
    
    float z = pos.z;
    if (z >= 0) {
        z += fabsf(IndexBoxMinZ);
    }
    
    int posX = (int)fabsf(x/boxSizeXWithoutOverlap);
    int posY = (int)fabsf(y/boxSizeYWithoutOverlap);
    int posZ = (int)fabsf(z/boxSizeZWithoutOverlap);
    int posInArray = posX + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*posY + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*(fabsf(IndexBoxMinY)+fabsf(IndexBoxMaxY))/boxSizeYWithoutOverlap*posZ;
    
    return [self.boxesForNodes objectAtIndex:posInArray];

}

- (void)addNodesToBox:(IndexBox*)box {
    for (int i = 0; i < [self.nodes count]; i++) {
        Node* node = [self.nodes objectAtIndex:i];
        GLKVector3 pos = [self.visualization nodePosition:node];
        if ([box isPointInside:pos]) {
            [box.indices addIndex:i];
        }
    }
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


-(void)loadAsInfo:(NSString*)filename {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
    NSError *parseError = nil;
    NSData* data = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
    
//    NSLog(@"%d", [jsonObject count]);
    for(id key in jsonObject)
    {
        Node* node = [self.nodesByAsn objectForKey:key];
        if(node){
            NSArray *as = [jsonObject objectForKey:key];
            node.name = [as objectAtIndex:1];
            node.textDescription = [as objectAtIndex:5];
            node.dateRegistered = [as objectAtIndex:3];
            node.address = [as objectAtIndex:7];
            node.city = [as objectAtIndex:8];
            node.state = [as objectAtIndex:9];
            node.postalCode = [as objectAtIndex:10];
            node.country = [as objectAtIndex:11];
        }
    }

    NSLog(@"asinfo load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}


-(void)updateDisplay:(MapDisplay*)display {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    display.numNodes = self.nodes.count;
    [self.visualization updateDisplay:display forNodes:self.nodes];
    [self.visualization updateLineDisplay:display forConnections:self.connections];
        
    NSLog(@"update display : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

@end
