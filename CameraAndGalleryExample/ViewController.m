//
//  ViewController.m
//  CameraAndGalleryExample
//
//  Created by Вика on 22/11/2019.
//  Copyright © 2019 Vika Olegova. All rights reserved.
//

#import "ViewController.h"
#import "Cell.h"
#import "CellData.h"
#import <PhotosUI/PhotosUI.h>

static const CGFloat ButtonHeight = 50.0;
static const CGFloat CollectionViewHeight = 100.f;

@interface ViewController () <UINavigationControllerDelegate,
                                UIImagePickerControllerDelegate,
                                UICollectionViewDataSource,
                                UICollectionViewDelegate>

// main image
@property (nonatomic, strong) UIImageView *imageView;

// filters
@property (nonatomic, strong) UICollectionView *collectionView;

// buttons
@property (nonatomic, strong) UIButton *galleryButton;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIView *splitter;

// other views
@property (nonatomic, strong) UIView *bottomBackground;

// not views
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, copy) NSArray<CellData *> *filteredImages;
@property (nonatomic, assign) BOOL hideCollectionView;

@property (nonatomic, copy, readonly) NSArray<NSString *> *filtersNames;

@property (nonatomic, strong) dispatch_semaphore_t filteringSemaphore;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    _filtersNames = @[
                      @"CIColorInvert",
                      @"CIColorMonochrome",
                      @"CIColorPosterize",
                      @"CIFalseColor",
                      @"CIMaximumComponent",
                      @"CIMinimumComponent",
                      @"CIPhotoEffectChrome",
                      @"CIPhotoEffectFade",
                      @"CIPhotoEffectInstant",
                      @"CIPhotoEffectMono",
                      @"CIPhotoEffectNoir",
                      @"CIPhotoEffectProcess",
                      @"CIPhotoEffectTonal",
                      @"CIPhotoEffectTransfer",
                      @"CISepiaTone",
                      @"CIVignetteEffect"
                      ];
    
    // prevent memory crash on iPhone
    self.filteringSemaphore = dispatch_semaphore_create(1);
	
	[self createUI];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    
    [self layoutViews];
}

#pragma mark - UI

- (void)layoutViews
{
    CGFloat topInset = self.view.safeAreaInsets.top;
    CGFloat bottomInset = self.view.safeAreaInsets.bottom;
    CGFloat maxY = CGRectGetMaxY(self.view.bounds) - bottomInset;
    
    CGFloat buttonWidth = CGRectGetWidth(self.view.bounds) / 2;
    CGRect galleryButtonRect = CGRectMake(0, maxY - ButtonHeight - 5, buttonWidth, ButtonHeight);
    CGRect cameraButtonRect = galleryButtonRect;
    cameraButtonRect.origin.x += buttonWidth;
    
    CGFloat imageHeight = CGRectGetMinY(galleryButtonRect) - topInset;
    CGRect imageRect = CGRectMake(0,
                                  topInset,
                                  CGRectGetWidth(self.view.bounds),
                                  imageHeight);
    
    CGFloat splitterWidth = 1;
    CGRect splitterRect = CGRectMake(CGRectGetMinX(cameraButtonRect) - splitterWidth/2,
                                     CGRectGetMinY(cameraButtonRect),
                                     splitterWidth,
                                     CGRectGetHeight(cameraButtonRect));
    
    [self changedLayoutViews:galleryButtonRect];
    
    self.galleryButton.frame = galleryButtonRect;
    self.cameraButton.frame = cameraButtonRect;
    self.imageView.frame = imageRect;
    self.splitter.frame = splitterRect;
}

