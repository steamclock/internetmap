//
//  LabelNumberBoxView.h
//  InternetMap
//
//  Created by Alexander on 07.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LabelNumberBoxView : UIView

@property (nonatomic, strong) UILabel* textLabel;
@property (nonatomic, strong) UILabel* numberLabel;
@property (nonatomic, strong) UIView* dividerView;

- (id)initWithFrame:(CGRect)frame labelText:(NSString*)labelText numberText:(NSString*)numberText;
- (void)incrementNumber;

@end
