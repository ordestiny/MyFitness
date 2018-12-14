//
//  CounterViewController.m
//  MyFitness
//
//  Created by Rick Wang on 2018/12/10.
//  Copyright © 2018 KMZJ. All rights reserved.
//

#import "CounterViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <BMKLocationkit/BMKLocationComponent.h>
#import <BaiduMapAPI_Utils/BMKGeometry.h>
#import <BaiduTraceSDK/BaiduTraceSDK.h>
#import <Masonry/Masonry.h>
#import <Toast/Toast.h>
#import <AVOSCloud/AVOSCloud.h>
#import "TransportModeEnum.h"
#import "MZTimerLabel.h"
#import "AppStyleSetting.h"
#import "CircleProgressButton.h"
#import "TrackDetailViewController.h"
#import "UIColor+UIColor_Hex.h"
#import "UIDevice+Type.h"

@interface CounterViewController ()<BTKTraceDelegate, BMKLocationManagerDelegate>

@property (nonatomic, strong) UIButton *backBtn;

@property (nonatomic, strong) UILabel *modeLabel;

@property (nonatomic, strong) UIView *topContainerView;

@property (nonatomic, strong) BMKLocationManager *locationManager;
	
@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) MZTimerLabel *timeCountingLabel;

@property (nonatomic, strong) UILabel *speedLabel;

@property (nonatomic, strong) UILabel *distanceLabel;

@property (nonatomic, strong) UILabel *disUnitLabel;

@property (nonatomic, strong) UIButton *pauseBtn;

@property (nonatomic, strong) UIButton *resumeBtn;

@property (nonatomic, strong) CircleProgressButton *stopBtn;

@property (nonatomic, assign) CGFloat centerOriginX;

@property (nonatomic, assign) CGFloat centerOriginY;

@property (nonatomic, assign) CGFloat resumeOriginX;

@property (nonatomic, assign) CGFloat resumeOriginY;

@property (nonatomic, assign) CGFloat stopOriginX;

@property (nonatomic, assign) CGFloat stopOriginY;

@property (nonatomic, strong) UIImageView *roundView;

@property (nonatomic, assign) TransportModeEnum transportMode;

@property (nonatomic, assign) NSInteger number;

@property (nonatomic, strong) NSTimer *timer;
	
@property (nonatomic, assign) BOOL firstLoad;
	
@property (nonatomic, strong) BMKLocation *lastLocation;
	
@property (nonatomic, strong) BMKLocation *currentLocation;
	
@property (nonatomic, assign) CLLocationDistance distance;
	
@property (nonatomic, strong) NSDate *startDate;
	
@property (nonatomic, strong) NSDate *finishDate;

// m/s
@property (nonatomic, assign) CLLocationSpeed speed;
	
@property (nonatomic, strong) AVObject *trackRecord;
	
@end

@implementation CounterViewController

#pragma  mark - Init
	
- (instancetype)init{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		_transportMode = TransportModeWalking;
		[self initValueProperty];
	}
	return self;
}
	
- (instancetype)initWithTransportMode:(TransportModeEnum)mode{
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		_transportMode = mode;
		[self initValueProperty];
	}
	return self;
}
	
#pragma mark - Init Property
	
- (void)initValueProperty{
	_number = 3;
	_firstLoad = YES;
	_lastLocation = [[BMKLocation alloc] init];
	_currentLocation = [[BMKLocation alloc]init];
	_distance = 0;
	_startDate = [NSDate date];
	_finishDate = [NSDate new];
	_speed = 0;
}
	
- (void)initlocationManager{
	_locationManager = [[BMKLocationManager alloc] init];
	_locationManager.delegate = self;
	_locationManager.coordinateType = BMKLocationCoordinateTypeBMK09LL;
	_locationManager.distanceFilter = 5.0;
	_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	_locationManager.activityType = CLActivityTypeAutomotiveNavigation;
	_locationManager.pausesLocationUpdatesAutomatically = NO;
	_locationManager.allowsBackgroundLocationUpdates = YES;
	_locationManager.locationTimeout = 10;
	_locationManager.reGeocodeTimeout = 10;
}
	
#pragma mark - Lift Circle
	
- (void)loadView{
	UIView *mainView = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
	mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	mainView.backgroundColor = [UIColor whiteColor];
	self.view = mainView;
}
	
- (void)viewDidLoad {
	[super viewDidLoad];
	self.automaticallyAdjustsScrollViewInsets = NO;
	self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
	
	[self initlocationManager];
	[self initBackgroundView];
	[self initTopContainerView];
	[self initPauseBtn];
	
	[self initDistanceLabel];
	[self initTimeCountingLabel];
	[self initSpeedLabel];
	
	// Do any additional setup after loading the view.
}
	
- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:NO];
}
	
- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	_centerOriginX = self.view.frame.size.width / 2 - 45;
	_centerOriginY = self.view.frame.size.height - 80 - 90;
	
	_resumeOriginX = self.view.frame.size.width / 2 - 30 - 90;
	_resumeOriginY = self.view.frame.size.height - 80 - 90;
	
	_stopOriginX = self.view.frame.size.width / 2 + 30;
	_stopOriginY = self.view.frame.size.height - 80 - 90;
	
	[self initResumeBtn];
	[self initStopBtn];
	
	// 第一次加载的时候默认开始
	if (_firstLoad) {
		_firstLoad = NO;
		[_timeCountingLabel start];
		[_locationManager startUpdatingLocation];
		[self startService];
	}
}
	
- (void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	[self.navigationController setNavigationBarHidden:NO animated:NO];
}
	
#pragma mark - Animation
	
	
#pragma mark - Init Views

- (void)initBackgroundView{
	_backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
	_backgroundView.backgroundColor = [UIColor colorWithHexString:@"#f0c800"];
	[self.view addSubview:_backgroundView];
}

- (void)initTopContainerView{
	_topContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
	[self.view addSubview:_topContainerView];
	
	[_topContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
		if ([[UIDevice currentDevice] fullScreen]){
			make.top.equalTo(self.view).offset(44);
		}
		else{
			make.top.equalTo(self.view).offset(20);
		}
		make.left.right.equalTo(self.view);
		make.height.equalTo(@44);
	}];
	
	_backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
	[_backBtn setImage:[UIImage imageNamed:@"left_25#00"] forState:UIControlStateNormal];
	[_backBtn addTarget:self action:@selector(backBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
	[_topContainerView addSubview:_backBtn];
	
	[_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
		make.left.equalTo(self.topContainerView).offset(8);
		make.centerY.equalTo(self.topContainerView);
		make.width.height.equalTo(@40);
	}];
	
	_modeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 25)];
	_modeLabel.textColor = AppStyleSetting.sharedInstance.textColor;
	_modeLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
	switch (_transportMode) {
		case TransportModeWalking:
			_modeLabel.text = @"健走";
			break;
		case TransportModeRunning:
			_modeLabel.text = @"跑步";
			break;
		case TransportModeRiding:
			_modeLabel.text = @"骑行";
			break;
		default:
			break;
	}
	[_topContainerView addSubview:_modeLabel];
	
	[_modeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.center.equalTo(self.topContainerView);
		make.height.equalTo(@25);
	}];
}

- (void)initDistanceLabel{
	_distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
	_distanceLabel.text = @"0.00";
	_distanceLabel.font = [UIFont systemFontOfSize:100];
	_distanceLabel.textColor = [UIColor whiteColor];
	[self.view addSubview:_distanceLabel];
	
	[_distanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.topContainerView.mas_bottom).offset(70);
		make.centerX.equalTo(self.backgroundView).offset(-10);
		make.height.equalTo(@90);
	}];
	
	_disUnitLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 25)];
	_disUnitLabel.text = @"公里";
	_disUnitLabel.textColor = UIColor.whiteColor;
	_disUnitLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
	[self.view addSubview:_disUnitLabel];
	
	[_disUnitLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.left.equalTo(self.distanceLabel.mas_right).offset(5);
		make.bottom.equalTo(self.distanceLabel).offset(-5);
		make.width.equalTo(@50);
		make.height.equalTo(@25);
	}];
}

- (void)initTimeCountingLabel{
	_timeCountingLabel = [[MZTimerLabel alloc] initWithTimerType:MZTimerLabelTypeStopWatch];
	_timeCountingLabel.frame = CGRectMake(0, 0, 100, 26);
	_timeCountingLabel.textColor = UIColor.whiteColor;
	_timeCountingLabel.timeFormat = @"mm:ss";
	_timeCountingLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
	[_backgroundView addSubview:self.timeCountingLabel];
	
	[_timeCountingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.distanceLabel.mas_bottom).offset(70);
		make.centerX.equalTo(self.view.mas_centerX).offset(-100);
		make.height.equalTo(@26);
	}];
	
	UILabel *displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 18)];
	displayLabel.text = @"用时";
	displayLabel.textColor = UIColor.whiteColor;
	displayLabel.font = [UIFont systemFontOfSize:25 weight:UIFontWeightSemibold];
	[self.backgroundView addSubview:displayLabel];
	
	[displayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.timeCountingLabel.mas_bottom).offset(15);
		make.centerX.equalTo(self.timeCountingLabel);
		make.height.equalTo(@25);
	}];
}

