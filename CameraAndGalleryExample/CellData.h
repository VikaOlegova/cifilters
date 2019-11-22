//
//  CellData.h
//  CameraAndGalleryExample
//
//  Created by Вика on 22/11/2019.
//  Copyright © 2019 Vika Olegova. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface CellData : NSObject

@property (nonatomic, strong, readonly) UIImage *originalImage;
@property (nonatomic, copy, readonly) NSString *filterName;

@property (nonatomic, strong, nullable) UIImage *filteredImage;

@property (nonatomic, readonly) BOOL isFiltered;
@property (nonatomic, assign) BOOL isFiltering;

/**
 filteredImage will be equal to originalImage.
 */
- (instancetype)initWithOriginalImage:(UIImage *)originalImage;

- (instancetype)initWithOriginalImage:(UIImage *)originalImage
                           filterName:(NSString *)filterName;

@end

NS_ASSUME_NONNULL_END
