//
//  ScnModel.swift
//  ARKitApp
//
//  Created by 623971951 on 2018/2/9.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import SceneKit
import CoreLocation

// 当使用lazy属性时，struct对象必须声明为var
// Cannot use mutating getter on immutable value: 'model' is a 'let' constant

class ScnModel: NSObject, NSCoding {
    var imgName: String!
    var scnName: String!
    var location: CLLocation?
    
    lazy var img: UIImage = {
        return UIImage(named: imgName)!
    }()
    
    lazy var scn: SCNScene = {
        return SCNScene(named: scnName)!
    }()
    lazy var node: AudioinARKitLocationNode = {
        
        let modelScene = SCNScene(named: scnName)!
        let cup = modelScene.rootNode.childNodes[0]
        let node = AudioinARKitLocationNode(location: location, node: cup)
        node.name = scnName
        let boundingBox = node.boundingBox
        let distance = boundingBox.max.distance(to: boundingBox.min)
        let base: Float = 0.8
        if distance > base {
            // 缩放模型, 初始化时,不错超出屏幕大小
            let scale = base / distance
            node.scale = SCNVector3(scale, scale, scale)
        }
        return node
        
    }()
    
    // "art.scnassets/cup/cup.scn"
    init(img: String, scn: String) {
        
        self.imgName = img
        self.scnName = scn
    }
    
    // 归档
    func encode(with aCoder: NSCoder) {
        aCoder.encode(imgName, forKey: "imgName")
        aCoder.encode(scnName, forKey: "scnName")
        aCoder.encode(location, forKey: "location")
//        aCoder.encode(node, forKey: "node")
    }
    // 解档
    required init?(coder aDecoder: NSCoder) {
        if let imgName = aDecoder.decodeObject(forKey: "imgName") as? String{
            self.imgName = imgName
        }
        if let v = aDecoder.decodeObject(forKey: "scnName") as? String{
            scnName = v
        }
        if let v = aDecoder.decodeObject(forKey: "location") as? CLLocation{
            location = v
        }
//        if let v = aDecoder.decodeObject(forKey: "node") as? AudioinARKitLocationNode{
//            node = v
//        }
    }
}

