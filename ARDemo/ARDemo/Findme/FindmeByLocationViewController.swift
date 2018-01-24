//
//  FindmeByLocationViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/24.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation


class FindmeByLocationViewController: UIViewController {
    
    
    private lazy var locationService: LocationService = {
        return LocationService()
    }()
    
    private var loadSingleScene: Bool = false
    // 纬度偏移量
    private var latitudeOffSet: Double = 0.0
    // 经度偏移量
    private var longitudeOffSet: Double = 0.0
    
    private var lastPosition: SCNVector3?
    
    private var sceneView: ARSCNView!
    private var videoRecodeBtn: UIButton!
    private var swit: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "findme + spitfire"
        self.view.backgroundColor = UIColor.white
        
        swit = UISwitch()
        let switBtn = UIBarButtonItem(customView: swit)
        // 录像
        videoRecodeBtn = UIButton(type: UIButtonType.system)
        videoRecodeBtn.setTitle("开始", for: UIControlState.normal)
        videoRecodeBtn.setTitle("结束", for: UIControlState.selected)
        videoRecodeBtn.addTarget(self, action: #selector(self.recordBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        let recordBarBtnItem = UIBarButtonItem(customView: videoRecodeBtn)
        let clear = UIBarButtonItem(title: "clear", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.clearAction(sender:)))
        self.navigationItem.rightBarButtonItems = [clear, switBtn, recordBarBtnItem]
        
        // 获取位置信息
        locationService.startLocation()
        
        // arkit
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        
        if singleScene != nil && lastLocation != nil{
            // 加载已有场景
            loadSingleScene = true
            swit.isOn = false
        }else{
            swit.isOn = true
            // 不加载已有场景
            loadSingleScene = false
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 获取当前位置
        if let location = locationService.currentLocation {
            if loadSingleScene {
                // 计算偏移量
                // 经度
                longitudeOffSet = location.coordinate.longitude - lastLocation.coordinate.longitude
                // 纬度
                latitudeOffSet = location.coordinate.latitude - lastLocation.coordinate.latitude
                
                // 加载已有场景
                sceneView.scene = singleScene
                
                // 移动
                let translation = MatrixHelper.transformMatrix(for: matrix_identity_float4x4, originLocation: lastLocation, location: location)
                let position = SCNVector3.positionFromTransform(translation)
                
                print("last location = \(lastLocation)")
                print("current location = \(location)")
                print("position = \(position)")
                for node in sceneView.scene.rootNode.childNodes{
                    print("node.position 0 = \(node.position)")
                    
                    node.position.x -= position.x
                    node.position.y -= position.y
                    node.position.z -= position.z
                    
                    print("node.position 1 = \(node.position)")
                }
            }
            // 结束定位, 省电
            locationService.stopLocation()
        }
        
        // session run
        sessionRun()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        // 结束定位
        locationService.stopLocation()
        
        // 获取当前位置
        guard let location = locationService.currentLocation else{
            print("current location is nil")
            return
        }
        if swit.isOn {
            // 保存
            lastLocation = location
            singleScene = sceneView.scene
        }
        // session
        sceneView.session.pause()
    }
    private func sessionRun(){
        let configure = ARWorldTrackingConfiguration()
        configure.worldAlignment = .gravityAndHeading
        sceneView.session.run(configure, options: [ARSession.RunOptions.removeExistingAnchors, .resetTracking])
    }
    @objc func clearAction(sender: Any?){
        // 清空
        lastLocation = nil
        singleScene = nil
    }
    @objc func recordBtnAction(sender: Any?){
        if loadSingleScene == true {
            // 加载了已有场景
            return
        }
        videoRecodeBtn.isSelected = !videoRecodeBtn.isSelected
        
        if videoRecodeBtn.isSelected {
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
            
            // 使用 keyed archiver 归档
            // 这里使用全局变量保存 scene
            singleScene = self.sceneView.scene
        }
    }
    private func addNode(){
        // 开始录制
        guard let pointOfView: SCNNode = self.sceneView.pointOfView else{ return }
        let current = pointOfView.position
        if lastPosition != nil{
            if lastPosition!.distance(vector: current) > 0.3 {
                
                let box = SCNBox(width: 0.1, height: 0.1, length: 0.3, chamferRadius: 0.0)
                let normaltNode = SCNNode(geometry: box)
                let action = SCNAction.rotateBy(
                    x: CGFloat(Float.pi/2.0*3.0),
                    y: CGFloat(Float.pi/4.0+atan2(current.x-self.lastPosition!.x, current.z-self.lastPosition!.z)),
                    z: 0,
                    duration: 0)
                normaltNode.runAction(action)
                
                normaltNode.position = current
                normaltNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                
                self.sceneView.scene.rootNode.addChildNode(normaltNode)
                
                self.lastPosition = current
            }
        }else{
            // 开始
            lastPosition = current
            // 添加开始节点
            let sphere = SCNSphere(radius: 0.1)
            let startNode = SCNNode(geometry: sphere)
            startNode.position = current
            startNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            
            self.sceneView.scene.rootNode.addChildNode(startNode)
        }
        glLineWidth(0)
    }
}
extension FindmeByLocationViewController: ARSCNViewDelegate{
    // MARK: SCN Scene Renderer Delegate 代理
    
    // MARK: ARSCNViewDelegate -> SCNSceneRendererDelegate 代理
    // 在SceneKit渲染场景内容之前自定义渲染内容
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        DispatchQueue.main.async {            
            if self.videoRecodeBtn.isSelected == true{
                self.addNode()
            }
        }
        
    }
}