- (void)changedLayoutViews:(CGRect)galleryButtonRect
{
    CGRect collectionRect = [self rectForCollectionViewHidden:self.hideCollectionView];
    
    BOOL collectionViewCollapsed = self.hideCollectionView || !self.filteredImages.count;
    CGFloat backgroundTop = collectionViewCollapsed ? CGRectGetMinY(galleryButtonRect) : CGRectGetMinY(collectionRect);
    backgroundTop -= 15;
    CGRect bottomBackgroundRect = CGRectMake(0,
                                             backgroundTop,
                                             CGRectGetWidth(self.view.bounds),
                                             CGRectGetHeight(self.view.bounds) - backgroundTop + 20);
    
    self.collectionView.frame = collectionRect;
    self.bottomBackground.frame = bottomBackgroundRect;
}

- (CGRect)rectForCollectionViewHidden:(BOOL)hidden
{
    CGFloat y = CGRectGetMaxY(self.view.bounds) - (self.view.safeAreaInsets.bottom + ButtonHeight + 7);
    if (!hidden)
    {
        y -= CollectionViewHeight;
    }
    
    return CGRectMake(0, y, CGRectGetWidth(self.view.bounds), hidden ? 0 : CollectionViewHeight);
}

- (void)createUI
{
    self.imageView = [UIImageView new];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	
	self.galleryButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.galleryButton setTitle:@"Галерея" forState:UIControlStateNormal];
	[self.galleryButton addTarget:self action:@selector(galleryButtonWasPressed) forControlEvents:UIControlEventTouchUpInside];
	[self.galleryButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
	
	self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.cameraButton setTitle:@"Камера" forState:UIControlStateNormal];
	[self.cameraButton addTarget:self action:@selector(cameraButtonWasPressed) forControlEvents:UIControlEventTouchUpInside];
	[self.cameraButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer new];
    [tapGesture addTarget:self action:@selector(didTapImage)];
    self.hideCollectionView = YES;
    
    [self.imageView addGestureRecognizer:tapGesture];
    [self.imageView setUserInteractionEnabled:YES];
    
    self.bottomBackground = [UIView new];
    self.bottomBackground.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    self.bottomBackground.layer.cornerRadius = 20;
    
    self.splitter = [UIView new];
    self.splitter.backgroundColor = UIColor.blackColor;
    
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.bottomBackground];
    [self.view addSubview:self.galleryButton];
    [self.view addSubview:self.cameraButton];
    [self.view addSubview:self.splitter];
    [self createCollectionVIew];
}

- (void)createCollectionVIew
{
    CGFloat itemSize = CollectionViewHeight - 20;
    CGFloat sectionInset = (CollectionViewHeight - itemSize) / 2;
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.itemSize = CGSizeMake(itemSize, itemSize);
    flowLayout.sectionInset = UIEdgeInsetsMake(sectionInset, sectionInset, sectionInset, sectionInset);
    flowLayout.minimumInteritemSpacing = sectionInset;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[Cell class] forCellWithReuseIdentifier:@"cell"];
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.backgroundColor = UIColor.clearColor;
    
    [self.view addSubview:self.collectionView];
}

- (void)animateLayout
{
    [UIView animateWithDuration:0.15 animations:^{
        [self changedLayoutViews:self.galleryButton.frame];
    }];
}

#pragma mark - Actions

- (void)didTapImage
{
    if (!self.filteredImages.count)
    {
        return;
    }
    
    self.hideCollectionView = !self.hideCollectionView;
    [self animateLayout];
}

