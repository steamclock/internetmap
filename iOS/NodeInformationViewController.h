//
//  NodeInformationViewController.h
//  InternetMap
//
//  Created by Angelina Fabbro on 12-12-04.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

@class LabelNumberBoxView;
@class NodeWrapper;

@protocol NodeInformationViewControllerDelegate <NSObject>

-(void)tracerouteButtonTapped;
-(void)pingButtonTapped;
-(void)forceTracerouteTimeout;

@end

@interface NodeInformationViewController : UIViewController


- (id)initWithNode:(NodeWrapper*)node isCurrentNode:(BOOL)isCurrent parent:(UIView*)parent;
- (void)tracerouteDone;

@property (strong, nonatomic) UILabel* topLabel;
@property (strong, nonatomic) UIButton* tracerouteButton;
@property (strong, nonatomic) UIButton* pingButton;
@property (nonatomic, strong) UITextView* tracerouteTextView;
@property (nonatomic, strong) NSTimer* tracerouteTimer;
@property (nonatomic, strong) LabelNumberBoxView* box1;
@property (nonatomic, strong) LabelNumberBoxView* box2;
@property (nonatomic, strong) LabelNumberBoxView* box3;

@property (weak, nonatomic) id<NodeInformationViewControllerDelegate> delegate;

@end
