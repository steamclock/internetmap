//
//  UIAlertView+SCBlocks.m
//
// -- Software License --
//
// Copyright (C) 2013, Steam Clock Software, Ltd.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// ----------------------

#import "UIAlertView+SCBlocks.h"

@interface SCAlertViewProxy : NSObject <UIAlertViewDelegate> {
    SCAlertViewProxy* _keepAlive; // we are a free roaming delegate, need a reference to ourself to avoid death
    NSArray* _actions;
    void (^_dismiss)();
}

@end

@implementation SCAlertViewProxy

-(id)initWithActions:(NSArray*)actions andDismiss:(void(^)())dismiss {
    if((self = [super init])) {
        _keepAlive = self;
        _actions = actions;
        _dismiss = dismiss;
    }
    return self;
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ((buttonIndex >= 0) && (buttonIndex < [_actions count])) {
        void(^action)() = [_actions objectAtIndex:buttonIndex];
        action();
    }
    _dismiss();
    _keepAlive = nil;
}

@end

@implementation UIAlertView (SCBlockAditions)
+(UIAlertView*) alertViewWithTitle:(NSString*)title 
                           message:(NSString*)message
                           dismiss:(void(^)())dismiss 
                 buttonsAndActions:(NSObject*) buttonsAndActions, ... { 
    
    NSMutableArray* actions = [NSMutableArray new];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title 
                                                        message:message 
                                                       delegate:nil 
                                              cancelButtonTitle:nil 
                                              otherButtonTitles:nil];
    va_list args;
    va_start(args, buttonsAndActions);
    
    NSObject* buttonTitle = (NSString*)buttonsAndActions;
    
    while(buttonTitle) {
        NSObject* action =  va_arg(args, NSObject*);
        
        if(buttonTitle != [NSNull null]) {
            [alertView addButtonWithTitle:(NSString*)buttonTitle];
            [actions addObject:[action copy]];
        }
        
        buttonTitle = va_arg(args, NSObject*);
    }
    va_end(args);

    SCAlertViewProxy* proxy = [[SCAlertViewProxy alloc] initWithActions:actions andDismiss:[dismiss copy]];
    alertView.delegate = proxy;
        
    return alertView;
}

@end