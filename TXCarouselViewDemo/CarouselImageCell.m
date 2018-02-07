//
//  TXCustomCarouselCell.m
//  textView
//
//  Created by 新华龙mac on 2018/1/11.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import "CarouselImageCell.h"
#import "TXCarouselView.h"

@interface CarouselImageCell()
@property (weak, nonatomic) IBOutlet TXCarouselView *carouselView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoButtonWidthConstraint;
@property (nonatomic, strong) NSMutableDictionary *carouselDict;
@end

@implementation CarouselImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

-(void)configData:(NSArray <TXCarouselCellModel*>*)modelArray andSuperScrollView:(UIScrollView *)superScrollView;
{
    self.title.text = @"新时代，新地貌新时代，新地貌新时代，新地貌新时代，新地";
    self.time.text = @"2018-01-31";
    self.infoLabel.text = @"TX";
    [self.carouselView setArrayData:modelArray andSuperScrollView:superScrollView];
    [self.carouselView reloadCarouselView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
