//
//  CreditsViewController.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-14.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "CreditsViewController.h"
#import "ViewController.h"

@interface CreditsViewController ()

@property (nonatomic, retain) UIWebView* webView;
@property (nonatomic, retain) UIButton* contactButton;

@end

@implementation CreditsViewController

+(CGSize) currentSize
{
    return [CreditsViewController sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

+(CGSize) sizeInOrientation:(UIInterfaceOrientation)orientation
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    if (application.statusBarHidden == NO)
    {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

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
    // Background image
    UIImage* backgroundImage;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        backgroundImage = [UIImage imageNamed:@"iphone-bg.png"];
    }
    else {
        backgroundImage = [UIImage imageNamed:@"ipad-bg.png"];
    }
    
    UIImageView* background = [[UIImageView alloc] initWithImage:backgroundImage];
    
    background.userInteractionEnabled = YES;
    
    self.view = background;
    
    // Webview for contents
    self.webView = [[UIWebView alloc] init];
    CGRect webViewFrame = background.frame;
    
    webViewFrame.size.height = [CreditsViewController currentSize].height;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // webViewFrame.origin.x += 300;
        webViewFrame.origin.x = ([[UIScreen mainScreen] bounds].size.width)/2-200;
        webViewFrame.size.width -= 600;
        
        _webView.scrollView.scrollEnabled = FALSE;
    } else {
        webViewFrame.size.width = [[UIScreen mainScreen] bounds].size.width - 20;
    }
    
    _webView.frame = webViewFrame;

    NSString *filePath;
    if (self.informationType != nil && [self.informationType isEqualToString:@"about"])
        filePath = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
    else if (self.informationType != nil && [self.informationType isEqualToString:@"contact"])
        filePath = [[NSBundle mainBundle] pathForResource:@"contact" ofType:@"html"];
    else
        filePath = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
    
    NSString *html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error: nil];
    if (html) {
        [_webView loadHTMLString:html baseURL:nil];
    }
    
    _webView.backgroundColor = [UIColor clearColor];
    _webView.opaque = NO;
    _webView.scrollView.showsVerticalScrollIndicator = NO;
    _webView.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    // Start webview faded out, load happens async, and this way we can fade it in rather
    // than popping when the load finishes. Slightly less jarring that way.
    _webView.alpha = 0.00f;
    
    _webView.delegate = self;
    _webView.scrollView.delegate = self;
    
    [self.view addSubview:_webView];
    
    //Done button
    UIImage* xImage = [UIImage imageNamed:@"x-icon"];
    UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect doneFrame = CGRectMake([[UIScreen mainScreen] bounds].size.width - (xImage.size.width+20), 0, xImage.size.width+20, xImage.size.height+20);
    doneButton.frame = doneFrame;
    doneButton.imageView.contentMode = UIViewContentModeCenter;
    [doneButton setImage:xImage forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    doneButton.backgroundColor = UI_PRIMARY_COLOR;
    [self.view addSubview:doneButton];
    
    [super viewDidLoad];
}

-(void) createContactButtonForAbout {
    
    _contactButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _contactButton.titleLabel.textColor = [UIColor whiteColor];
    [_contactButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_contactButton setTitle:NSLocalizedString(@"Contact Cogeco Peer 1", nil) forState:UIControlStateNormal];
    _contactButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:18];
    CGRect contactFrame;
    if (![HelperMethods deviceIsiPad])
        contactFrame = CGRectMake(20, [UIScreen mainScreen].bounds.size.height-40, 250, 40);
    else
        contactFrame = CGRectMake(([UIScreen mainScreen].bounds.size.width)/2-150, [UIScreen mainScreen].bounds.size.height-40, 250, 40);
    _contactButton.frame = contactFrame;
    [_contactButton addTarget:self action:@selector(contact:) forControlEvents:UIControlEventTouchUpInside];
    if (![HelperMethods deviceIsiPad])
        _contactButton.hidden = YES;
    [self.view addSubview:_contactButton];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.25 animations:^{
        webView.alpha = 1.0f;
    }];
    [webView.scrollView flashScrollIndicators];
    
    if ([_informationType isEqualToString:@"about"])
        [self createContactButtonForAbout];
}

-(IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)contact:(id)sender {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"contact" ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error: nil];
    if (html) {
        [_webView loadHTMLString:html baseURL:nil];
    }
    
    _informationType = @"contact";
    [_contactButton removeFromSuperview];
    
    [_webView.scrollView setContentOffset: CGPointMake(0, -_webView.scrollView.contentInset.top) animated:YES];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [HelperMethods deviceIsiPad] ? UIInterfaceOrientationIsLandscape(interfaceOrientation) : UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height-50)){
        NSLog(@"BOTTOM REACHED");
        _contactButton.hidden = NO;
    } else {
        NSLog(@"not bottom");
        _contactButton.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // the suggested not depreciated call does not seem to work
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // the suggested not depreciated call does not seem  to work
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}


@end
