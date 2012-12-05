//
//  NodeSearchViewController.m
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-03.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeSearchViewController.h"
#import "Node.h"

@interface NodeSearchViewController ()

@property (strong, nonatomic) UISearchDisplayController* nodeSearchDisplayController;
@property (strong, nonatomic) UISearchBar* searchBar;
@property (strong, nonatomic) NSMutableArray* searchResults;

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
    
    
    self.contentSizeForViewInPopover = CGSizeMake(320, 300);
    self.title = @"Search Nodes";
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.tableView.tableHeaderView = self.searchBar;
    
    self.nodeSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    self.nodeSearchDisplayController.delegate = self;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchResults.count;
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
        //
    } else {
        //
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        // search
    } else {
        //normal
    }
}

#pragma mark - UISearchBar Delegate

#pragma mark - UISearchDisplayController Delegate

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller{
    // moo
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    return YES;
}
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [self.searchResults removeAllObjects]; // First clear the filtered array.
    for (Node *node in self.allItems)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF contains[cd] %@)", searchText];
        [node.textDescription compare:searchText options:NSCaseInsensitiveSearch];
        
        BOOL resultName = [predicate evaluateWithObject:node.textDescription];
        
//        if([scope isEqualToString:@&quot;Product ID&quot;] && resultID)
//        {
//            [self.filteredData addObject:product];
//        }
//        if([scope isEqualToString:@"Product Name"] && resultName)
//        {
//            [self.filteredData addObject:product];
//        }
//        if([scope isEqualToString:@"Any"] && (resultID || resultName))
//        {
//            [self.filteredData addObject:product];
//        }
    }
}

@end
