//
//  HAsset.m
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/12.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <BKMediaPicker/HAsset.h>

@implementation HAsset

@synthesize isLocal = _isLocal;

NSString * const NOTI_ICLOUD_DOWN = @"NOTI_ICLOUD_DOWN";
int const NOTI_ICLOUD_DOWD_BEGIN = 0;
int const NOTI_ICLOUD_DOWD_ERROR = 1;
int const NOTI_ICLOUD_DOWD_COMPLETED = 2;

+ (instancetype)asset:(PHAsset *)asset {
    HAsset *hAsset = [[HAsset alloc] init];
    hAsset.asset = asset;
    return hAsset;
}

/**
 *  检测资源是否已加载到本地
 *  使用同步请求尝试获取本地媒体资源
 *  为节省开支，一旦检测到本地已加载完成，则下次调用不再重复检测，直接返回上次检测结果
 *
 *  @return BOOL
 */
- (BOOL)isLocal {
    if(!_isLocal){
        _isLocal = YES;
        if(_asset.mediaType == PHAssetMediaTypeImage){
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.networkAccessAllowed = NO;
            option.synchronous = YES;
            [[PHCachingImageManager defaultManager] requestImageDataForAsset:self.asset options:option resultHandler:^(NSData * imageData, NSString * dataUTI, UIImageOrientation orientation, NSDictionary * info) {
                _isLocal = imageData ? YES : NO;
            }];
        }else if(_asset.mediaType == PHAssetMediaTypeVideo){
            PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
            option.networkAccessAllowed = NO;
            [[PHCachingImageManager defaultManager] requestAVAssetForVideo:self.asset options:option resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
                _isLocal = asset ? YES : NO;
            }];
        }
    }
    return _isLocal;
}

/**
 *  请求高质量图片
 *  同步请求，在获取前应使用 downloadICloudImage 进行图片资源获取
 *
 *  @param completed RequestImageCompleted
 */
- (void)requestHighDefinitionImage:(RequestImageCompleted)completed {
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.networkAccessAllowed = NO;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.synchronous = YES;
    [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:requestOptions resultHandler:^(UIImage *result, NSDictionary * info) {
        if(result){
            if(completed){
                completed(result,nil, info);
            }
        }else{
            if(completed){
                completed(nil,[NSError errorWithDomain:@"失败" code:100 userInfo:nil], nil);
            }
        }
    }];
}

/**
 *  从ICloud下载图片资源
 */
- (void)downloadICloudImage {
    if(_fileType){
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    
    if(!self.isLocal)_isDownloding = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_ICLOUD_DOWN object:self userInfo:@{@"type":@(NOTI_ICLOUD_DOWD_BEGIN)}];
    requestOptions.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info){
        weakSelf.progess = progress;
    };
    
    requestOptions.networkAccessAllowed = YES;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:requestOptions resultHandler:^(UIImage *result, NSDictionary * info) {
        if(result){
            if(weakSelf.isDownloding){
                _isDownloding = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_ICLOUD_DOWN object:self userInfo:@{@"type":@(NOTI_ICLOUD_DOWD_COMPLETED)}];
            }
            NSURL *fileUrl = info[@"PHImageFileURLKey"];
            _fileType = [[fileUrl absoluteString] pathExtension];
        }else{
            if(weakSelf.isDownloding){
                _isDownloding = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTI_ICLOUD_DOWN object:self userInfo:@{@"type":@(NOTI_ICLOUD_DOWD_ERROR)}];
            }
        }
    }];
}

/**
 *  异步请求缩略图
 *  传入所需的最小图片大小可以节省开支和请求时间
 *
 *  @param size      CGSize 所需图片大小
 *  @param completed RequestImageCompleted
 */
- (void)requestThumbnailSize:(CGSize)size completed:(RequestImageCompleted)completed {
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:size contentMode:PHImageContentModeAspectFill options:requestOptions resultHandler:^(UIImage *result, NSDictionary * info) {
        if(completed){
            if(result){
                completed(result,nil, info);
            }else{
                completed(nil,nil,nil);
            }
        }
    }];
}

/**
 *  请求视频资源
 *  返回视频资源的AVAsset
 *
 *  @param completed RequestVideoCompleted
 */
- (void)requestVideoCompleted:(RequestVideoCompleted)completed {
    PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
    requestOptions.networkAccessAllowed = NO;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:requestOptions resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        if(completed){
            if(asset){
                completed(asset,nil, info);
            }else{
                completed(nil,nil,nil);
            }
        }
    }];
}

@end
