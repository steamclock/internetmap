//
//  ContactFormViewController.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-12.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "ContactFormViewController.h"
#import "HelperMethods.h"

@interface ContactFormViewController ()

@property (strong) IBOutlet UILabel* titleLabel;
@property (strong) IBOutlet UILabel* blurbLabel;

@property (strong) IBOutlet UIImageView* background;
@property (strong) IBOutlet UIScrollView* container;
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

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.titleLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:22.0];
    self.blurbLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:14.0];
    
    UIImage* fieldBackground = [[UIImage imageNamed:@"contact-sales-field.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
    [self.nameBackground setImage:fieldBackground];
    [self.phoneBackground setImage:fieldBackground];
    [self.emailBackground setImage:fieldBackground];
    
    [self.submitButton setBackgroundImage:[[UIImage imageNamed:@"traceroute-button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 22, 0, 22)] forState:UIControlStateNormal];
    
    self.nameField.delegate = self;
    self.phoneField.delegate = self;
    self.emailField.delegate = self;
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
    
    CGRect frame = self.container.frame;
    frame.size.height += 100;
    self.container.contentSize = frame.size;

}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.container scrollRectToVisible:CGRectMake(0, 50, 320, 480) animated:YES];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.nameField) {
        [self.phoneField becomeFirstResponder];
    }
    else if(textField == self.phoneField) {
        [self.emailField becomeFirstResponder];
    }
    else {
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [self.container scrollRectToVisible:CGRectMake(0, 0, 320, 480) animated:YES];
        }
        [textField resignFirstResponder];
    }
    return YES;
}

-(IBAction)done:(id)sender {
    [self dismissModalViewControllerAnimated:TRUE];
}

-(IBAction)submit:(id)sender {
    [self dismissModalViewControllerAnimated:TRUE];
}

@end
