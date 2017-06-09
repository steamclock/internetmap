//
//  VisualizationsTableViewController.m
//  InternetMap
//
//  Created by Angelina Fabbro on 12-11-30.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "StringListViewController.h"
#import "MapControllerWrapper.h"

@interface StringListViewController ()

@property (nonatomic, assign) NSInteger selectedRow;
@property (nonatomic, assign) BOOL highlightSelectedRow;

@end

@implementation StringListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.preferredContentSize = CGSizeMake(320, 150);
    }
    return self;
}

-(void) setHighlightCurrentRow:(BOOL)highlight {
    self.highlightSelectedRow = highlight;
    if (!highlight) {
        self.selectedRow = -1; //invalid row
    }
}

-(void)setItems:(NSArray *)items {
    _items = items;
    //update size
    int itemHeight = 44; //according to the internet
    NSInteger totalHeight = items.count * itemHeight;
    self.preferredContentSize = CGSizeMake(320, totalHeight);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

#define DIVIDER_TAG 2

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:24];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.selectedBackgroundView = [[UIView alloc] init];
    }

    UIView* divider = [cell.contentView viewWithTag:DIVIDER_TAG];
    if (!divider) {
        divider = [[UIView alloc] initWithFrame:CGRectMake(0, 43, self.tableView.width, 1)];
        divider.backgroundColor = [UIColor darkGrayColor];
        divider.tag = DIVIDER_TAG;
        [cell.contentView addSubview:divider];
    }
    
    if(indexPath.row == (self.items.count - 1)) {
        divider.backgroundColor = [UIColor blackColor];
    }
    else {
        divider.backgroundColor = [UIColor darkGrayColor];
    }
    
    if (indexPath.row == self.selectedRow) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.highlightedTextColor = FONT_COLOR_GRAY;
        [divider removeFromSuperview];
    }else {
        cell.textLabel.textColor = UI_WHITE_COLOR;
        cell.textLabel.highlightedTextColor = UI_ORANGE_COLOR;
        [cell.contentView addSubview:divider];
    }
    
    if (indexPath.row == self.selectedRow-1) {
        [divider removeFromSuperview];
    }
    
    
    cell.textLabel.text = [self.items objectAtIndex:indexPath.row];



    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.selectedRow) {
        cell.backgroundColor = UI_ORANGE_COLOR;
    }else {
        cell.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.highlightSelectedRow) {
        self.selectedRow = indexPath.row;
    }
    [self.tableView reloadData];
    if(self.selectedBlock) {
        self.selectedBlock((int)indexPath.row);
    }
}

@end
