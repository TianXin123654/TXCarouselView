//
//  TXCustomCarouselCell.h
//  textView
//
//  Created by 新华龙mac on 2018/1/11.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXCarouselCellModel.h"
@interface CarouselImageCell : UITableViewCell

/**
 configData

 @param modelArray modelArray
 @param superScrollView superScrollView
 */
-(void)configData:(NSArray <TXCarouselCellModel*>*)modelArray andSuperScrollView:(UIScrollView *)superScrollView;

@end
