//
//  NodeSearchViewController.m
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-03.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeSearchViewController.h"
#import "Node.h"

#define ASNS_AT_TOP @[@13768, @3, @15169, @714, @32934, @7847] //Peer1, MIT, google, apple, facebook, NASA

@interface NodeSearchViewController ()

@property (strong, nonatomic) UISearchDisplayController* nodeSearchDisplayController;
@property (strong, nonatomic) UISearchBar* searchBar;
@property (strong, nonatomic) NSArray* searchResults;
@property BOOL showHostLookup;
@end

@implementation NodeSearchViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Do stuff
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.contentSizeForViewInPopover = CGSizeMake(600, 300);
    self.title = @"Search Nodes";
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, 44)];
    self.searchBar.delegate = self;
    self.tableView.tableHeaderView = self.searchBar;
    
    self.nodeSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.nodeSearchDisplayController.delegate = self;
    self.nodeSearchDisplayController.searchResultsDelegate = self;
    self.nodeSearchDisplayController.searchResultsDataSource = self;


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setAllItems:(NSMutableArray *)allItems {
    _allItems = allItems;
    NSArray* arr = ASNS_AT_TOP;
    for (int i = 0; i < [arr count]; i++) {
        int asn = [arr[i] intValue];
        for (int j = 0; j < [self.allItems count]; j++) {
            Node* node = self.allItems[j];
            if ([node.asn intValue] == asn) {
                [self.allItems exchangeObjectAtIndex:i withObjectAtIndex:j];
                break;
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchResults.count + (self.showHostLookup ? 1 : 0);
    } else {
        return self.allItems.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        int row = indexPath.row;
        
        if(self.showHostLookup) {
            if(row == 0) {
                cell.textLabel.text = [NSString stringWithFormat:@"Find host '%@'", [self.searchBar.text lowercaseString] ];
                return cell;
            }
            else
            {
                row--;
            }
        }
        Node* node = self.searchResults[row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", node.asn, node.textDescription];
    } else {
        Node* node = self.allItems[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", node.asn, node.textDescription];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        int row = indexPath.row;
        
        if(self.showHostLookup) {
            if(row == 0) {
                [self.delegate selectNodeByHostLookup:[self.searchBar.text lowercaseString]];
                return;
            }
            else{
                row--;
            }
        }

        Node* node = self.searchResults[row];
        [self.delegate nodeSelected:node];
    } else {
        Node* node = self.allItems[indexPath.row];
        [self.delegate nodeSelected:node];
    }
}

#pragma mark - UISearchBar Delegate


#pragma mark - UISearchDisplayController Delegate

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
    // moo
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    self.showHostLookup = searchString.length != 0;
    [self filterContentForSearchText:searchString];
    return NO;
}

- (void)filterContentForSearchText:(NSString*)searchText
{
    self.searchResults = nil; // First clear the filtered array.
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(textDescription contains[cd] %@)", searchText];
    self.searchResults = [self.allItems filteredArrayUsingPredicate:predicate];
    
    [self.searchDisplayController.searchResultsTableView reloadData];
}

@end
