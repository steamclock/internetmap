//
//  NodeInformationViewController.h
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-04.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "ViewController.h"

@interface NodeInformationViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel* asnLabel;
@property (weak, nonatomic) IBOutlet UILabel* textDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel* nodeTypeLabel;
@property (weak, nonatomic) id delegate;

@end
