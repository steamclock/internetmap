//
//  ContactFormViewController.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-12.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "ContactFormViewController.h"
#import "HelperMethods.h"
#import "ASIFormDataRequest.h"
#import "MBProgressHUD.h"
#import "SCDispatchQueue.h"

@interface ContactFormViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;


@end

@implementation ContactFormViewController 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

-(IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) urlToLoad:(NSString *)urlString {
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [_webView loadRequest:request];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.activitySpinner.hidden = YES;
    
    [self urlToLoad:self.urlString];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.activitySpinner.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.activitySpinner.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // the suggested not depreciated call doesnt seem to work
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // the suggested not depreciated call doesnt seem  to work
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}


@end
