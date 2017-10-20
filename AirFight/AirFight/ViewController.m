//
//  ViewController.m
//  AirFight
//
//  Created by 马异峰 on 2017/10/20.
//  Copyright © 2017年 Yifeng. All rights reserved.
//
/**
 第一次调试：
 问题1:我方飞机没有显示
 问题2:当按home键返回后，再次打开app，
     1）累计得分没有了
     2）背景图片没有了
 */

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ViewController.h"
#import "Spirit.h"

@interface ViewController ()

@end

// 定义背景图片的高度为860
#define BACK_HEIGHT 860

@implementation ViewController{
    NSTimer * _timer;
    CALayer * _backgroundLayer_01;
    CALayer * _backgroundLayer_02;
    CALayer * _myPlane;
    CATextLayer * _scoreLayer;
    NSMutableArray<CALayer*>* _enemyPlaneArray;
    NSMutableArray<CALayer*>* _bulletArray;
    NSMutableArray<Spirit*>* _blastArray;
    NSArray<UIImage*>* _blastImageArray;
    AVAudioPlayer * _backgroundMusicPlayer;
    SystemSoundID _blastSound;
    NSInteger _count;
    UIImage * _planeImage_0;
    UIImage * _planeImage_1;
    UIImage * _enemyPlaneImage_0;
    UIImage * _enemyPlaneImage_1;
    UIImage * _enemyPlaneImage_2;
    UIImage * _bulletImage;
    UIImage * _backgroundImage;
    NSInteger _score;
    // 定义获取屏幕宽度、高度的变量
    NSInteger _screenWidth, _screenHeight;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // 获取屏幕的宽度和高度
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    _screenWidth = screenBounds.size.width;
    _screenHeight = screenBounds.size.height;
    _blastImageArray = @[[UIImage imageNamed:@"blast/blast0"],
                         [UIImage imageNamed:@"blast/blast1"],
                         [UIImage imageNamed:@"blast/blast2"],
                         [UIImage imageNamed:@"blast/blast3"],
                         [UIImage imageNamed:@"blast/blast4"],
                         [UIImage imageNamed:@"blast/blast5"],
                         ];
    // 初始化显示自己的飞机动画所需的两张图片
    _planeImage_0 = [UIImage imageNamed:@"plane/plane0"];
    _planeImage_1 = [UIImage imageNamed:@"plane/plane1"];
    // 初始化3种敌机的图片
    _enemyPlaneImage_0 = [UIImage imageNamed:@"plane/e0"];
    _enemyPlaneImage_1 = [UIImage imageNamed:@"plane/e1"];
    _enemyPlaneImage_2 = [UIImage imageNamed:@"plane/e2"];
    // 初始化子弹图片
    _bulletImage = [UIImage imageNamed:@"plane/bullet"];
    // 初始化背景图片
    _backgroundImage = [UIImage imageNamed:@"plane/bg.jpg"];
    // 获取背景音效的音频文件的URL
    NSURL * backgroundMusicURL = [[NSBundle mainBundle]URLForResource:@"s3" withExtension:@"wav"];
    // 创建AVAudioPlayer对象
    _backgroundMusicPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:backgroundMusicURL error:nil];
    _backgroundMusicPlayer.numberOfLoops = -1;
    // 播放背景音效
    [_backgroundMusicPlayer play];
    // 获取要播放爆炸的音频文件的URL
    NSURL * blastMusicURL = [[NSBundle mainBundle]URLForResource:@"s0" withExtension:@"mp3"];
    // 加载音效文件
    AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(blastMusicURL), &_blastSound);
    // 初始化容纳所有敌机、所有子弹、所有爆炸效果的NSMutableArray集合
    _enemyPlaneArray = [[NSMutableArray alloc]init];
    _bulletArray = [[NSMutableArray alloc]init];
    _blastArray = [[NSMutableArray alloc]init];
    // 创建代表背景的CALayer对象
    _backgroundLayer_01 = [CALayer layer];
    // 设置代表背景的CALayer显示的图片
    _backgroundLayer_01.contents = (id)(_backgroundImage.CGImage);
    _backgroundLayer_01.frame = CGRectMake(0, _screenHeight - BACK_HEIGHT, _screenWidth, BACK_HEIGHT);
    [self.view.layer addSublayer:_backgroundLayer_01];
    // 设置代表背景的CALayer显示的图片
    _backgroundLayer_02 = [CALayer layer];
    _backgroundLayer_02.contents = (id)(_backgroundImage.CGImage);
    _backgroundLayer_02.frame = CGRectMake(0, _screenHeight - BACK_HEIGHT * 2, _screenWidth, BACK_HEIGHT);
    [self.view.layer addSublayer:_backgroundLayer_02];
    
    // 创建代表自己飞机的CALayer对象
    _myPlane = [CALayer layer];
    _myPlane.frame = CGRectMake((_screenWidth - 56) / 2, _screenHeight - 80, 56, 61);
    [self.view.layer addSublayer:_myPlane];
    // 创建显示得分的CALayer对象
    _scoreLayer = [CATextLayer layer];
    _scoreLayer.frame = CGRectMake(10, 10, 120, 30);
    _scoreLayer.fontSize = 16;
    
    // 使用NSUserDefaults读取系统已经保存的得分
    NSNumber * scoreNumber;
    if ((scoreNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"score"])) {
        _score = scoreNumber.integerValue;
    }
    _scoreLayer.string = [NSString stringWithFormat:@"累计得分:%ld", _score];
    [self.view.layer addSublayer:_scoreLayer];
    // 启动定时器
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(move) userInfo:nil repeats:YES];
    
    // 使用默认的通知中心监听应用转入前台的过程
    // 应用转入前台时会向通知中心发送UIApplicationWillEnterForegroundNotification
    // 从而激发enterFore:方法
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFore:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    // 使用默认的通知中心监听应用转入后台的过程
    // 应用转入后台时会向通知中心发送UIApplicationDidEnterBackgroundNotification
    // 从而激发enterBack:方法
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBack:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
    
}
-(void)enterBack:(NSNotification*)notification{
    NSLog(@"---entreBack---");
    // 停止定制器
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    // 转入后台时将可以迅速重建，而且占用内存较大的对象设为nil，以便系统释放内存
    _planeImage_0 = nil;
    _planeImage_1 = nil;
    _myPlane.contents = nil;
    _enemyPlaneImage_0 = nil;
    _enemyPlaneImage_1 = nil;
    _enemyPlaneImage_2 = nil;
    _bulletImage = nil;
    _backgroundImage = nil;
    _backgroundLayer_01.contents = nil;
    _backgroundLayer_02.contents = nil;
    _backgroundMusicPlayer = nil;
    
    // 使用NSUserDefaults存储系统得分
    [[NSUserDefaults standardUserDefaults] setInteger:_score forKey:@"score"];
}
-(void)enterFore:(NSNotification*)notification{
    NSLog(@"---entreFore---");
    // 初始化显示自己的飞机动画所需的两张图片
    _planeImage_0 = [UIImage imageNamed:@"plane/plane0"];
    _planeImage_1 = [UIImage imageNamed:@"plane/plane1"];
    // 初始化3种敌机的图片
    _enemyPlaneImage_0 = [UIImage imageNamed:@"plane/e0"];
    _enemyPlaneImage_1 = [UIImage imageNamed:@"plane/e1"];
    _enemyPlaneImage_2 = [UIImage imageNamed:@"plane/e2"];
    // 初始化子弹图片
    _bulletImage = [UIImage imageNamed:@"plane/bullet"];
    // 初始化背景图片
    _backgroundImage = [UIImage imageNamed:@"plane/bg.jpg"];
    // 获取背景音效的音频文件的URL
    NSURL * backgroundMusicURL = [[NSBundle mainBundle]URLForResource:@"s3" withExtension:@"wav"];
    // 创建AVAudioPlayer对象
    _backgroundMusicPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:backgroundMusicURL error:nil];
    _backgroundMusicPlayer.numberOfLoops = -1;
    // 播放背景音效
    [_backgroundMusicPlayer play];
    // 如果定制器为nil，重新启动定时器
    if (_timer == nil) {
        // 启动定时器
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(move) userInfo:nil repeats:YES];
    }
    // 使用NSUserDefaults读取系统已经保存的得分
    NSNumber * scoreNumber = [[NSUserDefaults standardUserDefaults]objectForKey:@"score"];
    if (scoreNumber != nil) {
        _score = scoreNumber.integerValue;
    }
}
-(void)move{
    // 控制飞机的图片交替显示，实现动画效果
    _myPlane.contents = (id)((_count % 2 == 0) ? _planeImage_0 : _planeImage_1);
    // 控制背景向下移动
    _backgroundLayer_01.frame = CGRectOffset(_backgroundLayer_01.frame, 0, 5);
    _backgroundLayer_02.frame = CGRectOffset(_backgroundLayer_02.frame, 0, 5);
    // 如果_bgLayer1已经到了最下面（移出屏幕外），将_bgLayer1移动到最上面
    if (_backgroundLayer_01.position.y == BACK_HEIGHT / 2 + _screenHeight + 20) {
        [_backgroundLayer_01 removeFromSuperlayer];
        _backgroundLayer_01.position = CGPointMake(_screenWidth / 2, _screenHeight - BACK_HEIGHT * 3 / 2 + 20);
        [self.view.layer insertSublayer:_backgroundLayer_01 below:_backgroundLayer_02];
    }
    // 如果_bgLayer2已经到了最下面（移出屏幕外），将_bgLayer2移动到最上面
    if (_backgroundLayer_02.position.y == BACK_HEIGHT / 2 + _screenHeight + 20) {
        [_backgroundLayer_02 removeFromSuperlayer];
        _backgroundLayer_02.position = CGPointMake(_screenWidth / 2, _screenHeight - BACK_HEIGHT * 3 / 2 + 20);
        [self.view.layer insertSublayer:_backgroundLayer_02 below:_backgroundLayer_01];
    }
    // 遍历所有的爆炸效果
    for (int i = 0; i < _blastArray.count; i++) {
        Spirit* blast = _blastArray[i];
        // 控制爆炸效果CALayer显示下一张图片，从而显示爆炸动画
        blast.imageIndex = (blast.imageIndex + 1) % _blastImageArray.count;
        blast.layer.contents = (id)_blastImageArray[blast.imageIndex].CGImage;
    }
    // 遍历所有的子弹
    for (int i = 0; i < _bulletArray.count; i++) {
        CALayer * bullet = _bulletArray[i];
        // 控制所有的子弹向上移动
        bullet.frame = CGRectOffset(bullet.frame, 0, -15);
        // 如果子弹已经移出屏幕外，则删除子弹
        if (bullet.position.y < -10) {
            // 删除该子弹CALayer
            [bullet removeFromSuperlayer];
            // 从_bulletArray集合中删除子弹CALayer
            [_bulletArray removeObjectAtIndex:i];
        }
    }
    // 遍历所有的敌机
    for (int i = 0; i < _enemyPlaneArray.count; i++) {
        CALayer * enemyPlane = _enemyPlaneArray[i];
        // 控制所有的敌机向下移动
        enemyPlane.frame = CGRectOffset(enemyPlane.frame, 0, 15);
        // 如果敌机已经移出屏幕外，则删除敌机
        if (enemyPlane.position.y > _screenHeight + 50) {
            // 删除该敌机CALayer
            [enemyPlane removeFromSuperlayer];
            // 从_enemyPlaneArray集合中删除敌机CALayer
            [_enemyPlaneArray removeObjectAtIndex:i];
        }
    }
    
    // 遍历所有的子弹
    for (int i = 0; i < _bulletArray.count; i++) {
        // 处理第i颗子弹
        CALayer * bullet = _bulletArray[i];
        CGPoint bulletPosition = bullet.position;
        // 遍历所有的敌机
        for (int j = 0; j < _enemyPlaneArray.count; j++) {
            CALayer * enemyPlane = _enemyPlaneArray[j];
            CGPoint enemyPlanePosition = enemyPlane.position;
            // 如果敌机与子弹发生了碰撞
            if (CGRectContainsPoint(enemyPlane.frame, bulletPosition)) {
                // 创建CALayer来显示爆炸效果
                CALayer * blastLayer = [CALayer layer];
                // 设置显示爆炸效果的CALayer的大小和位置
                blastLayer.frame = CGRectMake(enemyPlanePosition.x - 40, enemyPlanePosition.y - 20, 78, 72);
                // 设置爆炸效果CALayer显示的第一张图片
                blastLayer.contents = (id)_blastImageArray[0].CGImage;
                [self.view.layer addSublayer:blastLayer];
                // 以显示爆炸效果的CALayer、正在显示的图片索引创建Spirit对象
                Spirit * blast = [[Spirit alloc]initWithLayer:blastLayer imageIndex:0];
                [_blastArray addObject:blast];
                // 播放爆炸音效
                AudioServicesPlaySystemSound(_blastSound);
                // 控制0.6秒后删除该爆炸效果
                [self performSelector:@selector(removeBlast:) withObject:blast afterDelay:0.6];
                // 删除这颗子弹
                [_bulletArray removeObjectAtIndex:i];
                [bullet removeFromSuperlayer];
                // 删除这架敌机
                [_enemyPlaneArray removeObjectAtIndex:j];
                [enemyPlane removeFromSuperlayer];
                // 得分加10
                _score += 10;
                // 显示最新的得分
                _scoreLayer.string = [NSString stringWithFormat:@"累计得分:%ld",_score];
                // 跳出循环，重新判断下一颗子弹
                break;
            }
        }
    }
    _count++;
    // 控制_count为5的倍数时发射一颗子弹
    if (_count % 5 == 0) {
        // 创建代表子弹的CALayer
        CALayer * bulletLayer = [CALayer layer];
        bulletLayer.frame = CGRectMake(_myPlane.position.x - 12, _myPlane.position.y - 50, 25, 25);
        // 设置子弹图片
        bulletLayer.contents = (id)_bulletImage.CGImage;
        [self.view.layer addSublayer:bulletLayer];
        [_bulletArray addObject:bulletLayer];
    }
    // 控制_count为10的倍数时添加一架敌机
    if (_count % 10 == 0) {
        // 创建代表敌机的CALayer
        CALayer * enemyLayer = [CALayer layer];
        // 根据rand随机数添加不同的敌机
        int rand = arc4random() % 3;
        // 使用随机数来设置敌机的X坐标
        int randX = arc4random() % (_screenWidth - 40) + 20;
        switch (rand) {
            case 0:
                // 设置第一种敌机所使用的图片
                enemyLayer.contents = (id)_enemyPlaneImage_0.CGImage;
                enemyLayer.frame = CGRectMake(randX, -80, 65, 75);
                break;
            case 1:
                // 设置第二种敌机所使用的图片
                enemyLayer.contents = (id)_enemyPlaneImage_1.CGImage;
                enemyLayer.frame = CGRectMake(randX, -80, 88, 65);
                break;
            default:
                // 设置第三种敌机所使用的图片
                enemyLayer.contents = (id)_enemyPlaneImage_2.CGImage;
                enemyLayer.frame = CGRectMake(randX, -80, 66, 59);
                break;
        }
        [_enemyPlaneArray addObject:enemyLayer];
        [self.view.layer addSublayer:enemyLayer];
    }
}
// 重写该方法，控制手指移动时，飞机跟随手指移动
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    // 获取触碰点的坐标
    UITouch * touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    // 将飞机的X坐标移动到与手指触碰点的X坐标相同
    _myPlane.position = CGPointMake(touchPoint.x, _myPlane.position.y);
}
// 控制删除爆炸动画CALayer的方法
-(void)removeBlast:(Spirit*)blast{
    [_blastArray removeObject:blast];
    [blast.layer removeFromSuperlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
