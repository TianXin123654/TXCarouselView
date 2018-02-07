//
//  TXCarouselViewLayout.m
//  HJCarouselDemo
//
//  Created by 新华龙mac on 2018/1/17.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import "TXCarouselViewLayout.h"

#define INTERSPACEPARAM  0.90
@interface TXCarouselViewLayout ()
@property (nonatomic, assign) CGFloat viewHeight;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) CGFloat lastDirectionIndex;
@property (nonatomic, assign) CGFloat slidDistance;
@property (nonatomic, strong) NSIndexPath *lastIndexOne;
@end

@implementation TXCarouselViewLayout

- (void)prepareLayout {
    [super prepareLayout];
    self.visibleCount = 7;
    self.viewHeight = CGRectGetWidth(self.collectionView.frame);
    self.itemHeight = self.itemSize.width;
}

- (CGSize)collectionViewContentSize {
    NSInteger cellCount = [self.collectionView numberOfItemsInSection:0];
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        return CGSizeMake(CGRectGetWidth(self.collectionView.frame), cellCount * self.itemHeight);
    }
    return CGSizeMake(cellCount * self.itemHeight, CGRectGetHeight(self.collectionView.frame));
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSInteger cellCount = [self.collectionView numberOfItemsInSection:0];
    CGFloat centerY =  self.collectionView.contentOffset.x + self.viewHeight / 2;
    NSInteger index = centerY / self.itemHeight;
    NSInteger count = (self.visibleCount - 1) / 2;
    NSInteger minIndex = MAX(0, (index - count));
    NSInteger maxIndex = MIN((cellCount - 1), (index + count));
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = minIndex; i <= maxIndex; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
        [array addObject:attributes];
    }
    return array;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = self.itemSize;
    CGFloat cY = self.collectionView.contentOffset.x + self.viewHeight / 2;
    CGFloat attributesY = self.itemHeight * indexPath.row + self.itemHeight / 2;//
    attributes.zIndex = -ABS(attributesY - cY);
    CGFloat delta = cY - attributesY;
    CGFloat ratio =  - delta / (self.itemHeight * 2);
    CGFloat scale = 1 - ABS(delta) / (self.itemHeight * 6.0) * cos(ratio * M_2_PI*0.9);
    attributes.transform = CGAffineTransformMakeScale(scale, scale);
    CGFloat centerY = attributesY;
//    NSLog(@"scale= %f",scale);
//    NSLog(@"indexPath = %ld",(long)indexPath.row);
//    NSLog(@"self.lastIndexOne = %ld",(long)self.lastIndexOne.row);
    if (scale>0.999){//滑动到最前面时， 交换持有者
         self.lastIndexOne = indexPath;
    }
    if (self.lastIndexOne == indexPath) {
        CGFloat index1 = 0.0f;
        if ([self judgeDirection:centerY]) {
            index1 = 2;
        }else{
            index1 = -2;
        }
        centerY = cY + sin(ratio * 1.31) * self.itemHeight * INTERSPACEPARAM*2.2+index1;
        //双保险，如果滑动急快的情况下，方法没有获取到最高点的坐标会导致判断失败scale>0.999 实效，
        //所以启用判断scale <= 0.84加以纠正。(且只有在上述方法实效的情况下调用，所以不能使用|| ，不然有冲突，)
        if (scale <= 0.84){
            if ([self judgeDirection:centerY]) {
                NSIndexPath *indexNext = [NSIndexPath indexPathForRow:self.lastIndexOne.row+1 inSection:0];
                self.lastIndexOne = indexNext;
            }else{
                NSIndexPath *indexNext = [NSIndexPath indexPathForRow:self.lastIndexOne.row-1 inSection:0];
                self.lastIndexOne = indexNext;
            }
        }
        if (scale <=0.9172) {
            CGFloat sinIndex = sin(ratio * 1.31) * self.itemHeight * INTERSPACEPARAM*2.7+index1;
            if ([self judgeDirection:centerY]) {
                centerY = centerY-(sinIndex+(self.itemSize.width*96/124));

            }else{
                centerY = centerY-(sinIndex-(self.itemSize.width*96/124));
            }
        }
        self.lastDirectionIndex = centerY;
    }else{
        centerY = cY + sin(ratio * 1.217) * self.itemHeight * INTERSPACEPARAM;
    }
    attributes.center = CGPointMake(centerY, CGRectGetHeight(self.collectionView.frame) / 2);
    return attributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGFloat index = roundf((proposedContentOffset.x+ self.viewHeight / 2 - self.itemHeight / 2) / self.itemHeight);
    proposedContentOffset.x = self.itemHeight * index + self.itemHeight / 2 - self.viewHeight / 2;
    return proposedContentOffset;
}

//判断滑动的方向(yes往左，no为右)；
-(BOOL)judgeDirection:(CGFloat )index{
    if (self.lastDirectionIndex>index) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
