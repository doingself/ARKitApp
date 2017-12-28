//
//  DoorARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/28.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit
import ARKit

class DoorARViewController: UIViewController {

    private var arSCNView: ARSCNView!
    private var arConfig: ARWorldTrackingConfiguration!
    private var planeNode: SCNNode!
    private var planeAnchor: ARPlaneAnchor!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "传送门"
        self.view.backgroundColor = UIColor.white
        
        arConfig = ARWorldTrackingConfiguration()
        // 平面检测
        arConfig.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        arConfig.isLightEstimationEnabled = true
        
        arSCNView = ARSCNView(frame: self.view.bounds)
        arSCNView.delegate = self
        arSCNView.automaticallyUpdatesLighting = true
        arSCNView.autoenablesDefaultLighting = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
extension DoorARViewController: ARSCNViewDelegate{
    
}
