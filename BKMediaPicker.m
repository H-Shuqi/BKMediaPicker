//
//  BKMediaPicker.m
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/23.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <BKMediaPicker/BKMediaPicker.h>
#import <BKMediaPicker/HImagePickerController.h>

@interface BKMediaPicker () <HImagePickerDelegate>

@end

@implementation BKMediaPicker

static BKMediaPicker *mediaPicker;

+ (instancetype)mediaPicker {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediaPicker = [[BKMediaPicker alloc] init];
    });
    return mediaPicker;
}

/**
 *  弹出选择器
 *
 *  @param type          BKMediaPickerType 类型 图片/视频
 *  @param limitMaxCount NSUInteger 最大选择限制
 */
- (void)showPickerWithType:(BKMediaPickerType)type limitMaxCount:(NSUInteger)limitMaxCount {
    HImagePickerController *imagePickController = [HImagePickerController imagePickerController];
    if(imagePickController.isViewLoaded && imagePickController.view.window){
        return;
    }
    imagePickController.selectedMax = limitMaxCount;
    imagePickController.delegate = self;
    imagePickController.type = type == BKMediaPickerTypeWithVideo ? HImagePickTypeWithVideo : HImagePickTypeWithPhoto;
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:imagePickController];
    navC.navigationBar.barTintColor = [UIColor colorWithRed:44/255.f green:152/255.f blue:240/255.f alpha:1];
    UIWindow *windoe = [[UIApplication sharedApplication].delegate window];
    [windoe.rootViewController presentViewController:navC animated:YES completion:^{
        
    }];
}

- (void)showPickerWithType:(BKMediaPickerType)type {
    [self showPickerWithType:type limitMaxCount:15];
}

- (void)showPicker {
    [self showPickerWithType:BKMediaPickerTypeWithImage limitMaxCount:15];
}

/**
 *  收回选择器
 *  自动收回，一般无需调用
 */
- (void)dismiss {
    HImagePickerController *imagePickController = [HImagePickerController imagePickerController];
    if(!imagePickController.isViewLoaded || !imagePickController.view.window){
        return;
    }
    [imagePickController.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - ImagePicker Delegate
- (void)imagePickerConfirmWithController:(HImagePickerController *)imagePicker filePaths:(NSArray<NSString *> *)filePaths {
    if(filePaths && filePaths.count > 0){
        if(self.delegate && [self.delegate respondsToSelector:@selector(sendCancel)]){
            [self.delegate sendCancel];
        }
    }else if(self.delegate && [self.delegate respondsToSelector:@selector(sendFilePathArray:)]){
        [self.delegate sendFilePathArray:filePaths];
    }
}

- (void)imagePickerCancelWithController:(HImagePickerController *)imagePicker {
    if(self.delegate && [self.delegate respondsToSelector:@selector(sendCancel)]){
        [self.delegate sendCancel];
    }
}

@end
