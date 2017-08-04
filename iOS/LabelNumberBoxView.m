//
//  LabelNumberBoxView.m
//  InternetMap
//
//  Created by Alexander on 07.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "LabelNumberBoxView.h"

@implementation LabelNumberBoxView

- (id)initWithFrame:(CGRect)frame labelText:(NSString*)labelText numberText:(NSString*)numberText
{
    self = [super initWithFrame:frame];
    if (self) {
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height*0.382)];//golden ratio
        self.textLabel.text = labelText;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:15];
        self.textLabel.textColor = FONT_COLOR_WHITE;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.textLabel];
        
        self.dividerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.textLabel.y+self.textLabel.height, self.width, 1)];
        self.dividerView.backgroundColor = [UIColor grayColor];
        [self addSubview:self.dividerView];
        
        CGFloat numberLabelHeight = self.height-self.textLabel.height-self.dividerView.height;
        self.numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.height-numberLabelHeight, self.width, numberLabelHeight)];
        self.numberLabel.text = numberText;
        self.numberLabel.backgroundColor = [UIColor clearColor];
        self.numberLabel.font = [UIFont fontWithName:FONT_NAME_LIGHT size:28];
        self.numberLabel.textColor = FONT_COLOR_WHITE;
        self.numberLabel.textAlignment = NSTextAlignmentCenter;
        self.numberLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.numberLabel];
    }
    return self;
}

- (void)incrementNumber {
    int number = [self.numberLabel.text intValue];
    number++;
    self.numberLabel.text = [NSString stringWithFormat:@"%i", number];
}

@end
