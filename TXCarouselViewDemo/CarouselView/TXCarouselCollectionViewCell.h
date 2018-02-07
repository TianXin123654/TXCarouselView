//
//  TXCustomCollectionViewCell.h
//  slidetext
//
//  Created by 新华龙mac on 2018/1/16.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXCarouselCellModel.h"
@interface TXCarouselCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *covierView;

-(void)setCarouselCellModel:(TXCarouselCellModel *)model;

@property(nonatomic,copy)void(^block)(void);

@end
