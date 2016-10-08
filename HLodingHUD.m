//
//  HLodingHUD.m
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/16.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <BKMediaPicker/HLodingHUD.h>
#import <QuartzCore/QuartzCore.h>

@interface HLayer : CAShapeLayer
@property (nonatomic, strong) CAAnimation *animation;

- (CAAnimation *)animationWithDuration:(NSTimeInterval)duration positionY:(CGFloat)positionY;
+ (instancetype)layerWithSize:(CGFloat)size;

@end

@implementation HLayer

+ (instancetype)layerWithSize:(CGFloat)size {
    HLayer *layer = [super layer];
    layer.bounds = CGRectMake(0, 0, size, size);
    layer.cornerRadius = CGRectGetWidth(layer.bounds)/2;
    layer.backgroundColor = [UIColor whiteColor].CGColor;
    return layer;
}

- (CAAnimation *)animationWithDuration:(NSTimeInterval)duration positionY:(CGFloat)positionY {
    CABasicAnimation *pba = [CABasicAnimation animationWithKeyPath:@"position"];
    pba.fromValue = [NSValue valueWithCGPoint:self.position];
    CGPoint point1 = self.position;
    point1.y -= positionY;
    pba.autoreverses = YES;
    pba.repeatCount = HUGE_VALF;
    pba.toValue = [NSValue valueWithCGPoint:point1];
    pba.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    pba.duration = duration;
    return pba;
}

@end

@interface HLodingHUD ()
@property (nonatomic, strong) CAReplicatorLayer *replicatorLayer;
@property (nonatomic, strong) NSTimer *timer;//暂停控制
@property (nonatomic) CGFloat durationTime;//播放速度
@property (nonatomic) NSUInteger layerCount;//Item个数
@property (nonatomic) CGFloat layerSize;//Item大小
@property (nonatomic, strong) UIColor *hudBGColor;//遮盖背景
@property (nonatomic, strong) CAAnimation *animation;//旋转动画
@property (nonatomic) BOOL interval;//是否暂停
@property (nonatomic) BOOL bounce;//是否弹跳
@property (nonatomic) CGFloat layerPositionHeight;//弹跳高度
@end

@implementation HLodingHUD

static HLodingHUD *hud;

+ (void)hudWithSetting:(void(^)(HLodingHUD *hud))settingHeader {
    if(!hud){
        UIWindow *window = [[UIApplication sharedApplication].delegate window];
        hud = [[self alloc] initWithFrame:window.bounds];
        
        hud.hidden = YES;
        
        hud.durationTime = 0.4;
        hud.layerCount = 4;
        hud.layerSize = 50;
        hud.hudBGColor = [UIColor colorWithWhite:0 alpha:0.3];
        hud.interval = NO;
        hud.layerPositionHeight = 80;
        hud.bounce = NO;
    }else{
        for(HLayer *layer in hud.replicatorLayer.sublayers){
            [layer removeFromSuperlayer];
        }
    }
    
    if(settingHeader){
        settingHeader(hud);
    }
    
    if(hud.hudBGColor){
        hud.backgroundColor = hud.hudBGColor;
    }else{
        hud.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    }
    
    hud.replicatorLayer = [[CAReplicatorLayer alloc] init];
    hud.replicatorLayer.bounds = CGRectMake(0, 0, 300, 300);
    hud.replicatorLayer.position = hud.center;
    hud.replicatorLayer.backgroundColor = [UIColor clearColor].CGColor;
    [hud.layer addSublayer:hud.replicatorLayer];
    
    HLayer *layer = [HLayer layerWithSize:hud.layerSize];
    [hud.replicatorLayer addSublayer:layer];
    CGRect bounds = hud.replicatorLayer.bounds;
    layer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGPoint anchorPoint = layer.anchorPoint;
    anchorPoint.y += hud.layerCount*0.3f;
    layer.anchorPoint = anchorPoint;
    if(hud.bounce){
        layer.animation = [layer animationWithDuration:hud.durationTime positionY:hud.layerPositionHeight];
    }
    
    hud.replicatorLayer.instanceCount = hud.layerCount;
    CGFloat angle = (2.f * M_PI) / hud.layerCount;
    hud.replicatorLayer.instanceTransform = CATransform3DMakeRotation(angle, 0, 0, 1);
    hud.replicatorLayer.instanceColor = [UIColor colorWithRed:44/255.f green:152/255.f blue:240/255.f alpha:1].CGColor;
    hud.replicatorLayer.instanceGreenOffset = ((100.f/hud.layerCount)/255.f);
    hud.replicatorLayer.instanceRedOffset = ((255.f/hud.layerCount)/255.f);
    hud.replicatorLayer.instanceBlueOffset = -((255.f/hud.layerCount)/255.f);
//    hud.replicatorLayer.instanceAlphaOffset = -(1.1/(float)hud.layerCount);
//    hud.replicatorLayer.instanceDelay = 0.05;
    
    CABasicAnimation *rba = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rba.fromValue = [NSNumber numberWithFloat:M_PI/hud.layerCount];
    rba.toValue = [NSNumber numberWithFloat:M_PI*2+M_PI/hud.layerCount];
    rba.autoreverses = NO;
    rba.repeatCount = HUGE_VALF;
    rba.duration = hud.durationTime*8;
    rba.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    hud.animation = rba;
}

