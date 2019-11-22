//
//  Cell.h
//  CameraAndGalleryExample
//
//  Created by Вика on 22/11/2019.
//  Copyright © 2019 Vika Olegova. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CellData;

@interface Cell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

- (void)displayData:(CellData *)data;

@end

NS_ASSUME_NONNULL_END
