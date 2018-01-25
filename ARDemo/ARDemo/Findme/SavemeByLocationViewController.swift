//
//  SavemeByLocationViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/24.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

class SavemeByLocationViewController: UIViewController {
    
    private lazy var locationService: LocationService = {
        return LocationService()
    }()
    
    private var lastPosition: SCNVector3?
    
    private var sceneView: ARSCNView!
    private var videoRecodeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "保存 findme + spitfire"
        self.view.backgroundColor = UIColor.white
        
        // 录像
        videoRecodeBtn = UIButton(type: UIButtonType.system)
        videoRecodeBtn.setTitle("开始", for: UIControlState.normal)
        videoRecodeBtn.setTitle("结束", for: UIControlState.selected)
        videoRecodeBtn.addTarget(self, action: #selector(self.recordBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        let recordBarBtnItem = UIBarButtonItem(customView: videoRecodeBtn)
        self.navigationItem.rightBarButtonItem = recordBarBtnItem
        
        // 获取位置信息
        locationService.startLocation()
        
        // arkit
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        // 添加开始节点
        let sphere = SCNSphere(radius: 0.01)
        let startNode = SCNNode(geometry: sphere)
        startNode.position = SCNVector3(x: 0, y: 0, z: 0)
        startNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        
        self.sceneView.scene.rootNode.addChildNode(startNode)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 获取当前位置
        if locationService.currentLocation != nil {
            // 结束定位, 省电
            locationService.stopLocation()
        }
        // 开始录制
        sessionRun()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        // session
        sceneView.session.pause()
        
        // 结束定位
        locationService.stopLocation()
        
        // 获取当前位置
        if let location = locationService.currentLocation {
            // 保存
            lastLocation = location
            singleScene = sceneView.scene
        }
    }
    private func sessionRun(){
        let configure = ARWorldTrackingConfiguration()
        configure.worldAlignment = .gravityAndHeading
        sceneView.session.run(configure, options: [ARSession.RunOptions.removeExistingAnchors, .resetTracking])
    }
    @objc func recordBtnAction(sender: Any?){
        
        videoRecodeBtn.isSelected = !videoRecodeBtn.isSelected
        
        if videoRecodeBtn.isSelected {
            // 获取当前位置
            if locationService.currentLocation != nil {
                // 结束定位, 省电
                locationService.stopLocation()
            }
            // 开始录制
            sessionRun()
        }else{
            // 结束录制
            guard self.lastPosition != nil else { return }
            // FIXME: add node / route
            let sphere = SCNSphere(radius: 0.1)
            let endNode = SCNNode(geometry: sphere)
            endNode.position = self.lastPosition!
            endNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            self.sceneView.scene.rootNode.addChildNode(endNode)
            
            self.lastPosition = nil
        }
    }
}

extension SavemeByLocationViewController: ARSCNViewDelegate{
    // MARK: SCN Scene Renderer Delegate 代理
}
