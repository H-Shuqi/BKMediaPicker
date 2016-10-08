//
//  HImagePickerViewModel.h
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/11.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <BKMediaPicker/HImagePickerController.h>
#import <BKMediaPicker/HAsset.h>

/**
 *  选择器视图模型
 *  包含选择器处理逻辑
 *  
 *  将选择的图片及视频写入本地缓存目录，返回FilePath
 *  缓存目录在下一次调用时清空
 *
 *  自动处理图片Exif信息，缓存旋转后的图片
 *  自动处理视频Rotation信息，矫正视频旋转
 *  使用AVAssetExportSession转码为mp4格式，进行AVAssetExportPresetMediumQuality压缩
 */
@interface HImagePickerViewModel : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<HAsset *> *allAlesst;
@property (nonatomic, strong, readonly) NSMutableArray<HAsset *> *selectedAlesst;
@property (nonatomic) HImagePickType type;
@property (nonatomic) NSUInteger maxLimit;
@property (nonatomic) BOOL canCommit;

@property (nonatomic, strong) NSString *tempPath;//缓存地址

/**
 *  根据选择器类型初始化
 *
 *  @param type HImagePickType
 *
 *  @return HImagePickerViewModel
 */
- (instancetype)initWithType:(HImagePickType)type;

/**
 *  选择
 *
 *  @param asset HAsset
 */
- (void)selectedAssest:(HAsset *)asset;

/**
 *  移除
 *
 *  @param asset HAsset
 */
- (void)removeAssest:(HAsset *)asset;

/**
 *  图库图片转储
 *
 *  @param completed void(^)(NSArray<NSString *> *filePathArray)
 */
- (void)archiveSelecteds:(void(^)(NSArray<NSString *> *filePathArray))completed;

/**
 *  单张图片转储
 *
 *  @param image     UIImage
 *  @param completed void(^)(NSString *filePath)
 */
- (void)archiveImage:(UIImage *)image completed:(void(^)(NSString *filePath))completed;

/**
 *  视频转码压缩
 *
 *  @param inputURL NSURL
 *  @param handler  block
 */
- (void)lowQuailtyWithInputURL:(NSURL *)inputURL blockHandler:(void (^)(AVAssetExportSession *session, NSURL *compressionVideoURL))handler;

/**
 *  清除缓存目录
 */
- (void)clearTempFile;

@end
