//
//  HImagePickerController.m
//  HImagePickerController
//
//  Created by 胡舒琦 on 16/8/5.
//  Copyright © 2016年 北科天翼. All rights reserved.
//

#import <BKMediaPicker/HImagePickerController.h>
#import <BKMediaPicker/HImageCollectionViewCell.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <BKMediaPicker/HImagePickerViewModel.h>
#import <BKMediaPicker/HLodingHUD.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface HImagePickerController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIButton *confirmButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIImagePickerController *picker;
@end

#define SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@implementation HImagePickerController

static HImagePickerController *imagePickerController;
static int interval = 2;//图片间距

+ (instancetype)imagePickerController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imagePickerController = [[HImagePickerController alloc] init];
    });
    return imagePickerController;
}

+ (instancetype)imagePickerControllerWithType:(HImagePickType)type {
    HImagePickerController *imagePickerController = [[HImagePickerController alloc] init];
    return imagePickerController;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _viewModel = [[HImagePickerViewModel alloc] init];
    }
    return self;
}

- (instancetype)initWithType:(HImagePickType)type {
    self = [super init];
    if (self) {
        _type = type;
        _viewModel = [[HImagePickerViewModel alloc] initWithType:type];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if(!self.view)self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.navigationItem.title = self.type == HImagePickTypeWithVideo ? @"选择视频" : @"选择图片";
    
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[HImageCollectionViewCell class] forCellWithReuseIdentifier:@"imageCell"];
    _collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_collectionView];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    _bottomView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_bottomView];
    _bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:_bottomView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    NSLayoutConstraint *joinConstraint = [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *htightConstraint = [NSLayoutConstraint constraintWithItem:_bottomView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_bottomView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_collectionView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    
    [self.view addConstraint:topConstraint];
    [self.view addConstraint:leftConstraint];
    [self.view addConstraint:rightConstraint];
    [self.view addConstraint:joinConstraint];
    [self.view addConstraint:bottomConstraint];
    [self.view addConstraint:htightConstraint];
    [self.view addConstraint:widthConstraint];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectZero];
    lineView.translatesAutoresizingMaskIntoConstraints = NO;
    lineView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [_bottomView addSubview:lineView];
    
    CGFloat onepix = 1.0f/[UIScreen mainScreen].scale;
    NSLayoutConstraint *lineTopConstraint = [NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *lineLeftConstraint = [NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *lineRightConstraint = [NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    NSLayoutConstraint *lineHeightConstraint = [NSLayoutConstraint constraintWithItem:lineView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:onepix];
    [_bottomView addConstraint:lineTopConstraint];
    [_bottomView addConstraint:lineLeftConstraint];
    [_bottomView addConstraint:lineRightConstraint];
    [_bottomView addConstraint:lineHeightConstraint];
    
    _confirmButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_confirmButton setTitle:@"确认" forState:UIControlStateNormal];
    [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_confirmButton setBackgroundImage:imageWithColor(colorWithRGB(72,198,37,1)) forState:UIControlStateNormal];
    [_confirmButton setBackgroundImage:imageWithColor(colorWithRGB(160, 160, 160, 1)) forState:UIControlStateDisabled];
    _confirmButton.layer.cornerRadius = 6;
    _confirmButton.clipsToBounds = YES;
    _confirmButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [_confirmButton addTarget:self action:@selector(confirmAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_confirmButton];
    
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_cancelButton setBackgroundImage:imageWithColor(colorWithRGB(253,126,35,1)) forState:UIControlStateNormal];
    _cancelButton.layer.cornerRadius = 6;
    _cancelButton.clipsToBounds = YES;
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_cancelButton];
    
    CGFloat space = SCREEN_HEIGHT * 0.06;
    NSLayoutConstraint *confirmWidthEqConstraint = [NSLayoutConstraint constraintWithItem:_confirmButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_cancelButton attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    NSLayoutConstraint *confirmTopConstraint = [NSLayoutConstraint constraintWithItem:_confirmButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeTop multiplier:1 constant:8];
    NSLayoutConstraint *confirmBottomConstraint = [NSLayoutConstraint constraintWithItem:_confirmButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeBottom multiplier:1 constant:-8];
    NSLayoutConstraint *confirmLeftConstraint = [NSLayoutConstraint constraintWithItem:_confirmButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeLeft multiplier:1 constant:space];
    NSLayoutConstraint *confirmSpaceConstraint = [NSLayoutConstraint constraintWithItem:_confirmButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_cancelButton attribute:NSLayoutAttributeLeft multiplier:1 constant:-space];
    NSLayoutConstraint *cancelRightConstraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_bottomView attribute:NSLayoutAttributeRight multiplier:1 constant:-space];
    NSLayoutConstraint *cancelHeightConstraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_confirmButton attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    NSLayoutConstraint *cancelCenterXConstraint = [NSLayoutConstraint constraintWithItem:_cancelButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_confirmButton attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    [_bottomView addConstraint:confirmWidthEqConstraint];
    [_bottomView addConstraint:confirmTopConstraint];
    [_bottomView addConstraint:confirmBottomConstraint];
    [_bottomView addConstraint:confirmLeftConstraint];
    [_bottomView addConstraint:confirmSpaceConstraint];
    [_bottomView addConstraint:cancelRightConstraint];
    [_bottomView addConstraint:cancelHeightConstraint];
    [_bottomView addConstraint:cancelCenterXConstraint];
    
    [self.viewModel addObserver:self forKeyPath:@"canCommit" options:NSKeyValueObservingOptionNew context:nil];
    
    [HLodingHUD hudWithSetting:^(HLodingHUD *hud) {
        hud.itemCount(4).itemSize(30).duration(0.4).positionHeight(30).hasInterval(NO).hasBounce(YES);
    }];
    
    [self.viewModel clearTempFile];
}

- (void)viewDidAppear:(BOOL)animated {
    if(self.selectedMax > 0)[self refreshSelectedCount];
    
    PHAuthorizationStatus author = [PHPhotoLibrary authorizationStatus];
    if(author == PHAuthorizationStatusRestricted || author == PHAuthorizationStatusDenied){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"相册访问已被禁止，请到设置中打开权限！" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:NULL];
        }]];
        [self presentViewController:alert animated:YES completion:NULL];
    }
}

