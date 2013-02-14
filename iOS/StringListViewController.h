//
//  VisualizationsTableViewController.h
//  InternetMap
//
//  Created by Angelina Fabbro on 12-11-30.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapControllerWrapper;

@interface StringListViewController : UITableViewController

@property (strong) void (^selectedBlock)(int index);
@property (nonatomic, strong) NSArray* items;
-(void) setHighlightCurrentRow:(BOOL)highlight;

@end
