//
//  HImageCollectionViewCell.h
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/5.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
@class HAsset;

typedef NS_ENUM(NSInteger, HImageCollectionViewCellType){
    HImageCollectionViewCellTypeWithCamera,
    HImageCollectionViewCellTypeWithVideo,
    HImageCollectionViewCellTypeWithLibrary
};

@interface HImageCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic, readonly) UIImageView *imageView;

@property (nonatomic) HImageCollectionViewCellType type;
@property (nonatomic, getter=isCellSelected, setter=setCellSelected:) BOOL cellSelected;

@property (nonatomic) CGFloat progress;

- (void)loadAsset:(HAsset *)asset;

@end
