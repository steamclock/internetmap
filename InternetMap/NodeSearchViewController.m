//
//  NodeSearchViewController.m
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-03.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeSearchViewController.h"
#import "NodeWrapper.h"

#define ASNS_AT_TOP @[@13768, @3, @15169, @714, @32934, @7847] //Peer1, MIT, google, apple, facebook, NASA

@interface NodeSearchViewController ()

@property (strong, nonatomic) UITextField* textField;
@property (strong, nonatomic) NSArray* searchResults;
@property BOOL showHostLookup;
@property BOOL isSearching;
@end

@implementation NodeSearchViewController

- (id)init
{
    self = [super init];
    if (self) {
        if ([HelperMethods deviceIsiPad]) {
            self.contentSizeForViewInPopover = CGSizeMake(400, 290);
        }else {
            CGSize screenSize = [[UIScreen mainScreen] bounds].size;
            self.contentSizeForViewInPopover = CGSizeMake(screenSize.width, screenSize.height-20-55-216); //status bar height, buttons, keyboard
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    
    self.title = @"Search Nodes";
    
    UIView* orangeBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, 44)];
    orangeBackground.backgroundColor = UI_ORANGE_COLOR;
    [self.view addSubview:orangeBackground];
    
    UIImage* doneImage = [UIImage imageNamed:@"x-icon"];
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 5, self.contentSizeForViewInPopover.width-doneImage.size.width-22, 44)];
    [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.textField.backgroundColor = [UIColor clearColor];
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.textColor = [UIColor blackColor];
    self.textField.delegate = self;
    self.textField.font = [UIFont fontWithName:FONT_NAME_LIGHT size:24];
    [self.view addSubview:self.textField];
    
    UIButton* doneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.textField.x+self.textField.width, 12, doneImage.size.width, doneImage.size.height)];
    [doneButton setImage:doneImage forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneButton];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(self.textField.x-10, self.textField.y+self.textField.height, self.contentSizeForViewInPopover.width-25, self.contentSizeForViewInPopover.height-self.textField.height-20) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    [self.textField becomeFirstResponder];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setAllItems:(NSMutableArray *)allItems {
    _allItems = [allItems mutableCopy];
    NSArray* arr = ASNS_AT_TOP;
    for (int i = 0; i < [arr count]; i++) {
        int asn = [arr[i] intValue];
        for (int j = 0; j < [self.allItems count]; j++) {
            NodeWrapper* node = self.allItems[j];
            if ([node.asn intValue] == asn) {
                [self.allItems exchangeObjectAtIndex:i withObjectAtIndex:j];
                break;
            }
        }
    }
}

#pragma mark - UITextField action method
- (void)textFieldDidChange:(UITextField*)sender {
    [self filterContentForSearchText:sender.text];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.isSearching = YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.isSearching = NO;
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isSearching && self.textField.text != nil && ![self.textField.text isEqualToString:@""]) {
        return (self.searchResults.count ? self.searchResults.count : 1) + (self.showHostLookup ? 1 : 0);
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
        cell.textLabel.textColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0];
        cell.textLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:24];
        UIView* seperator = [[UIView alloc] initWithFrame:CGRectMake(10, 43, tableView.width-10, 1)];
        seperator.backgroundColor = [UIColor grayColor];
        [cell.contentView addSubview:seperator];
    }
    
    if (self.isSearching && self.textField.text != nil && ![self.textField.text isEqualToString:@""]) {
        int row = indexPath.row;
        
        if(self.showHostLookup) {
            if(row == 0) {
                
                cell.textLabel.text = [NSString stringWithFormat:@"Find host '%@'", [self.textField.text lowercaseString] ];
                return cell;
            }
            else
            {
                row--;
            }
        }
        
        if (row >= self.searchResults.count) {
            cell.textLabel.text = @"No results found";
        }else {
            NodeWrapper* node = self.searchResults[row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", node.asn, node.textDescription];
        }
    } else {
        NodeWrapper* node = self.allItems[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", node.asn, node.textDescription];
    }
    
    return cell;
}

- (void)done{
    [self.delegate nodeSearchDelegateDone];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (self.isSearching && self.textField.text != nil && ![self.textField.text isEqualToString:@""]) {
        int row = indexPath.row;
        
        if(self.showHostLookup) {
            if(row == 0) {
                [self.delegate selectNodeByHostLookup:[self.textField.text lowercaseString]];
                return;
            }
            else{
                row--;
            }
        }

        NodeWrapper* node = self.searchResults[row];
        [self.delegate nodeSelected:node];
    } else {
        NodeWrapper* node = self.allItems[indexPath.row];
        [self.delegate nodeSelected:node];
    }
}


- (void)filterContentForSearchText:(NSString*)searchText
{
    self.showHostLookup = searchText.length != 0;
    self.searchResults = nil; // First clear the filtered array.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(textDescription contains[cd] %@) OR (asn contains[cd] %@)", searchText, searchText];
    self.searchResults = [self.allItems filteredArrayUsingPredicate:predicate];
    
    [self.tableView reloadData];
}

@end
