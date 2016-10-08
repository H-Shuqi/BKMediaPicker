//
//  BKMediaPicker.h
//  BKMediaPicker
//
//  Created by 胡舒琦 on 16/8/24.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BKMediaPickerType){
    BKMediaPickerTypeWithImage = 0,
    BKMediaPickerTypeWithVideo = 1
};

@protocol BKMediaPickerCallBackDelegate <NSObject>

/**
 *  向JS发送选择完成消息
 *  用户选择完成后，点击确定调用
 *
 *  @param filePathArray NSArray<NSString *> 选择结果 文件路径数组
 */
- (void)sendFilePathArray:(NSArray<NSString *> *)filePathArray;

/**
 *  向JS发送选择取消消息
 *  用户点击确定时选择内容为空，或点击取消选择时调用
 */
- (void)sendCancel;

@end

@interface BKMediaPicker : NSObject

@property (nonatomic, strong) id<BKMediaPickerCallBackDelegate> delegate;
@property (nonatomic) BKMediaPickerType type;

+ (instancetype)mediaPicker;

/**
 *  弹出选择器
 *
 *  @param type          BKMediaPickerType 类型 图片/视频
 *  @param limitMaxCount NSUInteger 最大选择限制
 */
- (void)showPickerWithType:(BKMediaPickerType)type limitMaxCount:(NSUInteger)limitMaxCount;

/**
 *  收回选择器
 *  自动收回，一般无需调用
 */
- (void)dismiss;

@end
