//
//  Cell.m
//  CameraAndGalleryExample
//
//  Created by Вика on 22/11/2019.
//  Copyright © 2019 Vika Olegova. All rights reserved.
//

#import "Cell.h"
#import "CellData.h"

@implementation Cell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView  alloc] initWithFrame:CGRectZero];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_spinner setHidesWhenStopped:YES];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.imageView.superview)
    {
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.spinner];
        self.layer.cornerRadius = 5;
        self.layer.masksToBounds = YES;
    }
    
    self.spinner.frame = self.bounds;
    self.imageView.frame = self.bounds;
}

- (void)displayData:(CellData *)data
{
    self.imageView.image = data.isFiltered ? data.filteredImage : data.originalImage;
    self.imageView.alpha = data.isFiltered ? 1 : 0.5;
    if (data.isFiltered)
    {
        [self.spinner stopAnimating];
    }
    else
    {
        [self.spinner startAnimating];
    }
}

@end
