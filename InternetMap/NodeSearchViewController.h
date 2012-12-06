//
//  NodeSearchViewController.h
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-03.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Node;

@protocol NodeSearchDelegate

-(void)nodeSelected:(Node*)node;

@end

@interface NodeSearchViewController : UITableViewController <UISearchDisplayDelegate, UISearchBarDelegate>

@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) NSArray* allItems;

@end