- (void)initSpeedLabel{
	_speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 26)];
	_speedLabel.text = @"0";
	_speedLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
	_speedLabel.textColor = UIColor.whiteColor;
	[_backgroundView addSubview:self.speedLabel];
	
	[_speedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.distanceLabel.mas_bottom).offset(70);
		make.centerX.equalTo(self.view.mas_centerX).offset(100);
		make.height.equalTo(@26);
	}];
	
	UILabel *displayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 18)];
	displayLabel.text = @"km/h";
	displayLabel.textColor = UIColor.whiteColor;
	displayLabel.font = [UIFont systemFontOfSize:25 weight:UIFontWeightSemibold];
	[self.backgroundView addSubview:displayLabel];
	
	[displayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.speedLabel.mas_bottom).offset(15);
		make.centerX.equalTo(self.speedLabel);
		make.height.equalTo(@25);
	}];
}
	
- (void)initPauseBtn{
	CGFloat bottomXcenter = self.view.center.x - 45;
	CGFloat originY = self.view.bounds.size.height - 80 - 90;
	_pauseBtn = [[UIButton alloc] initWithFrame:CGRectMake(bottomXcenter, originY, 90, 90)];
	_pauseBtn.backgroundColor = AppStyleSetting.sharedInstance.mainColor;
	[_pauseBtn setImage:[UIImage imageNamed:@"pause_25#ff"] forState:UIControlStateNormal];
	[_pauseBtn addTarget:self action:@selector(pauseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
	_pauseBtn.layer.cornerRadius = 45;
	_pauseBtn.clipsToBounds = YES;
	[self.view addSubview:_pauseBtn];
}
	
- (void)initResumeBtn{
	_resumeBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.centerOriginX, self.centerOriginY, 90, 90)];
	_resumeBtn.backgroundColor = AppStyleSetting.sharedInstance.mainColor;
	[_resumeBtn setImage:[UIImage imageNamed:@"play_25#ff"] forState:UIControlStateNormal];
	[_resumeBtn addTarget:self action:@selector(resumeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
	_resumeBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
	_resumeBtn.layer.cornerRadius = 45;
	_resumeBtn.clipsToBounds = YES;
	_resumeBtn.alpha = 0;
	[self.view addSubview:_resumeBtn];
}
	
- (void)initStopBtn{
	_stopBtn = [[CircleProgressButton alloc] initWithFrame:CGRectMake(self.centerOriginX, self.centerOriginY, 90, 90)];
	[_stopBtn setProgressBtnBackgroundColor:[UIColor colorWithHexString:@"#e43e45"]];
	[_stopBtn setProgressColor:UIColor.whiteColor];
	__weak typeof(self) weakSelf = self;
	_stopBtn.longPressedBlock = ^{
		[weakSelf stopBtnClicked];
	};
	_stopBtn.alpha = 0;
	[self.view addSubview:_stopBtn];
}
	
#pragma mark - Action

- (void)backBtnClicked:(UIButton*)sender{
	[self.navigationController popViewControllerAnimated:YES];
}
	
- (void)startService{
	NSString *userName = [AVUser currentUser].username;
	BTKStartServiceOption *opt = [[BTKStartServiceOption alloc] initWithEntityName:userName];
	[[BTKAction sharedInstance] startService:opt delegate:self];
	[[BTKAction sharedInstance] startGather:self];
	[self.view makeToast:@"开始服务并开始采集轨迹"];
}
	
- (void)stopGather{
	[[BTKAction sharedInstance] stopGather:self];
	[self.view makeToast:@"停止采集轨迹"];
}
	
- (void)startGather{
	[[BTKAction sharedInstance] startGather:self];
	[self.view makeToast:@"开始采集轨迹"];
}
	
- (void)stopService{
	[[BTKAction sharedInstance] stopGather:self];
	[[BTKAction sharedInstance] stopService:self];
	[self.view makeToast:@"关闭轨迹采集服务"];
}
	
- (void)constructTrackRecord{
	_trackRecord = [AVObject objectWithClassName:@"TrackRecord"];
	
	double timeInterval = [_timeCountingLabel getTimeCounted];
	double minDouble = timeInterval / 60;
	int minFloor = floor(minDouble);
	int secRound = round(timeInterval - (minFloor * 60));
	
	NSMutableString *formattString = [NSMutableString stringWithString:@"%d:%d"];
	if (minFloor < 10) {
		formattString = [NSMutableString stringWithString:@"0%d:%d"];
		
		if (secRound < 10) {
			formattString = [NSMutableString stringWithString:@"0%d:0%d"];
		}
	}
	
	NSMutableString *minuteString = [NSMutableString stringWithFormat:formattString,minFloor, secRound];
	
	CLLocationSpeed avgSpeed = (_distance / 1000) / (minDouble / 60);
	double calorie = 41 * _distance / 1000;
	double carbon = 115 * _distance / 1000;
	double intervalKm = timeInterval / (_distance / 1000);
	
	[_trackRecord setObject:[AVUser currentUser] forKey:@"user"];
	[_trackRecord setObject:_startDate forKey:@"startTime"];
	[_trackRecord setObject:_finishDate forKey:@"finishedTime"];
	[_trackRecord setObject:[NSNumber numberWithDouble:timeInterval] forKey:@"interval"];
	[_trackRecord setObject:minuteString forKey:@"minuteString"];
	[_trackRecord setObject:[NSNumber numberWithDouble:_distance] forKey:@"mileage"];
	[_trackRecord setObject:[NSNumber numberWithDouble: avgSpeed] forKey:@"avgSpeed"];
	[_trackRecord setObject:[NSNumber numberWithDouble:intervalKm] forKey:@"paceSpeed"];
	[_trackRecord setObject:[NSNumber numberWithDouble:calorie] forKey:@"calorie"];
	[_trackRecord setObject:[NSNumber numberWithDouble:carbon] forKey:@"carbonSaving"];
	[_trackRecord setObject:[NSNumber numberWithInt: _transportMode] forKey:@"transportMode"];
}
	
- (void)saveTrackRecord{
	// 构造轨迹记录模型
	[self constructTrackRecord];
	
	[_trackRecord saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
		if (succeeded) {
			[self.view makeToast:@"记录保存成功"];
			// 打开轨迹记录的详细
			TrackDetailViewController *detailVC = [[TrackDetailViewController alloc] initWithStartTime:self.startDate FinishedTime:self.finishDate TransportMode:self.transportMode TrackId:self.trackRecord.objectId];
			[self.navigationController pushViewController:detailVC animated:YES];
		}
		else{
			if (error == nil) {
				[self.view makeToast:@"轨迹保存失败"];
				return;
			}
			
			[self.view makeToast:[NSString stringWithFormat:@"轨迹保存失败，%@", error.localizedDescription]];
		}
	}];
}

	
- (void)pauseBtnClicked:(UIButton*)sender{
	[_timeCountingLabel pause];
	_resumeBtn.alpha = 1;
	_stopBtn.alpha = 1;
	
	_currentLocation = nil;
	_lastLocation = nil;
	[_locationManager stopUpdatingLocation];
	[self stopGather];
	
	[UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.pauseBtn.alpha = 0;
		self.resumeBtn.frame = CGRectMake(self.resumeOriginX, self.resumeOriginY, 90, 90);
		self.stopBtn.frame = CGRectMake(self.stopOriginX, self.stopOriginY, 90, 90);
	} completion:^(BOOL finish){
		if (finish) {
			[self stopGather];
		}
	}];
}
	
