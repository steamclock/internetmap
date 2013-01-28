//
//  ErrorInfoQueueView.m
//  InternetMap
//
//  Created by Alexander on 14.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "ErrorInfoView.h"

@interface ErrorInfoView()

@property (nonatomic, strong) NSTimer* hidingTimer;

@end

@implementation ErrorInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.userInteractionEnabled = YES;
        [self addSubview:self.label];
    }
    return self;
}


- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.label.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

- (void)setErrorString:(NSString*)error {
    
    void (^completion)(BOOL) = ^(BOOL finished) {
        self.label.text = error;
        [self.hidingTimer invalidate];
        self.hidingTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hidingTimerFired) userInfo:nil repeats:NO];
    };
    
    if (self.label.alpha == 1.0) {
        completion(YES);
    }else {
        [UIView animateWithDuration:0.75 animations:^{
            self.label.alpha = 1.0;
        } completion:completion];
    }
}

- (void)hidingTimerFired {
    [UIView animateWithDuration:0.75 animations:^{
        self.label.alpha = 0.0;
    }];
}

@end
