//
//  MapData
//  InternetMap
//

#import "MapData.h"
#import "Node.hpp"
#import "Lines.hpp"
#import "Connection.hpp"
#import "IndexBox.h"

@interface MapData ()
@end

@implementation MapData

-(NodePointer)nodeAtIndex:(NSUInteger)index {
    return self.nodes.at(index);
}

-(void)loadFromFile:(NSString*)filename {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *fileContents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    
    NSArray* header = [[lines objectAtIndex:0] componentsSeparatedByString:@"  "];
    int numNodes = [[header objectAtIndex:0] intValue];
    int numConnections = [[header objectAtIndex:1] intValue];

    self.testNodes = std::shared_ptr<std::vector<NodePointer>>(new std::vector<NodePointer>());
    for (int i = 0; i < numNodes; i++) {
        NSArray* nodeDesc = [[lines objectAtIndex:1 + i] componentsSeparatedByString:@" "];
        
        NodePointer node = NodePointer(new Node());
        node->asn = std::string([[nodeDesc objectAtIndex:0] UTF8String]);
        node->index = i;
        node->importance = [[nodeDesc objectAtIndex:1] floatValue];
        node->positionX = [[nodeDesc objectAtIndex:2] floatValue];
        node->positionY = [[nodeDesc objectAtIndex:3] floatValue];
        node->type = AS_UNKNOWN;
        
        self.testNodes->push_back(node);
        [self nodes].push_back(node);
        self.nodesByAsn.insert(std::make_pair(node->asn, node));
    }
    
    for (int i = 0; i < numConnections; i++) {
        NSArray* connectionDesc = [[lines objectAtIndex:1 + numNodes + i] componentsSeparatedByString:@" "];
        
        ConnectionPointer connection = ConnectionPointer(new Connection());
        connection->first = self.nodesByAsn[std::string([[connectionDesc objectAtIndex:0] UTF8String])];
        connection->second = self.nodesByAsn[std::string([[connectionDesc objectAtIndex:1] UTF8String])];
        connection->first->connections.push_back(connection);
        connection->second->connections.push_back(connection);
        self.connections.push_back(connection);
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
                box.minCorner = GLKVector3Make(x, y, z);
                box.maxCorner = GLKVector3Make(x+boxSizeXWithoutOverlap, y+boxSizeYWithoutOverlap, z+boxSizeZWithoutOverlap);
                [self.boxesForNodes addObject:box];
            }
        }
    }
    
    for (int i = 0; i < self.nodes.size(); i++) {
        NodePointer ptrNode = self.nodes.at(i);
        GLKVector3 pos = [self.visualization nodePosition:ptrNode];
        IndexBox* box = [self indexBoxForPoint:pos];
        [box.indices addIndex:i];
    }
}

- (IndexBox*)indexBoxForPoint:(GLKVector3)point {
    GLKVector3 pos = point;
    
    int posX = (int)fabsf((pos.x + fabsf(IndexBoxMinX))/boxSizeXWithoutOverlap);
    int posY = (int)fabsf((pos.y + fabsf(IndexBoxMinY))/boxSizeYWithoutOverlap);
    int posZ = (int)fabsf((pos.z + fabsf(IndexBoxMinZ))/boxSizeZWithoutOverlap);
    int posInArray = posX + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*posY + (fabsf(IndexBoxMinX) + fabsf(IndexBoxMaxX))/boxSizeXWithoutOverlap*(fabsf(IndexBoxMinY)+fabsf(IndexBoxMaxY))/boxSizeYWithoutOverlap*posZ;
    
    return [self.boxesForNodes objectAtIndex:posInArray];

}

- (void)addNodesToBox:(IndexBox*)box {
    for (int i = 0; i < self.nodes.size(); i++) {
        NodePointer node = self.nodes.at(i);
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
        
        NodePointer node = self.nodesByAsn[std::string([[asDesc objectAtIndex:0] UTF8String])];
        if(node){
            node->type = [[asTypeDict objectForKey: [asDesc objectAtIndex:7]] intValue];
            node->typeString = std::string([[asDesc objectAtIndex:7] UTF8String]);
            node->textDescription = std::string([[asDesc objectAtIndex:1] UTF8String]);
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
        NodePointer node = self.nodesByAsn[std::string([key UTF8String])];
        if(node){
            NSArray *as = [jsonObject objectForKey:key];
            node->name = std::string([[as objectAtIndex:1] UTF8String]);
            node->textDescription = std::string([[as objectAtIndex:5] UTF8String]);
            node->dateRegistered = std::string([[as objectAtIndex:3] UTF8String]);
            node->address = std::string([[as objectAtIndex:7] UTF8String]);
            node->city = std::string([[as objectAtIndex:8] UTF8String]);
            node->state = std::string([[as objectAtIndex:9] UTF8String]);
            node->postalCode = std::string([[as objectAtIndex:10] UTF8String]);
            node->country = std::string([[as objectAtIndex:11] UTF8String]);
        }
    }

    NSLog(@"asinfo load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}


-(void)updateDisplay:(MapDisplay*)display {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    [self.visualization resetDisplay:display forNodes:self.nodes];
    [self.visualization updateLineDisplay:display forConnections:self.connections];
        
    NSLog(@"update display : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

@end
