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

- (void) urlToLoad:(NSString *)urlString {
    
    NSURL *nsUrl = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    
    [_webView loadRequest:request];
    
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.activitySpinner.hidden = YES;
    
    [self urlToLoad:self.urlString];
        
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
 
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.activitySpinner.hidden = NO;
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.activitySpinner.hidden = YES;
    
}

-(IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
