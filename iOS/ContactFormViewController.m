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
@property (strong) IBOutlet UILabel* footerLabel;

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
    self.footerLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:12.0];
    
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
        [self.emailField becomeFirstResponder];
    }
    else if(textField == self.emailField) {
        [self.phoneField becomeFirstResponder];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)submit:(id)sender {
    [self.nameField resignFirstResponder];
    [self.emailField resignFirstResponder];
    [self.phoneField resignFirstResponder];
    
    // suppress forms that are gonna fail
    if((self.nameField.text.length == 0) || (self.emailField.text.length == 0)) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Missing required fields" message:@"Please enter both a name and email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    void (^genericFailure)() = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Could not complete the contact request. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    };
    
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = @"Sending contact request...";
    
    [hud showAnimated:YES];

    NSString* platform =  ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"iPhone" : @"iPad";
    NSDictionary* postData = @{@"fullName" : self.nameField.text,
                               @"email" : self.emailField.text,
                               @"phone" : self.phoneField.text,
                               @"LeadSource" : @"Map of the Internet",
                               @"Website_Source__c" : platform };
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://www.peer1.com/contact-sales"]];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    NSError* error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:postData options:0 error:&error];
    
    if(error) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Internal Error" message:@"Could not build contact submit request." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];        return;
    }
    
    [request appendPostData:data];
    
    __weak ASIFormDataRequest* weakRequest = request;
    
    [request setCompletionBlock:^{
        NSError* error = weakRequest.error;
        NSObject* jsonResponse = [NSJSONSerialization JSONObjectWithData:weakRequest.responseData options:NSJSONReadingAllowFragments error:&error];
        
        NSLog(@"Got contact response %d %@", weakRequest.responseStatusCode, jsonResponse);

        if(weakRequest.responseStatusCode == 200) {
            hud.mode = MBProgressHUDModeText;
            hud.label.text = @"Submitted. Thank you.";
            
            [hud hideAnimated:YES afterDelay:2.0];
            
            [[SCDispatchQueue mainQueue] dispatchAfter:2.0f block:^{
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }
        else {
            [hud hideAnimated:YES];

            NSDictionary* responseDict = nil;
            if([jsonResponse isKindOfClass:[NSDictionary class]]) {
                responseDict = (NSDictionary*)jsonResponse;
            }
            else if ([jsonResponse isKindOfClass:[NSArray class]] &&
                     (((NSArray*)jsonResponse).count > 0) &&
                     [((NSArray*)jsonResponse)[0] isKindOfClass:[NSDictionary class]]) {
                responseDict = (NSDictionary*)(((NSArray*)jsonResponse)[0]);
            }
            
            if((weakRequest.responseStatusCode == 422) && responseDict) {
                if([[responseDict valueForKey:@"field"] isEqualToString:@"email"]) {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Invalid email" message:@"Please enter a valid email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                else if([responseDict valueForKey:@"error"]) {
                    NSString* message;
                    
                    if([responseDict valueForKey:@"field"]) {
                        message = [NSString stringWithFormat:@"%@ : %@", [responseDict valueForKey:@"error"], [responseDict valueForKey:@"field"] ];
                    }
                    else {
                        message = [NSString stringWithFormat:@"%@", [responseDict valueForKey:@"error"] ];
                    }
                    
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Submit Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
                else {
                    genericFailure();
                }
            }
            else {
                genericFailure();
            }
        }
    }];
    
    [request setFailedBlock:genericFailure];
    
    [request startAsynchronous];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [HelperMethods deviceIsiPad] ? UIInterfaceOrientationIsLandscape(interfaceOrientation) : UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

@end