- (void)setType:(HImagePickType)type {
    _type = type;
    self.viewModel.type = type;
    [self.collectionView reloadData];
}

- (void)setSelectedMax:(NSInteger)selectedMax {
    self.viewModel.maxLimit = selectedMax;
}

- (NSInteger)selectedMax {
    return self.viewModel.maxLimit;
}

- (void)clearFileDocument {
    [self.viewModel clearTempFile];
}

#pragma mark - Action
- (void)confirmAction:(UIButton *)sender {
    [HLodingHUD show];
    __weak typeof(self) weakSelf = self;
    if(_delegate && [_delegate respondsToSelector:@selector(imagePickerConfirmWithController:filePaths:)]){
        if(self.type == HImagePickTypeWithVideo){
            HAsset *asset = [weakSelf.viewModel.selectedAlesst firstObject];
            [asset requestVideoCompleted:^(AVAsset *asset, NSError *error, NSDictionary *info) {
                if(asset){
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    [weakSelf.viewModel lowQuailtyWithInputURL:urlAsset.URL blockHandler:^(AVAssetExportSession *session, NSURL *compressionVideoURL) {
                        NSString *filePath = [compressionVideoURL absoluteString];
                        [HLodingHUD dismiss];
                        [weakSelf.navigationController dismissViewControllerAnimated:YES completion:^{
                            [weakSelf.delegate imagePickerConfirmWithController:weakSelf filePaths:@[filePath]];
                            [self clearSelected];
                        }];
                    }];
                }
            }];
        }else{
            [weakSelf.viewModel archiveSelecteds:^(NSArray<NSString *> *filePathArray) {
                [HLodingHUD dismiss];
                [weakSelf.navigationController dismissViewControllerAnimated:YES completion:^{
                    [weakSelf.delegate imagePickerConfirmWithController:weakSelf filePaths:filePathArray];
                    [self clearSelected];
                }];
            }];
        }
    }
}

