//
//  HImagePickerViewModel.m
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/11.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <BKMediaPicker/HImagePickerViewModel.h>

@implementation HImagePickerViewModel

extern NSString * NOTI_ICLOUD_DOWN;
extern int NOTI_ICLOUD_DOWD_BEGIN;
extern int NOTI_ICLOUD_DOWD_ERROR;
extern int NOTI_ICLOUD_DOWD_COMPLETED;

- (instancetype)init {
    self = [super init];
    if (self) {
        _allAlesst = [NSMutableArray arrayWithArray:[self allPhotos]];
        _selectedAlesst = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudDownlodNoti:) name:NOTI_ICLOUD_DOWN object:nil];
        _tempPath = [NSString stringWithFormat:@"%@PhotosSelectTemp/",NSTemporaryDirectory()];
    }
    return self;
}

- (instancetype)initWithType:(HImagePickType)type {
    self = [super init];
    if (self) {
        _type = type;
        if(_type == HImagePickTypeWithVideo){
            _allAlesst = [NSMutableArray arrayWithArray:[self allVideo]];
            _maxLimit = 1;
        }else{
            _allAlesst = [NSMutableArray arrayWithArray:[self allPhotos]];
        }
        _selectedAlesst = [NSMutableArray array];
        _tempPath = [NSString stringWithFormat:@"%@PhotosSelectTemp/",NSTemporaryDirectory()];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearTempFile) name:UIApplicationDidFinishLaunchingNotification object:nil];
    }
    return self;
}

/**
 *  更改选择器类型并拉取资源
 *
 *  @param type HImagePickType
 */
- (void)setType:(HImagePickType)type {
    _type = type;
    if (type == HImagePickTypeWithPhoto) {
        [_allAlesst setArray:[self allPhotos]];
    }else{
        [_allAlesst setArray:[self allVideo]];
        _maxLimit = 1;
    }
}

- (void)setMaxLimit:(NSUInteger)maxLimit {
    _maxLimit = maxLimit;
    if (_type == HImagePickTypeWithVideo || _maxLimit < 1) {
        _maxLimit = 1;
    }
}

#pragma mark - 拉取图库资源
/**
 *  获取图库所有图片资源
 *
 *  @return NSArray<HAsset *>
 */
- (NSArray<HAsset *> *)allPhotos {
    NSMutableArray<HAsset *> *array = [NSMutableArray array];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    for (NSInteger i = 0; i < assetsFetchResults.count; i++) {
        PHAsset *asset = assetsFetchResults[i];
        if(asset.mediaType == PHAssetMediaTypeImage){
            [array addObject:[HAsset asset:asset]];
        }
    }
    return array;
}
/**
 *  获取图库所有视频
 *
 *  @return NSArray<HAsset *>
 */
- (NSArray<HAsset *> *)allVideo {
    NSMutableArray<HAsset *> *array = [NSMutableArray array];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    for (NSInteger i=0; i < assetsFetchResults.count; i++) {
        PHAsset *asset = assetsFetchResults[i];
        if(asset.mediaType == PHAssetMediaTypeVideo){
            [array addObject:[HAsset asset:asset]];
        }
    }
    return array;
}

#pragma mark - 选择/移除/iCloud下载/刷新界面
- (void)selectedAssest:(HAsset *)asset {
    [self.selectedAlesst addObject:asset];
    [self chackCanComit];
}
- (void)removeAssest:(HAsset *)asset {
    [self.selectedAlesst removeObject:asset];
    [self chackCanComit];
}

- (void)iCloudDownlodNoti:(NSNotification *)noti {
    [self chackCanComit];
}

- (void)chackCanComit {
    BOOL haveTemp = NO;
    for (HAsset *asset in _selectedAlesst){
        if(asset.isDownloding){
            haveTemp = YES;
            break;
        }
    }
    self.canCommit = !haveTemp;
}

#pragma mark - 图像文件转存
/**
 *  图库图片转储
 *
 *  @param completed void(^)(NSArray<NSString *> *filePathArray)
 */
- (void)archiveSelecteds:(void(^)(NSArray<NSString *> *filePathArray))completed {
    if(self.selectedAlesst.count <= 0){
        if (completed){
            completed(@[]);
            return;
        }
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *filePathArray = [NSMutableArray array];
        for (HAsset *asset in weakSelf.selectedAlesst){
            [asset requestHighDefinitionImage:^(UIImage *image, NSError *error, NSDictionary *info) {
                if(!error){
                    NSString *fileName = [NSString stringWithFormat:@"%@.%@", [weakSelf retStringWithBitNum:8], asset.fileType];
                    NSString *filePath = [NSString stringWithFormat:@"%@%@",weakSelf.tempPath,fileName];
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    
                    if(![fileManager fileExistsAtPath:weakSelf.tempPath]){
                        [fileManager createDirectoryAtPath:weakSelf.tempPath withIntermediateDirectories:YES attributes:nil error:nil];
                        NSLog(@"创建Tmp目录 %@",weakSelf.tempPath);
                    }
                    if(![fileManager fileExistsAtPath:filePath]){
                        BOOL b = [fileManager createFileAtPath:filePath contents:UIImagePNGRepresentation(image) attributes:nil];
                        NSLog(@"写入文件%@! %@", b?@"成功":@"失败", fileName);
                        if(b){
                            [filePathArray addObject:filePath];
                        }
                    }
                }
            }];
        }
        if(completed){
            dispatch_async(dispatch_get_main_queue(), ^{
                completed(filePathArray);
            });
        }
    });
}

