//
//  TXCarouselView.m
//  textView
//
//  Created by 新华龙mac on 2018/1/17.
//  Copyright © 2018年 新华龙mac. All rights reserved.
//

#import "TXCarouselView.h"
#import "TXCarouselCollectionViewCell.h"
#import "TXCarouselViewLayout.h"

#import "TXCarouselCellModel.h"
#import <CoreMotion/CoreMotion.h>

#define itemHight 0.8

//当前 carousel 状态
@interface  carouselCurrentState : NSObject
@property (nonatomic, assign) BOOL isOverturnState; //是否进入翻转状态
@property (nonatomic, assign) BOOL isDragState;     //是否处于拖动状态
@property (nonatomic, assign) BOOL isDidScroll;     //是否处于滑动状态
@property (nonatomic, assign) BOOL isCenter;        //是否处于回到正中状态
@property (nonatomic, assign) BOOL isRestrict;      //是否处于限制重力感应
@property (nonatomic, assign) CGFloat lastCarouselPoint;//上一个lastPoint

@end

@implementation carouselCurrentState
@end

typedef void (^OpenAccelerometerUpdatesBlock)(CGFloat value);
typedef void (^OpenGyroUpdatesBlock)(CGFloat value);

@interface TXCarouselView ()<
UICollectionViewDelegateFlowLayout,
UICollectionViewDataSource,
UICollectionViewDelegate,
UIScrollViewDelegate
>

@property (nonatomic, strong) TXCarouselViewLayout *carouselViewLayout;
@property (nonatomic, strong) carouselCurrentState *currentState;//当前 carousel 状态
@property (nonatomic, strong) UIScrollView *superScrollView;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, assign) CGFloat lasttimePoint;
@property (nonatomic, assign) CGFloat gyrValue;//加速计值
@property (nonatomic, assign) CGSize carouselSize;

@end

@implementation TXCarouselView

#pragma mark - 生命周期
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        UIViewController *vc =  [self getTopViewController];
        for (id type1 in vc.view.subviews) {
            if ([type1 isKindOfClass:[UITableView class]]) {
                UITableView *table = (UITableView *)type1;
                UILongPressGestureRecognizer *tag = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(tapGes:)];
                [table addGestureRecognizer:tag];
            }
        }
        self.currentState = [[carouselCurrentState alloc]init];
        self.currentState.isOverturnState = NO;
        self.currentState.isDragState = NO;
        self.currentState.isDidScroll = NO;
        self.currentState.isCenter = NO;
        self.currentState.isRestrict = NO;
        [self openMotionManager];
        [self creatUIRunloopObserver:kCFRunLoopExit];
    
        //如果tableview 加载多个TXCarouselView的时候，最好实现以下几个通知，当cell 消失的时候关闭当前cell 上的重力感应.
        //关闭当前消失cell上的重力感应，
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAssignManager:) name:@"closeAssignManager" object:nil];
        //开启当前出现cell上的重力感应，
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openAssignManager:) name:@"openAssignManager" object:nil];
        //限制重力感应
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turnDowntGyroUpdates) name:@"turnDowntGyroUpdates" object:nil];
        //解除限制重力感应
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startGyroUpdates) name:@"startGyroUpdates" object:nil];

    }
    return self;
}
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(void)layoutSubviews
{
    self.carouselSize = self.frame.size;
    [self createCollectionView];
    [self.collectionView reloadData];
    [self.collectionView layoutIfNeeded];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setpoint];
    });
}

-(void)setpoint{
    [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.contentOffset.y) animated:NO];
    [self.collectionView setContentOffset:CGPointMake(0+((self.modelArray.count/2)*(self.carouselSize.height*itemHight)), self.collectionView.contentOffset.y) animated:NO];
    self.currentState.lastCarouselPoint = 0;
    [self setSlideEnd];
}

