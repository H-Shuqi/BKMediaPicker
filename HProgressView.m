//
//  HProgressView.m
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/12.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <BKMediaPicker/HProgressView.h>

@interface HProgressView ()
@property (strong, nonatomic) CAShapeLayer *srogressLayer;
@property (strong, nonatomic) CAShapeLayer *maskLayer;
@property (strong, nonatomic) CALayer *bgLayer;
@end

@implementation HProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = YES;
        
        UIColor *bgColor = [UIColor colorWithWhite:0 alpha:0.45];
        
        _bgLayer = [CALayer layer];
        _bgLayer.frame = self.bounds;
        [self.layer addSublayer:_bgLayer];
        _bgLayer.backgroundColor = bgColor.CGColor;
        
        _maskLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
        [path appendPath:[UIBezierPath bezierPathWithArcCenter:self.center
                                                        radius:CGRectGetWidth(self.bounds) / 3
                                                    startAngle:0
                                                      endAngle:2*M_PI
                                                     clockwise:NO]];
        _maskLayer.path = path.CGPath;
        _bgLayer.mask = _maskLayer;
        
        _srogressLayer = [CAShapeLayer layer];
        _srogressLayer.fillColor = [UIColor clearColor].CGColor;
        _srogressLayer.strokeColor = bgColor.CGColor;
        _srogressLayer.lineWidth = CGRectGetWidth(self.bounds) / 3;
        _srogressLayer.path = [UIBezierPath bezierPathWithArcCenter:self.center
                                                             radius:CGRectGetWidth(self.bounds) / 6
                                                         startAngle:0
                                                           endAngle:2*M_PI
                                                          clockwise:NO].CGPath;
        _srogressLayer.strokeStart = 0;
        _srogressLayer.strokeEnd = 1;
        [self.layer addSublayer:_srogressLayer];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    progress = 1- progress;
    
    if(progress < 0)progress = 0;
    if (progress > 1)progress = 1;

    dispatch_async(dispatch_get_main_queue(), ^{
        _srogressLayer.strokeEnd = progress;
    });
}

- (CGFloat)progress {
    return 1-_srogressLayer.strokeEnd;
}

@end
