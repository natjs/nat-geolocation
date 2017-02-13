//
//  NatGeo.h
//  WeexDemo
//
//  Created by HOOLI-008 on 17/1/7.
//  Copyright © 2017年 taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^NatCallback)(id error,id result);


@interface NatGeoLocation : NSObject<CLLocationManagerDelegate>

+ (id)singletonManger;
//获取一次地理位置
- (void)get:(NatCallback)back;
//持续获取地理位置
- (void)watch:(NSDictionary *)options :(NatCallback)back;
//清除持续定位
- (void)clearWatch:(NatCallback)back;
//关闭
- (void)close;
@end
