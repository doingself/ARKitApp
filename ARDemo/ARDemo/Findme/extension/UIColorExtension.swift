//
//  UIColorExtension.swift
//  Findme
//
//  Created by zhengperry on 2017/10/4.
//  Copyright © 2017年 mmoaay. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    // 随机颜色
    class func randomColor() -> UIColor{
        let r = CGFloat(arc4random_uniform(256))/255
        let g = CGFloat(arc4random_uniform(256))/255
        let b = CGFloat(arc4random_uniform(256))/255
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIColor {

    convenience init(hexColor: String) {
        var red:UInt32 = 0, green:UInt32 = 0, blue:UInt32 = 0
        
        Scanner(string: hexColor[0..<2]).scanHexInt32(&red)
        Scanner(string: hexColor[2..<4]).scanHexInt32(&green)
        Scanner(string: hexColor[4..<6]).scanHexInt32(&blue)
        
        self.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1.0)
    }
}
