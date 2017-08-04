//
//  CreditsViewController.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-14.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "CreditsViewController.h"

@interface CreditsViewController ()

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
    UIWebView* webView = [[UIWebView alloc] init];
    CGRect webViewFrame = background.frame;
    
    webViewFrame.size.height = [CreditsViewController currentSize].height;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        webViewFrame.origin.x += 300;
        webViewFrame.size.width -= 600;
        
        webView.scrollView.scrollEnabled = FALSE;
    } else {
        webViewFrame.size.width = [[UIScreen mainScreen] bounds].size.width - 20;
    }
    
    webView.frame = webViewFrame;

    NSString *filePath;
    if (self.informationType != nil && [self.informationType isEqualToString:@"about"])
        filePath = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
    else if (self.informationType != nil && [self.informationType isEqualToString:@"contact"])
        filePath = [[NSBundle mainBundle] pathForResource:@"contact" ofType:@"html"];
    else
        filePath = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
    
    NSString *html = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error: nil];
    if (html) {
        [webView loadHTMLString:html baseURL:nil];
    }
    
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    webView.scrollView.showsVerticalScrollIndicator = NO;
    webView.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    // Start webview faded out, load happens async, and this way we can fade it in rather
    // than popping when the load finishes. Slightly less jarring that way.
    webView.alpha = 0.00f;
    
    webView.delegate = self;
    
    [self.view addSubview:webView];
    
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

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.25 animations:^{
        webView.alpha = 1.0f;
    }];
    [webView.scrollView flashScrollIndicators];
}

-(IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [HelperMethods deviceIsiPad] ? UIInterfaceOrientationIsLandscape(interfaceOrientation) : UIInterfaceOrientationIsPortrait(interfaceOrientation);
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
