//
//  NodeSearchViewController.m
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-03.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeSearchViewController.h"
#import "NodeWrapper.h"
#import "SCDispatchQueue.h"

@interface NodeSearchViewController ()

@property (strong, nonatomic) UITextField* textField;
@property (strong, nonatomic) NSArray* searchResults;
@property BOOL showHostLookup;

@property int activeSearchID;

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
    self.textField.returnKeyType = UIReturnKeyGo;
    [self.textField setEnablesReturnKeyAutomatically:YES];

    // Attributed strings in iOS 6 only
    if([self.textField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [UIColor darkGrayColor];
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Type a company or domain..." attributes:@{NSForegroundColorAttributeName: color}];
    }
    else {
        // On iOS 5, we can set the colour (easily) and the default is pretty ugly, so
        // we're just gonna let it be blank for now
        //self.textField.placeholder = @"Type a company or domain...";
    }
    
    [self.view addSubview:self.textField];
    
    UIButton* doneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.textField.x+self.textField.width-10, 2, doneImage.size.width+20, doneImage.size.height+20)];
    [doneButton setImage:doneImage forState:UIControlStateNormal];
    doneButton.imageView.contentMode = UIViewContentModeCenter;
    [doneButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneButton];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(self.textField.x-10, self.textField.y+self.textField.height, self.contentSizeForViewInPopover.width-25, self.contentSizeForViewInPopover.height-self.textField.height-20) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.textField.text = @"";
    self.searchResults = self.allItems;
    self.showHostLookup = NO;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}

#pragma mark - UITextField action method
- (void)textFieldDidChange:(UITextField*)sender {
    [self filterContentForSearchText:sender.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.searchResults.count ? self.searchResults.count : 1) + (self.showHostLookup ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0];
        cell.textLabel.highlightedTextColor = UI_ORANGE_COLOR;
        cell.textLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:24];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.selectedBackgroundView = [[UIView alloc] init];
        
        UIView* seperator = [[UIView alloc] initWithFrame:CGRectMake(10, 43, tableView.width-10, 1)];
        seperator.backgroundColor = [UIColor grayColor];
        [cell.contentView addSubview:seperator];

    }
    
    cell.textLabel.textColor = [UIColor whiteColor];

    int row = indexPath.row;
    
    if(self.showHostLookup) {
        if(row == 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"Find host '%@'", [self.textField.text lowercaseString] ];
            cell.textLabel.textColor = UI_ORANGE_COLOR;
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
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", node.asn, node.friendlyDescription];
    }
    
    if((row == 0) && (self.textField.text.length != 0) && !self.showHostLookup) {
        cell.textLabel.textColor = UI_ORANGE_COLOR;
    }
    
    return cell;
}

- (void)done{
    [self.delegate nodeSearchDelegateDone];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}


- (void)filterContentForSearchText:(NSString*)searchText
{
    if(searchText.length == 0) {
        self.searchResults = self.allItems;
        [self.tableView reloadData];
    }
    else {
        __weak NodeSearchViewController* weakSelf = self;
        NSString* localSearchText = [searchText copy];
        NSString* upcaseSearchText = [[searchText copy] uppercaseString];
        NSArray* localAllItems = self.allItems;
        
        // Store unique id for active search, so we can abort if another search is started
        int mySearchID = ++self.activeSearchID;
        
        [[SCDispatchQueue defaultPriorityQueue] dispatchAsync:^{
            //NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
            NSMutableArray* searchResults = [NSMutableArray new];
            
            for(NodeWrapper* node in localAllItems) {
                if ([[node.rawTextDescription uppercaseString] rangeOfString:upcaseSearchText].location != NSNotFound) {
                    [searchResults addObject:node];
                    continue;
                }
                
                if ([[node.asn uppercaseString] rangeOfString:upcaseSearchText].location != NSNotFound) {
                    [searchResults addObject:node];
                    continue;
                }
                
                // Search ids not matching measn a newer search has started, so abort this one
                if(mySearchID != self.activeSearchID) {
                    //NSLog(@"search (aborted): %.2f", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
                    break;
                }
            }

            if(mySearchID == self.activeSearchID) {
                [[SCDispatchQueue mainQueue] dispatchAsync:^{
                    // Verify that the original parameters are still valid, we don't
                    // want to change the search results if there is another search in progress
                    if((weakSelf.allItems == localAllItems) && [localSearchText isEqualToString:weakSelf.textField.text])
                     {
                         //NSLog(@"search (used): %.2f", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);

                         bool hasDot = [localSearchText rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]].location != NSNotFound;
                         
                         // Only show search for host in table if it might reasonably be a host
                         // or ip address
                         weakSelf.showHostLookup = ((localSearchText.length != 0) && hasDot) ||  (searchResults.count == 0);
                         
                         weakSelf.searchResults = searchResults;
                         [self.tableView reloadData];
                     }
                     else {
                        //NSLog(@"search (discarded): %.2f", ([NSDate timeIntervalSinceReferenceDate] - start) * 1000.0f);
                     }
                }];
            }
        }];
    }
}

@end
