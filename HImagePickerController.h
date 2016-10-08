//
//  HImagePickerController.h
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/5.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class HImagePickerViewModel;
@class HImagePickerController;

typedef NS_ENUM(NSInteger, HImagePickType){
    HImagePickTypeWithPhoto,
    HImagePickTypeWithVideo
};

@protocol HImagePickerDelegate <NSObject>

@required
/**
 *  选择完成
 *
 *  @param imagePicker HImagePickerController
 *  @param filePaths   NSArray<NSString *> 选择的媒体文件缓存路径列表
 */
- (void)imagePickerConfirmWithController:(HImagePickerController *)imagePicker filePaths:(NSArray<NSString *> *)filePaths;
/**
 *  用户取消
 *
 *  @param imagePicker HImagePickerController
 */
- (void)imagePickerCancelWithController:(HImagePickerController *)imagePicker;

@optional
/**
 *  图库读取失败
 *
 *  @param imagePicker HImagePickerController
 *  @param error       NSError
 */
- (void)imagePickerErrorWithController:(HImagePickerController *)imagePicker error:(NSError *)error;

@end

/**
 *  单例实现的媒体选取器
 *
 *  使用PhotosKit，兼容iOS8以上系统
 *  为能返回文件路径用作上传，每次选择完成将会把选择的文件写入本地缓存，再返回缓存地址
 *  缓存目录在程序启动时做一次清空处理
 */
@interface HImagePickerController : UIViewController

+ (instancetype)imagePickerController;

@property (nonatomic, strong) HImagePickerViewModel *viewModel;
@property (nonatomic, weak) id<HImagePickerDelegate> delegate;
@property (nonatomic) NSInteger selectedMax;
@property (nonatomic) HImagePickType type;

- (instancetype)initWithType:(HImagePickType)type;

/**
 *  清空文件缓存目录
 */
- (void)clearFileDocument;

@end
