//
//  LocationService.swift
//  MapDemo
//
//  Created by 623971951 on 2018/1/18.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import CoreLocation

class LocationService: NSObject {
    
    var currentLocation: CLLocation?
    private var locationManager: CLLocationManager!
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        
        //设置定位服务管理器代理
        locationManager.delegate = self
        
        /*
         kCLLocationAccuracyBestForNavigation ：精度最高，一般用于导航
         kCLLocationAccuracyBest ： 精确度最佳
         kCLLocationAccuracyNearestTenMeters ：精确度10m以内
         kCLLocationAccuracyHundredMeters ：精确度100m以内
         kCLLocationAccuracyKilometer ：精确度1000m以内
         kCLLocationAccuracyThreeKilometers ：精确度3000m以内
         */
        //设置定位进度
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //定位准确度。distanceFilter表示更新位置的距离，假如超过设定值则进行定位更新，否则不更新。
        //kCLDistanceFilterNone表示不设置距离过滤，即随时更新地理位置
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        //发送授权申请
        locationManager.requestWhenInUseAuthorization()
    }
    // 开始定位
    func startLocation(){
        if (CLLocationManager.locationServicesEnabled())
        {
            //允许使用定位服务的话，开启定位服务更新
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    // 停止定位
    func stopLocation(){
        // 停止定位
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    // 地名 转 placemark
    private func cityToPlacemark(addressStr: String){
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressStr) { (placemarks:[CLPlacemark]?, error:Error?) -> Void in
            if error != nil {
                //print("city to placemark 错误：\(error!.localizedDescription))")
                return
            }
            if let p = placemarks?.first{
                let str = self.convertPlacemark(placemark: p)
                //print("city to placemark \(addressStr) \(str)")
            } else {
                //print("city to placemark No placemarks!")
            }
        }
    }
    // location 转 placemark 获取 地名
    private func locationToPlacemark(location: CLLocation){
        let geocode: CLGeocoder = CLGeocoder()
        geocode.reverseGeocodeLocation(location) { (placemarks:[CLPlacemark]?, error:Error?) -> Void in
            //强制转成简体中文
            let array = NSArray(object: "zh-hans")
            UserDefaults.standard.set(array, forKey: "AppleLanguages")
            //显示所有信息
            if error != nil {
                //print("location to placemark 错误：\(error!.localizedDescription))")
                return
            }
            
            if let p = placemarks?.first {
                //输出反编码信息
                let str = self.convertPlacemark(placemark: p)
                //print("location to placemark \(str)")
            } else {
                //print("location to placemark No placemarks!")
            }
        }
    }
    // location 转 string
    private func convertLocation(location: CLLocation) -> String{
        var str = ""
        str.append("经度：\(location.coordinate.longitude)\n")
        //获取纬度
        str.append("纬度：\(location.coordinate.latitude)\n")
        //获取海拔
        str.append("海拔：\(location.altitude)\n")
        //获取水平精度
        str.append("水平精度：\(location.horizontalAccuracy)\n")
        //获取垂直精度
        str.append("垂直精度：\(location.verticalAccuracy)\n")
        //获取方向
        str.append("方向：\(location.course)\n")
        //获取速度
        str.append("速度：\(location.speed)\n")
        return str
    }
    // placemark 转 string
    private func convertPlacemark(placemark: CLPlacemark) -> String{
        var address = ""
        address.append(convertLocation(location: placemark.location!))
        
        if let country = placemark.country {
            address.append("国家：\(country)\n")
        }
        if let administrativeArea = placemark.administrativeArea {
            address.append("省份：\(administrativeArea)\n")
        }
        if let subAdministrativeArea = placemark.subAdministrativeArea {
            address.append("其他行政区域信息（自治区等）：\(subAdministrativeArea)\n")
        }
        if let locality = placemark.locality {
            address.append("城市：\(locality)\n")
        }
        if let subLocality = placemark.subLocality {
            address.append("区划：\(subLocality)\n")
        }
        if let thoroughfare = placemark.thoroughfare {
            address.append("街道：\(thoroughfare)\n")
        }
        if let subThoroughfare = placemark.subThoroughfare {
            address.append("门牌：\(subThoroughfare)\n")
        }
        if let name = placemark.name {
            address.append("地名：\(name)\n")
        }
        if let isoCountryCode = placemark.isoCountryCode {
            address.append("国家编码：\(isoCountryCode)\n")
        }
        if let postalCode = placemark.postalCode {
            address.append("邮编：\(postalCode)\n")
        }
        if let areasOfInterest = placemark.areasOfInterest {
            address.append("关联的或利益相关的地标：\(areasOfInterest)\n")
        }
        if let ocean = placemark.ocean {
            address.append("海洋：\(ocean)\n")
        }
        if let inlandWater = placemark.inlandWater {
            address.append("水源，湖泊：\(inlandWater)\n")
        }
        return address
    }
}

extension LocationService: CLLocationManagerDelegate{
    // MARK: CL location manager delegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //did update heading newHeading=magneticHeading 17.63 trueHeading -1.00 accuracy 25.00 x -5.680 y +18.537 z -28.310 @ 2018-01-18 03:32:35 +0000
        ////print("did update heading newHeading=\(newHeading)")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print("did update locations \(locations.count) \(locations)")
        
        //获取坐标
        guard let currLoca:CLLocation = locations.last else{ return }
        currentLocation = currLoca
        //打印经纬度
        var str = convertLocation(location: currLoca)
        //print("did update locations.last \(str)")
        
        //获取坐标
        guard let managerLocation:CLLocation = manager.location else{ return }
        currentLocation = managerLocation
        //打印经纬度
        str = convertLocation(location: managerLocation)
        //print("did update manager.location \(str)")
        
        // location 转 placemark 获取 地名
        locationToPlacemark(location: managerLocation)
        // 根据 地名 获取 经纬度
        cityToPlacemark(addressStr: "北京体育馆")
    }
}
