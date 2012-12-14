//
//  ErrorInfoQueueView.h
//  InternetMap
//
//  Created by Alexander on 14.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ErrorInfoView : UIView

@property (nonatomic, strong) UILabel* label;


- (void)setErrorString:(NSString*)error;


@end
