//
//  LocationTextAnnotationNode.swift
//  ARDemo
//
//  Created by 623971951 on 2018/2/5.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import SceneKit
import CoreLocation

class LocationTextAnnotationNode: LocationNode {
    
    ///Subnodes and adjustments should be applied to this subnode
    ///Required to allow scaling at the same time as having a 2D 'billboard' appearance
    public let annotationNode: SCNNode
    
    public init(location: CLLocation?, color: UIColor, text: String) {
        
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = color //整個小球都是橘色的
        
        let sphere = SCNSphere(radius: 0.05) // 1 cm 的小球幾何形狀
        sphere.firstMaterial = sphereMaterial
        
        let sphereNode = SCNNode(geometry: sphere) // 創建了一個球狀的節點
        
        // 文字
        let textGeo = SCNText(string: text, extrusionDepth: 0)
        textGeo.alignmentMode = kCAAlignmentCenter
        textGeo.firstMaterial?.diffuse.contents = UIColor.black
        textGeo.firstMaterial?.specular.contents = UIColor.white
        textGeo.firstMaterial?.isDoubleSided = true
        textGeo.font = UIFont(name: "Futura", size: 0.5)
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = .Y
        
        annotationNode = SCNNode()
        annotationNode.addChildNode(sphereNode)
        annotationNode.addChildNode(textNode)
        
        
        super.init(location: location)
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
        
        addChildNode(annotationNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
