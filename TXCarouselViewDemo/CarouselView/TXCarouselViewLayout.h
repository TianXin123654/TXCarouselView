//
//  TXCarouselViewLayout.h
//  textView
//
//  Created by 新华龙mac on 2018/1/17.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TXCarouselViewLayout : UICollectionViewLayout
@property (nonatomic) CGSize itemSize;
@property (nonatomic) NSInteger visibleCount;
@property (nonatomic) UICollectionViewScrollDirection scrollDirection;
@end