- (void)dealloc
{
     _motionManager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma  mark - loadData
-(void)setArrayData:(NSArray <TXCarouselCellModel *>*)array{
    [self.modelArray removeAllObjects];
    //如果有数据情况下创建10轮数据用作无限循环（UIcllectView有复用机制不用担心数据过多引起卡顿）
    //我并没有采用正经的无线循环方式->(前后面加数据的方式，那是大神处理的事情，我暂时没有去采用那种方式）
    if (array.count<=0) {
        return;
    }
    [self.modelArray addObjectsFromArray:array];
    NSInteger index = 10;
    for (int i = 0; i<index; i++) {
        if (self.modelArray.count>500) {
            return;
        }
        [self.modelArray addObjectsFromArray:self.modelArray];
    }
}

-(void)setArrayData:(NSArray<TXCarouselCellModel *> *)array andSuperScrollView:(UIScrollView *)superScrollView
{

    [self.modelArray removeAllObjects];
    if (array.count<=0) {
        return;
    }
    [self.modelArray addObjectsFromArray:array];
    NSInteger index = 10;
    for (int i = 0; i<index; i++) {
        [self.modelArray addObjectsFromArray:self.modelArray];
    }
    self.superScrollView = superScrollView;
    [self addSuperScrollViewKvo];

}

-(void)reloadCarouselView
{
//    self.carouselSize = self.frame.size;
//    NSLog(@"%@",NSStringFromCGSize(self.frame.size));
//    [self createCollectionView];
//    [self.collectionView reloadData];
//    [self.collectionView layoutIfNeeded];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self setpoint];
//    });
}

#pragma mark - delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return  self.modelArray.count;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    self.currentState.isDidScroll = NO;
    self.currentState.isDragState = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    self.currentState.isDidScroll = NO;
    self.currentState.isDragState = NO;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x<300) {
        CGPoint point = CGPointMake(0+(self.modelArray.count/2*self.frame.size.height*itemHight),
                                    self.collectionView.contentOffset.y);
        [self.collectionView setContentOffset:point animated:NO];
    }else if (scrollView.contentOffset.x>(self.modelArray.count*self.frame.size.height*itemHight)-500){
        CGPoint point = CGPointMake(0+(self.modelArray.count/2*self.frame.size.height*itemHight),
                                    self.collectionView.contentOffset.y);
        [self.collectionView setContentOffset:point animated:NO];
    }

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    TXCarouselCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TXCarouselCollectionViewCell" forIndexPath:indexPath];
    [cell setCarouselCellModel:self.modelArray[indexPath.row]];
    [cell setBlock:^{
        weakSelf.currentState.isDragState = YES;
        weakSelf.currentState.isCenter = NO;
    }];
    return cell;
}

#pragma mark - privately method
/**
 计算滑动的距离，然后计算collectionView的偏移量

 @param index index
 */
-(void)setSlideDistance:(CGFloat)index{
    self.currentState.isCenter = NO;
    self.currentState.isDidScroll = YES;
    CGFloat indexContentOffset = self.collectionView.contentOffset.x;
    indexContentOffset+=((index-self.lasttimePoint))*0.8;
    [self.collectionView setContentOffset:CGPointMake(indexContentOffset, 0) animated:NO];
    self.lasttimePoint = index;
}

/**
 回到屏幕正中间
 */
-(void)setSlideEnd{
    CGPoint collectionViewPoint = self.collectionView.contentOffset;
    if ( self.currentState.lastCarouselPoint == collectionViewPoint.x||
        self.currentState.isDragState
        ) {
        return;
    }
    CGFloat viewHeight = CGRectGetWidth(self.collectionView.frame);
    CGFloat itemHeight = self.carouselSize.height*itemHight;
    CGFloat index = roundf((self.collectionView.contentOffset.x+ viewHeight / 2 - itemHeight / 2) /itemHeight);
    collectionViewPoint.x = itemHeight * index + itemHeight / 2 - viewHeight / 2;
 
    [self.collectionView setContentOffset:CGPointMake(collectionViewPoint.x, collectionViewPoint.y) animated:YES];
    self.currentState.lastCarouselPoint = self.collectionView.contentOffset.x;
    self.currentState.isDidScroll = NO;
}

- (UIViewController*)getTopViewController {
    UIViewController *rootVc = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self topViewControllerWithRootViewController:rootVc];
}

- (UIViewController *)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* nav = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:nav.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

#pragma mark - 通知
-(void)turnDowntGyroUpdates{
    self.currentState.isRestrict = YES;
}
-(void)startGyroUpdates{
    self.currentState.isRestrict = NO;
}

-(void)openAssignManager:(NSNotification *)notification{
    [self openMotionManager];
}

-(void)closeAssignManager:(NSNotification *)notification
{
    [self closeAllManager];

}

/**
 手势优先级
 
 @param longGesture longGesture
 */
-(void)tapGes:(UILongPressGestureRecognizer *)longGesture{
    self.currentState.isDragState = YES;
    if (longGesture.state == UIGestureRecognizerStateEnded){
        self.currentState.isDragState = YES;
    }
}

/**
 父视图滑动的距离
 
 @param notification notification
 */
-(void)slideDistance:(NSNotification *)notification{
    NSString *str = notification.userInfo[@"scrollViewcontentOffset"];
    CGFloat index = [str doubleValue];
    [self setSlideDistance:index];
}

/**
 结束滑动后计算图片的正中偏移量
 
 @param notification isEnd
 */
-(void)setScrollViewSlideEnd:(NSNotification *)notification{
    self.currentState.isDragState = NO;
    [self setSlideEnd];
}

