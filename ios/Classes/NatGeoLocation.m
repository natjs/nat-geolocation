//
//  NatGeolocation.m
//
//  Created by huangyake on 17/1/7.
//  Copyright © 2017 Nat. All rights reserved.
//

#import "NatGeolocation.h"


@interface NatGeolocation ()

{
    NSTimer *timer;
    BOOL success;
}
@property (nonatomic, strong)NatCallback callback;
@property(nonatomic, strong)CLLocationManager* locationManager;
@property(nonatomic, assign)NSInteger isget; //get方法为0 watch 方法为1
@property(nonatomic, strong)NSDictionary *options;
@property(nonatomic, assign)NSInteger maximumAge;
@property(nonatomic, strong)NSDate *lastDate;//上次返回时间
@property(nonatomic, assign)NSInteger timeOut;//设置超时

@end

@implementation NatGeolocation




+ (NatGeoLocation *)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)clearWatch:(NatCallback)back{
    [self.locationManager stopUpdatingLocation];
    self.locationManager = nil;
    self.isget = 0;
    back(nil,@"");
}


- (void)watch:(NSDictionary *)options :(NatCallback)back{
    success = NO;
    if (self.isget == 1) {
        back(@{@"error":@{@"code":@160030,@"msg":@"LOCATION_SERVICE_BUSY"}},nil);
        return;
    }
    
    if (options) {
        if (options[@"maximumAge"] && ![options[@"maximumAge"] isKindOfClass:[NSNumber class]]) {
        back(@{@"error":@{@"code":@160041,@"msg":@"WATCH_LOCATION_INVALID_ARGUMENT"}},nil);
            
            return;
        }
        
        if (options[@"timeout"] && ![options[@"timeout"] isKindOfClass:[NSNumber class]]) {
            back(@{@"error":@{@"code":@160041,@"msg":@"WATCH_LOCATION_INVALID_ARGUMENT"}},nil);
            
            return;
        }
        
        if ([options[@"maximumAge"] integerValue]) {
            self.maximumAge = [options[@"maximumAge"] integerValue];
        }
        if ([options[@"timeout"] integerValue]) {
            self.timeOut = [options[@"timeout"] integerValue];
        }
    }
    self.options = options;
    self.callback = back;
    self.isget = 1;
    self.locationManager = [[CLLocationManager alloc] init];
    BOOL enable=[CLLocationManager locationServicesEnabled];
    //是否具有定位权限
    int status=[CLLocationManager authorizationStatus];
    if(!enable || status<3)
    {
        //请求权限
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8)
        {
            //由于IOS8中定位的授权机制改变 需要进行手动授权
            self.locationManager.delegate = self;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//            self.locationManager
            //获取授权认证
            //            [locationManager requestAlwaysAuthorization];
            [self.locationManager requestWhenInUseAuthorization];
            
            
            [self.locationManager startUpdatingLocation];
        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"无法定位到您所在的城市，请前去开启GPS定位"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"取消",@"去设置", nil];
            alertView.tag = 1000;
            [alertView show];
            self.callback(@{@"error":@{@"msg":@"LOCATION_PERMISSION_DENIED",@"code":@160020}},nil);

        }
        
        
    }else{
        
        self.locationManager.delegate = self;
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
         timer = [NSTimer scheduledTimerWithTimeInterval:self.timeOut/1000.000 target:self selector:@selector(locationSuccess) userInfo:nil repeats:YES];
//        [self.locationManager requestLocation];
    }
    

}
- (void)get:(NatCallback)back{
    self.callback = back;
    self.isget = 0;
   self.locationManager = [[CLLocationManager alloc] init];
    BOOL enable=[CLLocationManager locationServicesEnabled];
    //是否具有定位权限
    int status=[CLLocationManager authorizationStatus];
    if(!enable || status<3)
    {
        //请求权限
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8)
        {
            //由于IOS8中定位的授权机制改变 需要进行手动授权
            self.locationManager.delegate = self;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            //获取授权认证
            //            [locationManager requestAlwaysAuthorization];
            [self.locationManager requestWhenInUseAuthorization];
            
            
            [self.locationManager startUpdatingLocation];
        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"无法定位到您所在的城市，请前去开启GPS定位"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"取消",@"去设置", nil];
            alertView.tag = 1000;
            [alertView show];
            self.callback(@{@"error":@{@"msg":@"LOCATION_PERMISSION_DENIED",@"code":@160020}},nil);
        }
        
        
    }else{
       
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
    }

    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        
    }
    
    else
    {
        [self jumpSetting];
    }
    
}

- (void)jumpSetting
{
    //打开设置页面，去设置定位
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
        
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    // 1.获取用户位置的对象
    CLLocation *location = [locations lastObject];
    CLLocationCoordinate2D coordinate = location.coordinate;
    // 2.停止定位
    if (self.isget == 0) {
        [manager stopUpdatingLocation];
        self.locationManager = nil;
    }
    if (self.timeOut) {
        success = YES;
    }
    
    if (self.maximumAge) {
        if (self.lastDate && [self.lastDate timeIntervalSince1970]*1000.0 + self.maximumAge > [[NSDate date] timeIntervalSince1970] * 1000.0) {
            
        }else{
            self.lastDate = [NSDate date];
        self.callback(nil,@{@"latitude":@(coordinate.latitude),@"longitude":@(coordinate.longitude),@"speed":@(location.speed),@"accuracy":@(location.verticalAccuracy)});
 
        }
    }else{
       self.callback(nil,@{@"latitude":@(coordinate.latitude),@"longitude":@(coordinate.longitude),@"speed":@(location.speed),@"accuracy":@(location.verticalAccuracy)});
  
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied) {
        // 提示用户出错原因，可按住Option键点击 KCLErrorDenied的查看更多出错信息，可打印error.code值查找原因所在
        self.callback(@{@"error":@{@"msg":@"LOCATION_UNAVAILABLE",@"code":@160070}},nil);
    }else if(error.code == kCLErrorNetwork){
        self.callback(@{@"error":@{@"msg":@"LOCATION_NETWORK_ERROR",@"code":@160070}},nil);
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {    switch (status) {
    case kCLAuthorizationStatusNotDetermined:
        break;
    default:
        break;
}}


- (void)close{
    self.isget = 0;
}


- (void)locationSuccess{
    if (!success) {
        self.callback(@{@"error":@{@"msg":@"LOCATION_TIMEOUT",@"code":@160080}},nil);
        [self.locationManager stopUpdatingLocation];
        self.locationManager = nil;
        self.isget = 0;
    }
    [timer invalidate];
    timer = nil;
}


@end
