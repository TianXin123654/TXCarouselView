//
//  ViewController.m
//  textView
//
//  Created by 新华龙mac on 2018/1/10.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import "ViewController.h"
#import "TXCarouselCellModel.h"
#import "CarouselImageCell.h"
#import "TXTextTableViewCell.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    NSArray *arrayStr = [NSArray arrayWithObjects:
                         @"1111111111111111111111111111111111111111111111",
                         @"2222222222222222222222222222222222222222222222",
                         @"3333333333333333333333333333333333333333333333",
                         @"4444444444444444444444444444444444444444444444",
                         @"5555555555555555555555555555555555555555555555",
                         nil];
    for (int i = 0; i<arrayStr.count; i++) {
        TXCarouselCellModel *model = [[TXCarouselCellModel alloc]init];
        model.imageUrl = [NSString stringWithFormat:@"zongshujidaowojia%d",i+1];
        model.titleStr = arrayStr[i];
        model.newsId = i;
        [self.array addObject:model];
    }
    [self.tableView reloadData];
}
//页面出现的时候限制重力感应
-(void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"startGyroUpdates" object:nil];
}

//页面消失的时候打开重力限制
- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter]postNotificationName:@"turnDowntGyroUpdates" object:nil];
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 8;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 62+49 +181*SCREEN_WIDTH/375;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1) {
        CarouselImageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CarouselImageCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell configData:self.array andSuperScrollView:self.tableView];
        return  cell;
    }else{
        TXTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TXTextTableViewCell"];
        return cell;
    }
}

//如果同一个tableview出现多个重力的时候，打开当前即将加载的cell 上的重力感应
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        NSDictionary *dict =[[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"openAssignManager",nil];
        NSNotification *notification =[NSNotification notificationWithName:@"openAssignManager" object:nil userInfo:dict];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

//如果同一个tableview出现多个重力的时候，关闭当前cell上的重力感应
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 1) {
        NSDictionary *dict =[[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"closeAssignManager",nil];
        NSNotification *notification =[NSNotification notificationWithName:@"closeAssignManager" object:nil userInfo:dict];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }


}
#pragma mark - Lazy
-(UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc]
                      initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerNib:[UINib nibWithNibName:@"CarouselImageCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"CarouselImageCell"];
        [_tableView registerNib:[UINib nibWithNibName:@"TXTextTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"TXTextTableViewCell"];
    }
    return _tableView;
}

-(NSMutableArray *)array
{
    if (!_array) {
        _array = [[NSMutableArray alloc]init];
    }
    return _array;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