- (void)resumeBtnClicked:(UIButton*)sender{
	[_timeCountingLabel start];
	
	[_locationManager startUpdatingLocation];
	[self startGather];
	
	[UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.pauseBtn.alpha = 1;
		self.resumeBtn.alpha = 0;
		self.stopBtn.alpha = 0;
		self.resumeBtn.frame = CGRectMake(self.centerOriginX, self.centerOriginY, 90, 90);
		self.stopBtn.frame = CGRectMake(self.centerOriginX, self.centerOriginY, 90, 90);
	} completion:^(BOOL finish){
		if (finish) {
			[self startGather];
		}
	}];
}
	
- (void)stopBtnClicked{
	_finishDate = [NSDate date];
	[self stopService];
	[_locationManager stopUpdatingLocation];
	
	//正式代码
	[self saveTrackRecord];
}
	
- (void)calculateDistance{
	CLLocation *last = _lastLocation.location;
	CLLocation *current = _currentLocation.location;
	CLLocationDistance pointsDistance = [current distanceFromLocation:last];
	if (pointsDistance > 0) {
		_distance += pointsDistance;
	}
}
	
- (void)refreshDisplayData{
	_distanceLabel.text = [NSString stringWithFormat:@"%.2f", _distance / 1000];
	_speedLabel.text = [NSString stringWithFormat:@"%.1f", _speed];
}
	
#pragma mark - BMKLocationManagerDelegate
	
// 更新定位的位置信息
- (void)BMKLocationManager:(BMKLocationManager *)manager didUpdateLocation:(BMKLocation *)location orError:(NSError *)error{
	
	if (error != nil) {
		NSLog(@"Location Error--%ld   detail==>%@",(long)error.code, error.localizedDescription);
	}
	
	if (location == nil) {
		[self.navigationController.view makeToast:@"定位失败"];
		return;
	}
	
	_lastLocation = _currentLocation;
	_currentLocation = location;
	_speed = fabs(_currentLocation.location.speed);
	[self calculateDistance];
	[self refreshDisplayData];
}
	
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end