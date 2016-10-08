//
//  HLodingHUD.h
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/16.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  加载ActionView，使用Core Animation框架，效果为几个小球弹跳转动
 *  小球最多6个，最少1个
 *  使用链式语法设置属性
 *  属性设置必须在初始化方法之内，允许多次设置，在下次show时生效
 *  间歇 使用Timer控制，长时间运行可能有偏移
 */
@interface HLodingHUD : UIView

/**
 *  初始化
 *
 *  @param settingHeader void(^)(HLodingHUD *hud)
 */
+ (void)hudWithSetting:(void(^)(HLodingHUD *hud))settingHeader;

/**
 *  个数
 */
- (HLodingHUD *(^)(NSUInteger itemCount))itemCount;

/**
 *  大小
 */
- (HLodingHUD *(^)(CGFloat itemSize))itemSize;

/**
 *  动画速度
 */
- (HLodingHUD *(^)(CGFloat duration))duration;

/**
 *  遮盖颜色
 */
- (HLodingHUD *(^)(UIColor *bgColor))bgColor;

/**
 *  间歇
 */
- (HLodingHUD *(^)(BOOL hasInterval))hasInterval;

/**
 *  弹跳
 */
- (HLodingHUD *(^)(BOOL hasBounce))hasBounce;

/**
 *  弹跳高度
 */
- (HLodingHUD *(^)(CGFloat positionHeight))positionHeight;

+ (void)show;

+ (void)dismiss;

@end
