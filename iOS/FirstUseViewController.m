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


static const int NUM_PAGES = 2;

@implementation FirstUseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void)viewWillAppear:(BOOL)animated {
    self.content.delegate = self;
    
    CGRect frame = self.content.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    
    UIImageView* content0 = [[UIImageView alloc] initWithFrame:frame];

    frame.origin.x += frame.size.width;
    UIImageView* content1 = [[UIImageView alloc] initWithFrame:frame];

    content0.image = [UIImage imageNamed:@"eye.png"];
    content1.image = [UIImage imageNamed:@"youarehere.png"];
    
    [self.content addSubview:content0];
    [self.content addSubview:content1];
    
    self.content.contentSize = CGSizeMake(frame.size.width * 2, frame.size.height);
    
    self.page = 0;
    [self setPageMarkerForPage:0];
}

-(void)setPageMarkerForPage:(int)page {
    switch(page) {
        case 0:
            self.pageMarker.image = [UIImage imageNamed:@"eye.png"];
            break;
        case 1:
            self.pageMarker.image = [UIImage imageNamed:@"youarehere.png"];
            break;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int page = (int)round( scrollView.contentOffset.x / scrollView.frame.size.width);
    
    if(page != self.page) {
        self.page = page;
        [self setPageMarkerForPage:page];
    }
}

-(IBAction)next:(id)sender {
    int page = (int)round( self.content.contentOffset.x / self.content.frame.size.width);
 
    if(page == (NUM_PAGES - 1)) {
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        CGRect frame = self.content.frame;
        frame.origin.x = (page + 1) * frame.size.width;
        frame.origin.y = 0;
        
        [self.content scrollRectToVisible:frame animated:YES];
    }
}

@end