#pragma mark - 监听
/**
 建立对外层ScrollView的监听
 */
-(void)addSuperScrollViewKvo
{
    [self.superScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void *)context {
    if (object == self.superScrollView) {
        CGPoint point=[((NSValue *)[self.superScrollView  valueForKey:@"contentOffset"]) CGPointValue];
        [self setSlideDistance:point.y];
    }
}
- (void)creatUIRunloopObserver:(CFOptionFlags)flag {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFStringRef runLoopMode = (__bridge CFStringRef)UITrackingRunLoopMode;
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, flag, true, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity _activity) {
        switch (_activity) {
            case kCFRunLoopEntry: {
                NSLog(@"即将进入Loop");
            }
                break;
            case kCFRunLoopBeforeTimers: {
                NSLog(@"即将处理 Timer");
                break;
            }
            case kCFRunLoopBeforeSources:
                NSLog(@"即将处理 Source");
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"即将进入休眠");
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"刚从休眠中唤醒");
                break;
            case kCFRunLoopExit:
                NSLog(@"UITracking 即将退出Loop");
                self.currentState.isOverturnState = NO;
                self.currentState.isDragState = NO;
                self.currentState.isDidScroll = NO;
                self.currentState.isCenter = NO;
                self.currentState.isRestrict = NO;
                self.currentState.lastCarouselPoint = 0.0f;
                [self setSlideEnd];
                break;
            default:
                break;
        }
    });
    
    CFRunLoopAddObserver(runLoop, observer, runLoopMode);
}


#pragma mark - 重力感应
-(void)openMotionManager{
    __weak typeof(self) weakSelf = self;
    [self  startGyroUpdates:^(CGFloat value) {
        weakSelf.gyrValue = value;
        
    }];
    [self startAccelerometerUpdates:^(CGFloat value) {
        //1.进入翻转状态
        if (fabs(value)>0.05){
            weakSelf.currentState.isOverturnState = YES;
        }else{
            weakSelf.currentState.isOverturnState = NO;
            if (!weakSelf.currentState.isDragState&&
                !weakSelf.currentState.isDidScroll&&
                !weakSelf.currentState.isCenter) {
                self.currentState.isCenter = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf setSlideEnd];
                });
            }
        }
        [weakSelf setGyroUpdatesValue];
    }];
}

-(void)setGyroUpdatesValue
{
    if (self.currentState.isDragState||
        !self.currentState.isOverturnState||
        self.currentState.isDidScroll||
        self.currentState.isRestrict) {
        return;
    }
    
    NSLog(@"重力感应开始滑动");
    self.currentState.isCenter = NO;
    CGFloat indexContentOffset = self.collectionView.contentOffset.x;
    [self.collectionView setContentOffset:CGPointMake(indexContentOffset+self.gyrValue*3, 0) animated:NO];
    
}

-(void)startAccelerometerUpdates:(OpenAccelerometerUpdatesBlock)result{
    if (![self.motionManager isAccelerometerAvailable]) {
        NSLog(@"陀螺仪不可用");
        return;
    }
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        result(accelerometerData.acceleration.x);
    }];
}

- (void)startGyroUpdates:(OpenGyroUpdatesBlock)result{
    
    if (![self.motionManager isGyroAvailable]) {
        NSLog(@"加速计不可用");
        return;
    }
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        result(gyroData.rotationRate.y);
    }];
}

//关闭陀螺仪
-(void)closeAccelerometerUpdates{
    [self.motionManager stopAccelerometerUpdates];
}

//关闭加速计
-(void)closeGyroUpdates{
    [self.motionManager stopGyroUpdates];
}

//关闭所有
-(void)closeAllManager{
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
}

#pragma mark - Lazy
-(CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.deviceMotionUpdateInterval = 0.1;
    }
    return _motionManager;
}

-(TXCarouselViewLayout *)carouselViewLayout{
    if (!_carouselViewLayout) {
        CGFloat itemsHeight = self.carouselSize.height*itemHight;
        _carouselViewLayout = [[TXCarouselViewLayout alloc] init];
        _carouselViewLayout.itemSize = CGSizeMake(itemsHeight, itemsHeight);
        _carouselViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _carouselViewLayout;
}

-(void)createCollectionView{
    if (!self.collectionView) {
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width,self.frame.size.height ) collectionViewLayout:self.carouselViewLayout];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.pagingEnabled = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.collectionView registerNib:[UINib nibWithNibName:@"TXCarouselCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"TXCarouselCollectionViewCell"];
        self.collectionView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.collectionView];
    }
}

-(NSMutableArray *)modelArray
{
    if (!_modelArray) {
        _modelArray = [[NSMutableArray alloc]init];
    }
    return _modelArray;
}

@end
