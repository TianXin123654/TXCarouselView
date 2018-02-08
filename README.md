  前段时间，公司的大佬看中了新浪新闻首页卡片滚动的特效，如下图：
  
  ![新浪新闻卡片效果（网络来源）](https://upload-images.jianshu.io/upload_images/9610720-84968781a1077e85.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/360)

拿到效果图一看之下这个效果，这个效果不是那么好做。由于赶在年前就要上线，时间紧迫。没办法只有靠度娘了，多方查找之下，找到了一篇文章-[iOS新浪新闻首页卡片滚动特效实现浅谈](https://www.jianshu.com/p/5145da65f20f)。

 当时一看，这个不就是大佬想要的效果么？心中顿时一阵窃喜。大致浏览了一下然后迅速拉到文章底下想看一下demo。结果傻眼了，别说demo了，连部分源码也没有，只提供了大致的思路。我靠，心中一阵拔凉。

 然后重新阅读了一下[随行的羊](https://www.jianshu.com/u/f4cf2045e5e1)的文章。发现他的思路很明确。行吧，那没办法了， 只有先按照他的思路做。

###下面进入正题
[随行的羊](https://www.jianshu.com/u/f4cf2045e5e1)采用了UICollectionView，那我也采用了这个吧，说干就干，下面我直接根据他的思路贴出部分代码，具体的demo 详见github地址:[TXCarouselView](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2FTianXin123654%2FTXCarouselView)

问题1：中间的滚动视图是一块一块移动的，停止时距离中间最近的卡片会自动滑动到中间，居中对齐。
```
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGFloat index = roundf((proposedContentOffset.x+ self.viewHeight / 2 - self.itemHeight / 2) / self.itemHeight);
    proposedContentOffset.x = self.itemHeight * index + self.itemHeight / 2 - self.viewHeight / 2;
    return proposedContentOffset;
}
```
问题2：中间的滚动视图在滑动的时候发现卡片是叠在一起的，中间的在上层，其他部分在下层，根据距离中间位置的远近来区别上下层。
```
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = self.itemSize;
    CGFloat cY = self.collectionView.contentOffset.x + self.viewHeight / 2;
    CGFloat attributesY = self.itemHeight * indexPath.row + self.itemHeight / 2;//
    attributes.zIndex = -ABS(attributesY - cY);
}
```
问题3：中间的滚动视图在滑动的时候发现卡片大小不一致，中间的最大，越靠近边框越小。同样是在layoutAttributesForItemAtIndexPath中：
```
    CGFloat scale = 1 - ABS(delta) / (self.itemHeight * 6.0) * cos(ratio * M_2_PI*0.9);
    attributes.transform = CGAffineTransformMakeScale(scale, scale);
```
问题4：中间的滚动视图在滑动的时候发现滑动的距离和卡片移动的距离并不是成正比，而是按照不断变化的加速度移动的。
```
centerY = cY + sin(ratio * 1.31) * self.itemHeight * INTERSPACEPARAM*2.2+index1;

```
问题5：中间的滚动视图滑到左右边缘时视图透明度改变。
```
这个也可以根据的centerY来确定，attributes这个布局类中提供了
@property (nonatomic) CGFloat alpha;
所以也可以实现。
```
问题6：循环滚动方案的实现(额。这里我用的创建多组数据来实现的，因为cell有复用机制，所以创建多组数据也没有关系。只要能顺滑就行了)
```
self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];

```

问题7：上下滑动表格时，中间的滚动视图要跟着一起滑动，上滑时向左移动，下滑时向右移动。
```
这里用kvo监听一下就可以了
 [self.superScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
```
问题8：左右晃动手机时，中间的滚动视图要跟着一起滑动，向左晃动时卡片向左移动，向右晃动时卡片向右移动。
>这个用苹果自带的加速计和陀螺仪就行了，但是其中有很多问题需要解决，但是细致调试之下完美解决了具体代码详见github地址:[TXCarouselView](https://link.jianshu.com/?t=https%3A%2F%2Fgithub.com%2FTianXin123654%2FTXCarouselView)

问题9：需要保证刚才提到的3种控制方式互不干扰。
```
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
```
问题10：拖动，滑动， 重力感应结束需要回到正中位置。
```
1.拖动
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGFloat index = roundf((proposedContentOffset.x+ self.viewHeight / 2 - self.itemHeight / 2) / self.itemHeight);
    proposedContentOffset.x = self.itemHeight * index + self.itemHeight / 2 - self.viewHeight / 2;
    return proposedContentOffset;
}
```
```
2.tableview滑动结束时，需要回到初始位置，这里我试过用kvo监听superScrollView的滑动结束，但是没有找到方法。用通知就太low了，然后在朋友的建议下用了runLoop:
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

```
好了，大部分的细节就不细说了，如果能给一个star就最好了。

