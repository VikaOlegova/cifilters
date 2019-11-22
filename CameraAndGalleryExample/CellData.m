//
//  CellData.m
//  CameraAndGalleryExample
//
//  Created by Вика on 22/11/2019.
//  Copyright © 2019 Vika Olegova. All rights reserved.
//

#import "CellData.h"

@implementation CellData

- (BOOL)isFiltered
{
    return self.filteredImage != nil;
}

- (instancetype)initWithOriginalImage:(UIImage *)originalImage
{
    self = [super init];
    if (self)
    {
        _originalImage = originalImage;
        _filteredImage = originalImage;
        _filterName = @"none";
    }
    return self;
}

- (instancetype)initWithOriginalImage:(UIImage *)originalImage filterName:(NSString *)filterName
{
    self = [super init];
    if (self)
    {
        _originalImage = originalImage;
        _filterName = filterName;
    }
    return self;
}

@end
