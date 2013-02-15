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

-(void)setPlaceholderColor:(UIColor*)color forTextField:(UITextField*)field {
    if(![self.nameField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        return;
    }

    if(field == self.nameField) {
        self.nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Name (Required)" attributes:@{NSForegroundColorAttributeName: color}];
    }
    else if (field == self.phoneField) {
        self.phoneField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Phone" attributes:@{NSForegroundColorAttributeName: color}];
    }
    else if(field == self.emailField) {
        self.emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email (Required)" attributes:@{NSForegroundColorAttributeName: color}];
    }
}

-(UIImageView*)backgroundForField:(UITextField*)field {
    if(field == self.nameField) {
        return self.nameBackground;
    }
    else if (field == self.phoneField) {
        return self.phoneBackground;
    }
    else if(field == self.emailField) {
        return self.emailBackground;
    }
    
    return nil;
} 

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.container scrollRectToVisible:CGRectMake(0, 50, 320, 480) animated:YES];
    }
    
    UIImage* fieldBackground = [[UIImage imageNamed:@"contact-sales-field-highlighted.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
    [[self backgroundForField:textField] setImage:fieldBackground];
    [textField setTextColor:[UIColor blackColor]];
    [self setPlaceholderColor:[UIColor darkGrayColor] forTextField:textField];
}


-(void)textFieldDidEndEditing:(UITextField *)textField {
    UIImage* fieldBackground = [[UIImage imageNamed:@"contact-sales-field.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
    [[self backgroundForField:textField] setImage:fieldBackground];
    [textField setTextColor:[UIColor whiteColor]];
    [self setPlaceholderColor:[UIColor lightGrayColor] forTextField:textField];
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
    // suppress forms that are gonna fail
    if((self.nameField.text.length == 0) || (self.emailField.text.length == 0)) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Missing required fields" message:@"Please enter both a name and email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    void (^failure)() = ^{
        [self dismissModalViewControllerAnimated:TRUE];
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Could not complete the contact request. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    };
    
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Sending contact request...";
    
    [hud show:YES];

    NSString* platform =  ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"iPhone" : @"iPad";
    NSDictionary* postData = @{@"fullName" : self.nameField.text,
                               @"email" : self.emailField.text,
                               @"phone" : self.phoneField.text,
//                               @"company" : @"",
                               @"LeadSource" : @"Map of the Internet",
                               @"Website_Source__c" : platform };
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://www.peer1.com/lead-submit"]];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    NSError* error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
    
    if(error) {
        failure();
        return;
    }
    
    [request appendPostData:data];
    
    __weak ASIFormDataRequest* weakRequest = request;
    
    [request setCompletionBlock:^{
        NSError* error = weakRequest.error;
        NSDictionary* jsonResponse = [NSJSONSerialization JSONObjectWithData:weakRequest.responseData options:NSJSONReadingAllowFragments error:&error];
        
        NSLog(@"Got contact response %d %@", weakRequest.responseStatusCode, jsonResponse);

        if(weakRequest.responseStatusCode == 200) {
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"Sent request";
            
            [hud hide:YES afterDelay:1.0];
            
            [[SCDispatchQueue mainQueue] dispatchAfter:1.0f block:^{
                [self dismissModalViewControllerAnimated:TRUE];
            }];
        }
        else {
            failure();
        }
    }];
    
    [request setFailedBlock:failure];
    
    [request startAsynchronous];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [HelperMethods deviceIsiPad] ? UIInterfaceOrientationIsLandscape(interfaceOrientation) : UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

@end
