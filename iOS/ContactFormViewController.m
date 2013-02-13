//
//  ContactFormViewController.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-12.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "ContactFormViewController.h"

@interface ContactFormViewController ()

@property (strong) IBOutlet UIImageView* background;
@property (strong) IBOutlet UIView* container;
@property (strong) IBOutlet UIButton* submitButton;

@property (strong) IBOutlet UITextField* nameField;
@property (strong) IBOutlet UIImageView* nameBackground;

@property (strong) IBOutlet UITextField* phoneField;
@property (strong) IBOutlet UIImageView* phoneBackground;

@property (strong) IBOutlet UITextField* emailField;
@property (strong) IBOutlet UIImageView* emailBackground;

@end

@implementation ContactFormViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.background.image = [UIImage imageNamed:@"iphone-bg.png"];
        
        // Automatic positioning doesn't handle y position of inset content view on iPhone,
        // need to manually position
        CGRect origFrame = self.container.frame;
        origFrame.origin.x = 0;
        origFrame.origin.y = 0;
        self.container.frame = origFrame;
    }
    else {
        self.background.image = [UIImage imageNamed:@"ipad-bg.png"];
    }
    
    UIImage* fieldBackground = [[UIImage imageNamed:@"contact-sales-field.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 12, 10, 12)];
    [self.nameBackground setImage:fieldBackground];
    [self.phoneBackground setImage:fieldBackground];
    [self.emailBackground setImage:fieldBackground];
    
    [self.submitButton setBackgroundImage:[[UIImage imageNamed:@"traceroute-button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 22, 0, 22)] forState:UIControlStateNormal];
}

-(IBAction)done:(id)sender {
    [self dismissModalViewControllerAnimated:TRUE];
}

-(IBAction)submit:(id)sender {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
