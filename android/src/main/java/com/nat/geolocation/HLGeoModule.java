package com.nat.geolocation;

import android.content.Context;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.CountDownTimer;
import java.util.HashMap;
import java.util.List;

/**
 * Created by xuqinchao on 17/1/7.
 * Copyright (c) 2017 Nat. All rights reserved.
 */

public class HLGeoModule{

    private LocationManager mWatchLocationManager;
    int maximumAge = 0;
    int timeout = 10000;
    String model = "highAccuracy";
    MyCountDownTimer countDownTimer;
    LocationListener mLocationListener;
    private Context mContext;
    private static volatile HLGeoModule instance = null;

    private HLGeoModule(Context context){
        mContext = context;
    }

    public static HLGeoModule getInstance(Context context) {
        if (instance == null) {
            synchronized (HLGeoModule.class) {
                if (instance == null) {
                    instance = new HLGeoModule(context);
                }
            }
        }

        return instance;
    }

    public void get(final HLModuleResultListener listener) {
        if (listener == null) return;
        if (mContext == null) {
            listener.onResult(HLConstant.HL_ERROR_NULL_CONTEXT);
            return;
        }

        final LocationManager locationManager = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
        List<String> providers = locationManager.getProviders(true);
        String locationProvider;
        if (providers.contains(LocationManager.PASSIVE_PROVIDER)) {
            locationProvider = LocationManager.PASSIVE_PROVIDER;
        } else if (providers.contains(LocationManager.GPS_PROVIDER)) {
            locationProvider = LocationManager.GPS_PROVIDER;
        } else if (providers.contains(LocationManager.NETWORK_PROVIDER)) {
            locationProvider = LocationManager.NETWORK_PROVIDER;
        } else {
            listener.onResult(HLUtil.getError(HLConstant.LOCATION_UNAVAILABLE, HLConstant.LOCATION_UNAVAILABLE_CODE));
            return;
        }

        Location location = locationManager.getLastKnownLocation(locationProvider);
        if (location != null) {
            listener.onResult(getLocationInfo(location));
            return;
        } else {
            locationManager.requestLocationUpdates(locationProvider, 0, 0, new LocationListener() {
                @Override
                public void onLocationChanged(Location location) {
                    listener.onResult(getLocationInfo(location));
                    locationManager.removeUpdates(this);
                    return;
                }

                @Override
                public void onStatusChanged(String provider, int status, Bundle extras) {

                }

                @Override
                public void onProviderEnabled(String provider) {

                }

                @Override
                public void onProviderDisabled(String provider) {

                }
            });
        }
    }

    public void watch(HashMap<String, Object> options, final HLModuleResultListener listener) {
        if (listener == null) return;
        if (mContext == null) {
            listener.onResult(HLConstant.HL_ERROR_NULL_CONTEXT);
            return;
        }

        if (mWatchLocationManager != null) {
            listener.onResult(HLUtil.getError(HLConstant.LOCATION_SERVICE_BUSY, HLConstant.LOCATION_SERVICE_BUSY_CODE));
            return;
        }

        try {
            maximumAge = options.containsKey("maximumAge") ? (int) options.get("maximumAge") : maximumAge;
            timeout = options.containsKey("timeout") ? (int) options.get("timeout") : timeout;
            model = options.containsKey("model") ? (String) options.get("model") : model;
        } catch (ClassCastException e) {
            e.printStackTrace();
            listener.onResult(HLUtil.getError(HLConstant.WATCH_LOCATION_INVALID_ARGUMENT, HLConstant.WATCH_LOCATION_INVALID_ARGUMENT_CODE));
        }

        mWatchLocationManager = (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
        Criteria crite = new Criteria();
        crite.setAccuracy(model.equals("highAccuracy")?Criteria.ACCURACY_FINE:Criteria.ACCURACY_COARSE); //精度
        crite.setPowerRequirement(Criteria.POWER_LOW); //功耗类型选择
        String provider = mWatchLocationManager.getBestProvider(crite, true);

        if (provider != null) {
            countDownTimer = new MyCountDownTimer(timeout, timeout, listener);
            countDownTimer.start();
            mLocationListener = new LocationListener() {
                @Override
                public void onLocationChanged(Location location) {
                    listener.onResult(getLocationInfo(location));
                    if (countDownTimer != null) {
                        countDownTimer.cancel();
                        countDownTimer.start();
                    }

                }

                @Override
                public void onStatusChanged(String s, int i, Bundle bundle) {

                }

                @Override
                public void onProviderEnabled(String s) {

                }

                @Override
                public void onProviderDisabled(String s) {

                }
            };
            mWatchLocationManager.requestLocationUpdates(provider, maximumAge, 0, mLocationListener);
        } else {
            listener.onResult(HLUtil.getError(HLConstant.LOCATION_UNAVAILABLE, HLConstant.LOCATION_UNAVAILABLE_CODE));
            return;
        }

    }

    public void clearWatch(HLModuleResultListener listener) {
        if (listener == null)return;
        if (mWatchLocationManager == null) {
            listener.onResult(HLUtil.getError(HLConstant.LOCATION_SERVICE_BUSY, HLConstant.LOCATION_SERVICE_BUSY_CODE));
            return;
        }
        if (mLocationListener != null) {
            mWatchLocationManager.removeUpdates(mLocationListener);
            mLocationListener = null;
            mWatchLocationManager = null;
        }
        if (countDownTimer != null) {
            countDownTimer.cancel();
            countDownTimer = null;
        }
        listener.onResult(null);
    }

    private HashMap<String, Object> getLocationInfo(Location location) {
        HashMap<String, Object> result = new HashMap<>();
        result.put("latitude", location.getLatitude());
        result.put("longitude", location.getLongitude());
        result.put("speed", location.getSpeed());
        result.put("accuracy", location.getAccuracy());
        return result;
    }

    class MyCountDownTimer extends CountDownTimer{
        HLModuleResultListener mListener;
        public MyCountDownTimer(long millisInFuture, long countDownInterval, HLModuleResultListener listener) {
            super(millisInFuture, countDownInterval);
            mListener = listener;
        }

        @Override
        public void onTick(long l) {

        }

        @Override
        public void onFinish() {
            if (mLocationListener != null && mWatchLocationManager != null) {
                mWatchLocationManager.removeUpdates(mLocationListener);
            }
            mWatchLocationManager = null;
            if (countDownTimer != null) {
                countDownTimer.cancel();
                countDownTimer = null;
            }
            mListener.onResult(HLUtil.getError(HLConstant.LOCATION_TIMEOUT, HLConstant.LOCATION_TIMEOUT_CODE));
        }
    }
}