- (void)cancelAction:(UIButton *)sender {
    if(_delegate && [_delegate respondsToSelector:@selector(imagePickerCancelWithController:)]){
        [_delegate imagePickerCancelWithController:self];
        [self clearSelected];
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)refreshSelectedCount {
    NSString *confirmBtnTitle = [NSString stringWithFormat:@"(%lu/%ld) 确认", (unsigned long)_viewModel.selectedAlesst.count, (long)self.selectedMax];
    [_confirmButton setTitle:confirmBtnTitle forState:UIControlStateNormal];
}

- (void)clearSelected {
    [self.viewModel.selectedAlesst removeAllObjects];
    [self.collectionView reloadData];
    [self refreshSelectedCount];
}

#pragma mark - ImagePickerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [HLodingHUD show];
        NSLog(@"当前线程—MainThread : %@",[NSThread isMultiThreaded]?@"YES":@"NO");
        __weak typeof(self) weakSelf = self;
        [self.viewModel archiveImage:image completed:^(NSString *filePath) {
            [HLodingHUD dismiss];
            if(weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(imagePickerConfirmWithController:filePaths:)]){
                [weakSelf.delegate imagePickerConfirmWithController:self filePaths:@[filePath]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [picker dismissViewControllerAnimated:NO completion:^{
                    [weakSelf.navigationController dismissViewControllerAnimated:YES completion:NULL];
                }];
            });
        }];
    }else if([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
        [HLodingHUD show];
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];//视频路径
        [self.viewModel lowQuailtyWithInputURL:url blockHandler:^(AVAssetExportSession *session, NSURL *compressionVideoURL) {
            [HLodingHUD dismiss];
            [picker dismissViewControllerAnimated:NO completion:^{
                [self.navigationController dismissViewControllerAnimated:NO completion:NULL];
                if(compressionVideoURL){
                    NSString *filePath = [compressionVideoURL absoluteString];
                    if(self.delegate && [self.delegate respondsToSelector:@selector(imagePickerConfirmWithController:filePaths:)]){
                        [self.delegate imagePickerConfirmWithController:self filePaths:@[filePath]];
                    }
                }else{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(imagePickerConfirmWithController:filePaths:)]){
                        [self.delegate imagePickerConfirmWithController:self filePaths:@[]];
                    }
                }
            }];
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark - CollectionView Delegate & DataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _viewModel.allAlesst.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HImageCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imageCell" forIndexPath:indexPath];
    
    if (indexPath.item == 0){
        cell.type = self.type == HImagePickTypeWithVideo ? HImageCollectionViewCellTypeWithVideo: HImageCollectionViewCellTypeWithCamera;
    }else{
        cell.type = HImageCollectionViewCellTypeWithLibrary;
        
        HAsset *item = self.viewModel.allAlesst[indexPath.item -1];
        if(item.asset.mediaType == PHAssetMediaTypeImage){
            [cell loadAsset:item];
        }else if(item.asset.mediaType == PHAssetMediaTypeVideo){
            [cell loadAsset:item];
        }

        cell.cellSelected = [self.viewModel.selectedAlesst indexOfObject:item] !=  NSNotFound;
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.item == 0){
        if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"相机不可用" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [alert dismissViewControllerAnimated:YES completion:NULL];
            }]];
            [self presentViewController:alert animated:YES completion:NULL];
            return;
        }
        self.picker = [[UIImagePickerController alloc] init];//初始化
        self.picker.delegate = self;
        self.picker.allowsEditing = YES;//设置可编辑
        self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        if(self.type == HImagePickTypeWithVideo){
            self.picker.mediaTypes = @[(NSString *)kUTTypeMovie];
        }else{
            self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        }
        [self presentViewController:self.picker animated:YES completion:^{
            
        }];
    }else{
        HImageCollectionViewCell *cell = (HImageCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        HAsset *item = self.viewModel.allAlesst[indexPath.item -1];
        if (!cell.cellSelected) {
            if(self.selectedMax > 0){
                if(self.viewModel.selectedAlesst.count >= self.selectedMax) return;
            }
            
            [self.viewModel selectedAssest:item];
            cell.cellSelected = YES;
            
            if(!item.fileType) [item downloadICloudImage];
        }else{
            cell.cellSelected = NO;
            [self.viewModel removeAssest:item];
        }
        
        if(self.selectedMax > 0)[self refreshSelectedCount];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (SCREEN_WIDTH-(interval*2))/3;
    return CGSizeMake(width, width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return interval;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return interval;
}
#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if([keyPath isEqualToString:@"canCommit"]){
        NSNumber *canCommit = change[@"new"];
        self.confirmButton.enabled = [canCommit boolValue];
    }
}

#pragma mark - Util
UIImage * imageWithColor(UIColor *color){
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

UIColor * colorWithRGB(int R, int G, int B, float alpha){
    UIColor *color = [UIColor colorWithRed:R/255.f green:G/255.f blue:B/255.f alpha:alpha];
    return color;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    @try {
        [self.viewModel removeObserver:self forKeyPath:@"canCommit"];
    } @catch (NSException *exception) {
        
    }
}

@end