/**
 *  单张图片转储
 *
 *  @param image     UIImage
 *  @param completed void(^)(NSString *filePath)
 */
- (void)archiveImage:(UIImage *)image completed:(void(^)(NSString *filePath))completed {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *fileName = [NSString stringWithFormat:@"%@.png", [weakSelf retStringWithBitNum:8]];
        NSString *filePath = [NSString stringWithFormat:@"%@%@",weakSelf.tempPath,fileName];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if(![fileManager fileExistsAtPath:weakSelf.tempPath]){
            [fileManager createDirectoryAtPath:weakSelf.tempPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        if(![fileManager fileExistsAtPath:filePath]){
            UIImage *normalizedImage = [self normalizedImage:image];
            BOOL b = [fileManager createFileAtPath:filePath contents:UIImagePNGRepresentation(normalizedImage) attributes:nil];
            if(b){
                if(completed){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completed(filePath);
                    });
                }
            }
        }
    });
}

/**
 *  图片方向修正
 *
 *  @return UIImage
 */
- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = nil;
    return normalizedImage;
}

#pragma mark - 视频矫正及缓存写入
/**
 *  视频写入
 *
 *  @param asset  PHAsset
 *  @param result void(^)(NSString *filePath, NSString *fileName)
 */
- (void)videoPathFromPHAsset:(PHAsset *)asset Complete:(void(^)(NSString *filePath, NSString *fileName))result {
    NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
    PHAssetResource *resource;
    
    for (PHAssetResource *assetRes in assetResources) {
        if (assetRes.type == PHAssetResourceTypePairedVideo ||
            assetRes.type == PHAssetResourceTypeVideo) {
            resource = assetRes;
        }
    }
    NSString *fileName = @"tempAssetVideo.mov";
    if (resource.originalFilename) {
        fileName = resource.originalFilename;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:self.tempPath]) {
        [fileManager createDirectoryAtPath:self.tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",self.tempPath, fileName];

        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        
        
        
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
                                                                    toFile:[NSURL fileURLWithPath:filePath]
                                                                   options:nil
                                                         completionHandler:^(NSError *error) {
                                                             if (error) {
                                                                 result(nil, nil);
                                                             } else {
                                                                 result(filePath, fileName);
                                                             }
                                                         }];
    } else {
        result(nil, nil);
    }
}

/**
 *  获取视频方向信息
 *
 *  @param url NSURL
 *
 *  @return NSUInteger
 */
+ (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url {
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    
    return degress;
}

/**
 *  获取视频旋转矫正数据信息
 *
 *  @param asset AVAsset
 *
 *  @return AVMutableVideoComposition
 */
- (AVMutableVideoComposition *)getVideoComposition:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if((t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) ||
           (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)){
            videoSize = CGSizeMake(videoSize.height, videoSize.width);
        }
    }
    
    composition.naturalSize    = videoSize;
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMakeWithSeconds( 1 / videoTrack.nominalFrameRate, 600);
    
    AVMutableCompositionTrack *compositionVideoTrack;
    compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInst setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    return videoComposition;
}

/**
 *  视频转码压缩
 *
 *  @param inputURL NSURL
 *  @param handler  block
 */
- (void)lowQuailtyWithInputURL:(NSURL *)inputURL blockHandler:(void (^)(AVAssetExportSession *session, NSURL *compressionVideoURL))handler {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    NSString *path = self.tempPath;

    NSFileManager *fileManage = [[NSFileManager alloc] init];
    if(![fileManage fileExistsAtPath:path]){
        [fileManage createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if([fileManage fileExistsAtPath:[NSString stringWithFormat:@"%@VideoCompressionTemp.mp4",path]]){
        [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@VideoCompressionTemp.mp4",path] error:nil];
    }
    
    NSURL *compressionVideoURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@VideoCompressionTemp.mp4",path]];
    session.outputURL = compressionVideoURL;
    session.outputFileType = AVFileTypeMPEG4;
    session.shouldOptimizeForNetworkUse = YES;
    session.videoComposition = [self getVideoComposition:asset];
    [session exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(),^{
            switch ([session status]) {
                case AVAssetExportSessionStatusFailed:{
                    NSLog(@"Export failed: %@ : %@", [[session error] localizedDescription], [session error]);
                    handler(session, nil);
                    break;
                }case AVAssetExportSessionStatusCancelled:{
                    NSLog(@"Export canceled");
                    handler(session, nil);
                    break;
                }case AVAssetExportSessionStatusCompleted: {
                    handler(session,compressionVideoURL);
                    break;
                }default:{
                    handler(session,nil);
                    break;
                }
            }
        });
    }];
}

#pragma mark - 清除缓存文件目录
/**
 *  清除Temp文件夹
 */
- (void)clearTempFile {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:_tempPath error:nil];
    });
    NSLog(@"\n\n ********* 清空文件!!!!!!!\n\n");
}

#pragma mark -
/**
 *  随机生成bitNum位字符串
 *
 *  @return NSString
 */
- (NSString *)retStringWithBitNum:(NSUInteger)bitNum {
    if(bitNum == 0)return nil;
    char data[bitNum];
    for (int x=0;x<bitNum;data[x++] = (char)('A' + (arc4random_uniform(26))));
    return [[NSString alloc] initWithBytes:data length:bitNum encoding:NSUTF8StringEncoding];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
