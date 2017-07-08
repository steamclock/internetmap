//
//  FirstUseViewController.m
//  InternetMap
//
//  Created by Nigel Brooke on 2013-02-12.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "FirstUseViewController.h"

@interface FirstUseViewController ()

@property (weak, nonatomic) IBOutlet UILabel *headlineLabel;
@property (weak, nonatomic) IBOutlet UILabel *broughtToLabel;
@property (weak, nonatomic) IBOutlet UILabel *blurbLabel;

@property (weak, nonatomic) IBOutlet UIButton *exploreButton;

@end


@implementation FirstUseViewController

- (IBAction)explore:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _headlineLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:32.0];
    _broughtToLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:16.0];
    _blurbLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:24.0];
    _exploreButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:24.0];
    _exploreButton.layer.cornerRadius = _exploreButton.frame.size.height / 2;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [HelperMethods deviceIsiPad] ? UIInterfaceOrientationIsLandscape(interfaceOrientation) : UIInterfaceOrientationIsPortrait(interfaceOrientation);
}


@end
