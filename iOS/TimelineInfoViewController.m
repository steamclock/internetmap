//
//  TimelineInfoViewController.m
//  InternetMap
//
//  Created by Alexander on 18.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "TimelineInfoViewController.h"
#import <CoreText/CoreText.h>
#import "TTTAttributedLabel.h"

@interface TimelineInfoViewController ()

@property(nonatomic, strong) TTTAttributedLabel* label;
@property(nonatomic, strong) UILabel* yearLabel;
@property(nonatomic, strong) UIView* yearLabelBackgroundView;

@end

@implementation TimelineInfoViewController

- (id)init {
    if (self = [super init]) {
        NSString* json = [[NSBundle mainBundle] pathForResource:@"history" ofType:@"json"];
        self.jsonDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:json] options:0 error:nil];
        self.contentSizeForViewInPopover = CGSizeMake(320, 0); //height is set in setYear:
    }
    
    return self;
}

- (void)viewDidLoad
{
    
    UIView* divider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSizeForViewInPopover.width, 1)];
    divider.backgroundColor = UI_ORANGE_COLOR;
    divider.alpha = 0.5;
    [self.view addSubview:divider];
    
    
    self.label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.lineBreakMode = UILineBreakModeWordWrap;
    self.label.numberOfLines = 0;
    [self.view addSubview:self.label];
    
    self.yearLabelBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.yearLabelBackgroundView.backgroundColor = UI_ORANGE_COLOR;
    [self.view addSubview:self.yearLabelBackgroundView];
    
    self.yearLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.yearLabel.textColor = [UIColor blackColor];
    self.yearLabel.backgroundColor = [UIColor clearColor];
    self.yearLabel.font = [UIFont fontWithName:FONT_NAME_MEDIUM size:25];
    [self.yearLabelBackgroundView addSubview:self.yearLabel];

    [super viewDidLoad];
    
}

- (void)setYear:(int)year {
    if (_year == year) {
        return;
    }
    _year = year;
    
    
    //force view to load (else labels could be nil)
    [self.view setNeedsLayout];
    
    NSString* yearString = [NSString stringWithFormat:@"%i", year];
    NSString* string = self.jsonDict[yearString];
    if (string) {
        string = [string stringByReplacingOccurrencesOfString:@"</b>" withString:@"<b>"];
        string = [string stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
        NSArray* components = [string componentsSeparatedByString:@"<b>"];
        NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] init];
        for (int i = 0; i<[components count]; i++) {
            NSString* comp = components[i];
            if (![comp isEqualToString:@""]) {
                NSString* fontName = i%2 ? FONT_NAME_MEDIUM : FONT_NAME_LIGHT;
                CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, 19, NULL);
                UIFont* font = (__bridge id)fontRef;
                NSAttributedString* tempAttr = [[NSAttributedString alloc] initWithString:comp attributes:@{(id)kCTFontAttributeName : font, (id)kCTForegroundColorAttributeName : (id)[UIColor whiteColor].CGColor}];
                [attributedString appendAttributedString:tempAttr];
                CFRelease(fontRef);
            }
        }
        
        float yearLabelHeight = 44;
        string = [string stringByReplacingOccurrencesOfString:@"<b>" withString:@""];
        CGSize size = CGSizeMake(0, [self heightForMutableAttributedString:attributedString width:self.contentSizeForViewInPopover.width-10]);
        self.contentSizeForViewInPopover = CGSizeMake(self.contentSizeForViewInPopover.width, size.height+yearLabelHeight+5+8);
        self.label.frame = CGRectMake(5, 5, self.contentSizeForViewInPopover.width-10, size.height);
        self.label.text = attributedString;
        
        self.yearLabelBackgroundView.frame = CGRectMake(0, self.contentSizeForViewInPopover.height-yearLabelHeight, self.contentSizeForViewInPopover.width, yearLabelHeight);
        self.yearLabel.frame = CGRectMake(10, 5, self.yearLabelBackgroundView.width-20, self.yearLabelBackgroundView.height-10);
        self.yearLabel.text = yearString;
    }
    

}

-(void)startLoad {
    self.yearLabel.text = [NSString stringWithFormat:@"Loading %d", self.year];
}


- (CGFloat)heightForMutableAttributedString:(NSMutableAttributedString*)mutableAttString width:(CGFloat)width
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString( (__bridge CFMutableAttributedStringRef) mutableAttString);
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(width, CGFLOAT_MAX), NULL);
    CFRelease(framesetter);
    return suggestedSize.height;
}

@end