- (void)galleryButtonWasPressed
{
	[self presentImagePickerWithType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)cameraButtonWasPressed
{
	[self presentImagePickerWithType:UIImagePickerControllerSourceTypeCamera];
}

- (UIImagePickerController *)createImagePickerWithSourceType: (UIImagePickerControllerSourceType) sourceType
{
	UIImagePickerController *imagePickerController = [UIImagePickerController new];
	imagePickerController.delegate = self;
	imagePickerController.sourceType = sourceType;
    imagePickerController.allowsEditing = NO;
	return imagePickerController;
}

- (void)presentImagePickerWithType: (UIImagePickerControllerSourceType) sourceType
{
	if ([UIImagePickerController isSourceTypeAvailable:sourceType])
	{
		UIImagePickerController *imagePickerController = [self createImagePickerWithSourceType:sourceType];
		[self presentViewController:imagePickerController animated:YES completion:nil];
	}
	else
	{
		NSLog(@"Got unavaliable source type");
	}
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
	UIImage *resizedImage = [self resizeImage:selectedImage newWidth:CGRectGetWidth(self.view.bounds)];
    NSLog(@"new size %ldx%ld", (long)resizedImage.size.width, (long)resizedImage.size.height);
    
	self.selectedImage = resizedImage;
	self.imageView.image = resizedImage;
    
    NSMutableArray<CellData *> *newData = [NSMutableArray new];
    
    CellData *originalImageData = [[CellData alloc] initWithOriginalImage:resizedImage];
    [newData addObject:originalImageData];
    
    for (NSString *filterName in self.filtersNames) {
        CellData *data = [[CellData alloc] initWithOriginalImage:resizedImage filterName:filterName];
        [newData addObject:data];
    }
    
    self.filteredImages = newData;
    [self.collectionView reloadData];
    
    for (NSUInteger i = 1; i < newData.count; i++)
    {
        CellData *data = newData[i];
        [self applyFilterForCellData:data atIndex:i];
    }
}


#pragma mark - CIFilter

- (void)applyFilterForCellData:(CellData *)cellData atIndex:(NSUInteger)index
{
    if (cellData.isFiltered || cellData.isFiltering)
    {
        return;
    }
    
    cellData.isFiltering = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(self.filteringSemaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"entered %ld", index);
        cellData.filteredImage = [self imageAfterFiltering:cellData.originalImage
                                                filterName:cellData.filterName];
        NSLog(@"leaved %ld", index);
        dispatch_semaphore_signal(self.filteringSemaphore);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
        });
    });
}

- (UIImage *)imageAfterFiltering:(UIImage *)imageToFilter filterName:(NSString *)filterName
{
    UIImage *imageToDisplay = imageToFilter;//[self normalizedImageWithImage:imageToFilter];
	
	CIContext *context = [[CIContext alloc] initWithOptions:nil];
	CIImage *ciImage = [[CIImage alloc] initWithImage:imageToDisplay];
	
	CIFilter *ciEdges = [CIFilter filterWithName:filterName];
	[ciEdges setValue:ciImage forKey:kCIInputImageKey];
    
    if ([filterName isEqualToString:@"CIVignetteEffect"])
    {
        CIVector *center = [CIVector vectorWithX:imageToDisplay.size.width / 2
                                               Y:imageToDisplay.size.height / 2];
        CGFloat radius = MAX(imageToDisplay.size.width, imageToDisplay.size.height) / 2;
        [ciEdges setValue:center forKey:@"inputCenter"];
        [ciEdges setValue:@(radius) forKey:@"inputRadius"];
        [ciEdges setValue:@(1) forKey:@"inputIntensity"];
    }
	
    CIImage *result = [ciEdges valueForKey:kCIOutputImageKey];
	CGRect extent = [result extent];
	CGImageRef cgImage = [context createCGImage:result fromRect:extent];
	UIImage *filteredImage = [[UIImage alloc] initWithCGImage:cgImage];
	CFRelease(cgImage);
	
	return filteredImage;
}


#pragma mark - Helpers

- (UIImage *)resizeImage:(UIImage *)image newWidth:(CGFloat)newWidth
{
    CGFloat aspect = image.size.height / image.size.width;
    CGSize newSize = CGSizeMake(newWidth, newWidth * aspect);
    
    UIGraphicsBeginImageContextWithOptions(newSize, YES, image.scale);
    [image drawInRect:(CGRect){0, 0, newSize}];
	UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return resizedImage;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CellData *data = self.filteredImages[indexPath.row];
    if (data.isFiltered)
    {
        self.imageView.image = data.filteredImage;
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.filteredImages.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    Cell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    CellData *data = self.filteredImages[indexPath.row];
    
    [cell displayData:data];
    
    return cell;
}

@end
