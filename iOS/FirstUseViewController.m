//
//  FirstUseViewController.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-12.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "FirstUseViewController.h"

@interface FirstUseViewController ()

@property (strong) IBOutlet UIScrollView* content;
@property (strong) IBOutlet UIImageView* pageMarker;
@property (strong) IBOutlet UIImageView* background;
@property (strong) IBOutlet UIButton* next;

@property int page;
@end


static const int NUM_PAGES = 3;

@implementation FirstUseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization is all in viewWillApper (to make sure that resizes and stuff have already happened)
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.content.delegate = self;
    self.view.frame = [UIApplication sharedApplication].keyWindow.frame;
    
    // Do idiom specific setup
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.background.image = [UIImage imageNamed:@"iphone-bg.png"];
    }
    else {
        self.background.image = [UIImage imageNamed:@"ipad-bg.png"];
    }
    
    // Add all the actual pages to the scrioll view
    CGRect frame = self.content.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    for(int i = 0; i < NUM_PAGES; i++) {
        UIImageView* page = [[UIImageView alloc] initWithFrame:frame];
        [page setContentMode:UIViewContentModeScaleAspectFit];
        frame.origin.x += frame.size.width;
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            page.image = [UIImage imageNamed:[NSString stringWithFormat:@"help0%d.png", i+1]];
        }
        else {
            page.image = [UIImage imageNamed:[NSString stringWithFormat:@"help0%d-ipad.png", i+1]];
        }
        
        page.contentMode = UIViewContentModeScaleAspectFit;

        [self.content addSubview:page];
    }
    

    self.content.contentSize = CGSizeMake(frame.size.width * NUM_PAGES, frame.size.height);

    NSLog (@"CONTENT WIDTH %f HEIGHT %f", self.content.contentSize.width, self.content.contentSize.height );
    
    // Set up everything for the firsst page
    self.page = 0;
    [self setPageMarkerForPage:0];
}

-(void)setPageMarkerForPage:(int)page {
    if(page >= NUM_PAGES) {
        page = NUM_PAGES - 1;
    }
    
    // The little dots to show the page
    self.pageMarker.image = [UIImage imageNamed:[NSString stringWithFormat:@"screen%d-highlight.png", page+1]];
    
    // Show diffeernt button for last page
    UIImage* nextImage = (page == (NUM_PAGES - 1)) ? [UIImage imageNamed:@"finish.png"] : [UIImage imageNamed:@"next-button.png"];
    [self.next setImage:nextImage forState:UIControlStateNormal];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // rounding, so it changes halfway through scroll
    int page = (int)round( scrollView.contentOffset.x / scrollView.frame.size.width);
    
    // Change the dots and the button 
    if(page != self.page) {
        self.page = page;
        [self setPageMarkerForPage:page];
    }
}

-(IBAction)next:(id)sender {
    int page = (int)round( self.content.contentOffset.x / self.content.frame.size.width);
 
    if(page == (NUM_PAGES - 1)) {
        // Last page, dismiss
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        //Trigger scroll to next page
        CGRect frame = self.content.frame;
        frame.origin.x = (page + 1) * frame.size.width;
        frame.origin.y = 0;
        
        [self.content scrollRectToVisible:frame animated:YES];
    }
}


-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [HelperMethods deviceIsiPad] ? UIInterfaceOrientationIsLandscape(interfaceOrientation) : UIInterfaceOrientationIsPortrait(interfaceOrientation);
}


@end
