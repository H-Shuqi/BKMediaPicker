//
//  HAsset.h
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/12.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <Photos/Photos.h>

typedef void(^RequestImageCompleted)(UIImage *image, NSError *error, NSDictionary *info);
typedef void(^RequestVideoCompleted)(AVAsset *asset, NSError *error, NSDictionary *info);

@interface HAsset : NSObject

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) NSString *fileType;
@property (nonatomic) CGFloat progess;
@property (nonatomic, readonly) BOOL isLocal;
@property (nonatomic, readonly) BOOL isDownloding;

/**
 *  根据PHAsset创建HAsset
 *
 *  @param asset PHAsset
 *
 *  @return HAsset
 */
+ (instancetype)asset:(PHAsset *)asset;

/**
 *  从iCloud下载图片资源
 *  用于预加载图片资源
 */
- (void)downloadICloudImage;

/**
 *  请求高质量图片 
 *  同步请求，在获取前应使用 downloadICloudImage 进行图片资源获取
 *
 *  @param completed RequestImageCompleted
 */
- (void)requestHighDefinitionImage:(RequestImageCompleted)completed;

/**
 *  异步请求缩略图
 *  传入所需的最小图片大小可以节省开支和请求时间
 *
 *  @param size      CGSize 所需图片大小
 *  @param completed RequestImageCompleted
 */
- (void)requestThumbnailSize:(CGSize)size completed:(RequestImageCompleted)completed;

/**
 *  请求视频资源
 *  返回视频资源的AVAsset
 *
 *  @param completed RequestVideoCompleted
 */
- (void)requestVideoCompleted:(RequestVideoCompleted)completed;

@end
