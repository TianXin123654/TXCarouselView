//
//  TXCarouselView.h
//  textView
//
//  Created by 新华龙mac on 2018/1/17.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXCarouselCellModel.h"

@interface TXCarouselView : UIView

/**
 配置数据（固定TXCarouselView）

 @param array TXCarouselCellModelArray
 */
-(void)setArrayData:(NSArray <TXCarouselCellModel *>*)array;

/**
 配置数据（滑动TXCarouselView，加在ScrollViewv上时 需要传入）

 @param array TXCarouselCellModelArray
 @param superScrollView 父系ScrollView
 */
-(void)setArrayData:(NSArray <TXCarouselCellModel *>*)array
 andSuperScrollView:(UIScrollView *)superScrollView;

/**
 刷新CarouselView
 */
-(void)reloadCarouselView;

@end
