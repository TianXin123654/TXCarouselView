//
//  TXCustomCollectionViewCell.m
//  slidetext
//
//  Created by 新华龙mac on 2018/1/16.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import "TXCarouselCollectionViewCell.h"

@interface TXCarouselCollectionViewCell()<UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleStr;

@end

@implementation TXCarouselCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.shadowRadius = 6.0f;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 6.0f;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.masksToBounds = NO;
    
    UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panSild)];
    ges.delegate = self;
    [self addGestureRecognizer:ges];
}

/**
 解决手势冲突

 @param gestureRecognizer gestureRecognizer
 @param otherGestureRecognizer otherGestureRecognizer
 @return bool
 */
-(BOOL)gestureRecognizer:(UIGestureRecognizer*) gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
    if ([gestureRecognizer.view isKindOfClass:[UICollectionView class]]) {
        return NO;
    }else{
        return YES;
    }
}

/**
 手势滑动
 */
-(void)panSild
{
    if (self.block) {self.block();}
}

/**
 加载数据

 @param model TXCarouselCellModel
 */
-(void)setCarouselCellModel:(TXCarouselCellModel *)model{
    self.imageView.image = [UIImage imageNamed:model.imageUrl];
    self.titleStr.text = model.titleStr;
}
@end
