//
//  NodeSearchViewController.h
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-03.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NodeWrapper;

@protocol NodeSearchDelegate

-(void)nodeSearchDelegateDone;
-(void)nodeSelected:(NodeWrapper*)node;
-(void)selectNodeByHostLookup:(NSString*)host;

@end

@interface NodeSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) id delegate;
@property (nonatomic, copy) NSMutableArray* allItems;
@property (strong, nonatomic) UITableView* tableView;

@end