- (void)timerAnimationController:(NSTimer *)timer {
    CGFloat speed = hud.replicatorLayer.speed;
    if(speed != 0){
        CFTimeInterval pausedTime = [hud.replicatorLayer convertTime:CACurrentMediaTime() fromLayer:nil];
        hud.replicatorLayer.speed = 0.0;
        hud.replicatorLayer.timeOffset = pausedTime;
    }else{
        CFTimeInterval pausedTime = [hud.replicatorLayer timeOffset];
        hud.replicatorLayer.speed = 1.0;
        hud.replicatorLayer.timeOffset = 0.0;
        hud.replicatorLayer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [hud.replicatorLayer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
        hud.replicatorLayer.beginTime = timeSincePause;
    }
}

- (HLodingHUD *(^)(NSUInteger itemCount))itemCount {
    return ^HLodingHUD *(NSUInteger itemCount){
        if(itemCount < 1){
            itemCount = 1;
        }else if(itemCount > 6){
            itemCount = 6;
        }
        self.layerCount = itemCount;
        return self;
    };
}

- (HLodingHUD *(^)(CGFloat duration))duration {
    return ^HLodingHUD *(CGFloat duration){
        if(duration < 0.1){
            duration = 0.1;
        }
        self.durationTime = duration;
        return self;
    };
}

- (HLodingHUD *(^)(UIColor *bgColor))bgColor {
    return ^HLodingHUD *(UIColor *bgColor) {
        self.hudBGColor = bgColor;
        return self;
    };
}

- (HLodingHUD *(^)(CGFloat itemSize))itemSize {
    return ^HLodingHUD *(CGFloat itemSize) {
        if(itemSize < 5){
            itemSize = 5;
        }else if(itemSize > 80){
            itemSize = 80;
        }
        self.layerSize = itemSize;
        return self;
    };
}

- (HLodingHUD *(^)(BOOL hasInterval))hasInterval {
    return ^HLodingHUD *(BOOL hasInterval) {
        self.interval = hasInterval;
        return self;
    };
}

- (HLodingHUD *(^)(BOOL hasBounce))hasBounce {
    return ^HLodingHUD *(BOOL hasBounce) {
        self.bounce = hasBounce;
        return self;
    };
}

- (HLodingHUD *(^)(CGFloat positionHeight))positionHeight {
    return ^HLodingHUD *(CGFloat positionHeight) {
        self.layerPositionHeight = positionHeight;
        return self;
    };
}

+ (void)show {
    @synchronized (self) {
        if(!hud){
            [self hudWithSetting:NULL];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showHUD];
    });
}

+ (void)showHUD {
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    [window addSubview:hud];
    [window bringSubviewToFront:hud];
    hud.hidden = NO;
    
    [hud.replicatorLayer addAnimation:hud.animation forKey:@"rba"];
    if(hud.interval){
        hud.timer = [NSTimer scheduledTimerWithTimeInterval:hud.durationTime*2 target:hud selector:@selector(timerAnimationController:) userInfo:nil repeats:YES];
    }
    if(hud.bounce){
        for (HLayer *layer in hud.replicatorLayer.sublayers){
            if(!layer.animation) break;
            [layer addAnimation:layer.animation forKey:@"pba"];
        }
    }
}

+ (void)dismiss {
    hud.hidden = YES;
    [hud removeFromSuperview];
    [hud.replicatorLayer removeAllAnimations];
    for (HLayer *layer in hud.replicatorLayer.sublayers){
        [layer removeAllAnimations];
    }
    if(hud.timer)[hud.timer invalidate], hud.timer = nil;
}

- (void)addAnimation:(HLayer *)layer index:(NSUInteger)index{
    
}

@end
