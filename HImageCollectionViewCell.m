//
//  HImageCollectionViewCell.m
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/5.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <BKMediaPicker/HImageCollectionViewCell.h>
#import <BKMediaPicker/HProgressView.h>
#import <BKMediaPicker/HAsset.h>

@interface HImageCollectionViewCell()
@property (strong, nonatomic) UIImageView *selectedImageView;
@property (strong, nonatomic) UIImageView *cameraImageView;
@property (strong, nonatomic) UILabel *cameraLabel;
@property (strong, nonatomic) HProgressView *progressView;
@property (strong, nonatomic) UILabel *cloudLabel;

@property (nonatomic, strong) HAsset *asset;
@end

#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

@implementation HImageCollectionViewCell

@synthesize cellSelected = _cellSelected;

extern NSString * NOTI_ICLOUD_DOWN;
extern int NOTI_ICLOUD_DOWD_BEGIN;
extern int NOTI_ICLOUD_DOWD_ERROR;
extern int NOTI_ICLOUD_DOWD_COMPLETED;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _cellSelected = NO;
        
        self.contentView.autoresizingMask = YES;
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:_imageView];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.translatesAutoresizingMaskIntoConstraints = YES;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _cameraImageView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame)-53.25)/2, (CGRectGetHeight(frame)-42)/2-10, 53.25, 42)];
        [self.contentView addSubview:_cameraImageView];
        _cameraImageView.image = [UIImage imageNamed:@"BKMediaPicker.bundle/camera"];
        _cameraImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                            UIViewAutoresizingFlexibleRightMargin |
                                            UIViewAutoresizingFlexibleBottomMargin |
                                            UIViewAutoresizingFlexibleTopMargin;
        
        _cameraLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_cameraImageView.frame), CGRectGetWidth(frame), 30)];
        [self.contentView addSubview:_cameraLabel];
        _cameraLabel.text = @"拍照";
        _cameraLabel.textColor = [UIColor whiteColor];
        _cameraLabel.font = [UIFont boldSystemFontOfSize:14];
        _cameraLabel.textAlignment = NSTextAlignmentCenter;
        _cameraLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleBottomMargin |
                                        UIViewAutoresizingFlexibleTopMargin;

        _progressView = [[HProgressView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:_progressView];
        [self.contentView bringSubviewToFront:_progressView];
        
        _cloudLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, CGRectGetHeight(frame)-18, CGRectGetWidth(frame)-16, 20)];
        [_progressView addSubview:_cloudLabel];
        _cloudLabel.font = [UIFont systemFontOfSize:10];
        _cloudLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
        _cloudLabel.text = @"iCloud";
        
        _selectedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame)-28, 8, 20, 20)];
        [self.contentView addSubview:_selectedImageView];
        _selectedImageView.image = [UIImage imageNamed:@"BKMediaPicker.bundle/select"];
        _selectedImageView.translatesAutoresizingMaskIntoConstraints = YES;
        _selectedImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudDownlodNoti:) name:NOTI_ICLOUD_DOWN object:nil];
    }
    return self;
}

- (void)setType:(HImageCollectionViewCellType)type {
    _type = type;
    if (_type != HImageCollectionViewCellTypeWithLibrary) {
        if(_type == HImageCollectionViewCellTypeWithVideo){
            _cameraLabel.text = @"拍摄";
        }else if(_type == HImageCollectionViewCellTypeWithCamera){
            _cameraLabel.text = @"拍照";
        }
        _selectedImageView.hidden = YES;
        _imageView.hidden = YES;
        _imageView.image = nil;
        _cameraImageView.hidden = NO;
        _cameraLabel.hidden = NO;
        _progressView.hidden = YES;
        self.contentView.backgroundColor = [UIColor orangeColor];
    }else{
        _selectedImageView.hidden = NO;
        _imageView.hidden = NO;
        _cameraImageView.hidden = YES;
        _cameraLabel.hidden = YES;
        _progressView.hidden = YES;
        self.contentView.backgroundColor = [UIColor whiteColor];
    }
}

- (void)loadAsset:(HAsset *)asset {
    if(asset == _asset){
        return;
    }
    
    if(_asset){
        @try {
            [_asset removeObserver:self forKeyPath:@"progess"];
//            NSLog(@"移除监听 : %@",_asset);
        } @catch (NSException *exception) {
//            NSLog(@"Remove Cell S Err : %@",exception);
        } @finally {
            _asset = nil;
        }
    }
    
    _asset = asset;
    if(asset.asset.mediaType == PHAssetMediaTypeImage){
        [asset requestThumbnailSize:self.bounds.size completed:^(UIImage *image, NSError *error, NSDictionary *info) {
            self.imageView.image = image;
        }];
    }else{
        [asset requestThumbnailSize:self.bounds.size completed:^(UIImage *image, NSError *error, NSDictionary *info) {
            self.imageView.image = image;
        }];
    }
    BOOL local = _asset.isLocal;
    _progressView.hidden = local;
    if(!local){
        [self setProgress:_asset.progess];
        [_asset addObserver:self forKeyPath:@"progess" options:NSKeyValueObservingOptionNew context:nil];
//        NSLog(@"添加监听 : %@",_asset);
    }else{
        
    }
}



- (void)setProgress:(CGFloat)progress {
    _progressView.progress = progress;
}

- (CGFloat)progress {
    return _progressView.progress;
}

- (void)setCellSelected:(BOOL)selected {
    _cellSelected = selected;
    if(_cellSelected){
        _selectedImageView.image = [UIImage imageNamed:@"BKMediaPicker.bundle/selected"];
    }else{
        _selectedImageView.image = [UIImage imageNamed:@"BKMediaPicker.bundle/select"];
    }
}

- (BOOL)isCellSelected {
    return _cellSelected;
}

- (void)iCloudDownlodNoti:(NSNotification *)noti {
    HAsset *noAsset = noti.object;
    if (noAsset == self.asset) {
        int type = [noti.userInfo[@"type"] intValue];
        if (type == NOTI_ICLOUD_DOWD_ERROR) {
            self.progressView.hidden = NO;
            [self setProgress:0];
        }else if(type == NOTI_ICLOUD_DOWD_COMPLETED){
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:2 animations:^{
                    self.progressView.hidden = YES;
                }];
            });
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    NSNumber *progressNum = change[@"new"];
    CGFloat progress = [progressNum floatValue];
    NSLog(@"ProgressFloat : %.3f", progress);
    [self setProgress:progress];
}

- (void)dealloc {
    if(_asset){
        @try {
            [_asset removeObserver:self forKeyPath:@"progess"];
        } @catch (NSException *exception) {
//            NSLog(@"RemoveO Cell D Err : %@",exception.reason);
        } @finally {
            _asset = nil;
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
