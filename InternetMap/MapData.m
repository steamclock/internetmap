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
        node.type = AS_UNKNOWN;
        
        [self.nodes addObject:node];
        [self.nodesByUid setObject:node forKey:node.uid];
    }
    
    self.connections = [NSMutableArray new];
    
    for (int i = 0; i < numConnections; i++) {
        NSArray* connectionDesc = [[lines objectAtIndex:1 + numNodes + i] componentsSeparatedByString:@" "];
        
        Node* first = [self.nodesByUid valueForKey:[connectionDesc objectAtIndex:0]];
        Node* second = [self.nodesByUid valueForKey:[connectionDesc objectAtIndex:1]];
        
        if((first.importance > 0.01) && (second.importance > 0.01)) {
            [self.connections addObject:[NSNumber numberWithInt:first.index]];
            [self.connections addObject:[NSNumber numberWithInt:second.index]];
        }
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
        
        Node* node = [self.nodesByUid objectForKey:[asDesc objectAtIndex:0]];
        if(node){
            node.type = [[asTypeDict objectForKey: [asDesc objectAtIndex:7]] intValue];
        }
//        NSLog(@"%@",[asDesc objectAtIndex:0]);
//        NSLog(@"%@", node);
    }
    
    
    NSLog(@"attr load : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}


#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

-(void)updateDisplay:(MapDisplay*)display {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    display.numNodes = self.nodes.count;
    
//    UIColor* nodeColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    
//    UIColor* t1Color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
//    UIColor* t2Color = [UIColor colorWithRed:1.0 green:0.7 blue:1.0 alpha:1.0];
//    UIColor* compColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
//    UIColor* eduColor = [UIColor colorWithRed:1.0 green:0.7 blue:0.7 alpha:1.0];
//    UIColor* ixColor = [UIColor colorWithRed:0.7 green:1.0 blue:0.7 alpha:1.0];
//    UIColor* nicColor = [UIColor colorWithRed:0.7 green:0.7 blue:1.0 alpha:1.0];
//    UIColor* unknownColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];

    UIColor* t1Color = UIColorFromRGB(0x36a3e6);
    UIColor* t2Color = UIColorFromRGB(0x2246a7);
    UIColor* unknownColor = UIColorFromRGB(0x8e44bd);
    UIColor* compColor = UIColorFromRGB(0x4490ce);
    UIColor* eduColor = UIColorFromRGB(0xecb7fd);
    UIColor* ixColor = UIColorFromRGB(0xb7fddc);
    UIColor* nicColor = UIColorFromRGB(0xb0a2d3);
    
    [self.nodes enumerateObjectsUsingBlock:^(Node* obj, NSUInteger idx, BOOL *stop) {
        DisplayNode* point = [display displayNodeAtIndex:idx];
        
        point.x = log10f(obj.importance) + 2.0f;
        point.y = obj.positionX;
        point.z = obj.positionY;
        float size = 2.0 + 400*powf(obj.importance, .75);
//        float size = 2.0 + 100*sqrtf(obj.importance);
//        float size = 2.0 + 1000*obj.importance;
        point.size = ([[UIScreen mainScreen] scale] == 2.00) ? 2.0*size : 1.0*size;
        
        switch(obj.type) {
            case AS_T1:
                point.color = t1Color;
                break;
            case AS_T2:
                point.color = t2Color;
                break;
            case AS_COMP:
                point.color = compColor;
                break;
            case AS_EDU:
                point.color = eduColor;
                break;
            case AS_IX:
                point.color = ixColor;
                break;
            case AS_NIC:
                point.color = nicColor;
                break;
            default:
                point.color = unknownColor;
                break;
        }

        float lineImportance = MAX(obj.importance - 0.01f, 0.0f) * 0.5f;
        UIColor* lineColor = [UIColor colorWithRed:lineImportance green:lineImportance blue:lineImportance alpha:1.0];
        point.lineColor = lineColor;
    }];
    
    [display setLineIndices:self.connections];
    
    NSLog(@"update display : %.2fms", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
}

@end
