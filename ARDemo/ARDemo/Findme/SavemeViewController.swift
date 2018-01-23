//
//  SavemeViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/23.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

// 保存轨迹, 可以通过 key archive 归档
var meScene: SCNScene!


// find me 保存设备运动轨迹并查看 https://github.com/mmoaay/Findme
// 思路: 运动过程中 添加 node 到 ARSCNView.scene.rootNode.childeNodes 中, 将当前 ARSCNView.scene 保存到起来( SCNScene ), 使用空白页面的 ARSCNView 加载已经保存的 SCNScene
class SavemeViewController: UIViewController {
    
    private var sceneView: ARSCNView!
    private var previewNode: PreviewNode?
    private var swit: UISwitch!
    
    // 中心
    private var screenCenter: CGPoint = .zero
    // 检测到地面或者被拖拽, 取消 update at time
    private var hasPlaneOrGesture = false
    // 是否选中模型,用于 拖拽 / 旋转
    private var selectModel = false
    // 拖拽
    private var pinchBeginNodeScaleX: Float = 0.0
    
    // 录像
    private var videoRecodeBtn: UIButton!

    private var lastPosition: SCNVector3?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "保存设备的运动轨迹 运动过程中 添加 node 到 ARSCNView.scene.rootNode.childeNodes 中, 将当前 ARSCNView.scene 保存到起来( SCNScene )"
        self.view.backgroundColor = UIColor.white
        
        let save = UIBarButtonItem(title: "保存", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.saveBarBtnItemAction(sender:)))
        let reset = UIBarButtonItem(title: "复位", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.resetBarBtnItemAction(sender:)))
        swit = UISwitch()
        let switBtn = UIBarButtonItem(customView: swit)
        // 录像
        videoRecodeBtn = UIButton(type: UIButtonType.system)
        videoRecodeBtn.setTitle("开始", for: UIControlState.normal)
        videoRecodeBtn.setTitle("结束", for: UIControlState.selected)
        videoRecodeBtn.addTarget(self, action: #selector(self.recordBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        let recordBarBtnItem = UIBarButtonItem(customView: videoRecodeBtn)
        self.navigationItem.rightBarButtonItems = [save,reset,switBtn, recordBarBtnItem]
        
        // pan 拖拽
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
        pan.maximumNumberOfTouches = 1
        // pinch 捏
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(sender:)))
        
        // ar scn view
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.isUserInteractionEnabled = true
        sceneView.addGestureRecognizer(pan)
        sceneView.addGestureRecognizer(pinch)
        
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        // scn scene
        let modelScene = SCNScene(named: "art.scnassets/cup/cup.scn")!
        let cup = modelScene.rootNode.childNodes[0] //.childNode(withName: "cup", recursively: true)!
        cup.name = "nodeName"
        previewNode = PreviewNode(node: cup)
        
        sceneView.scene.rootNode.addChildNode(previewNode!)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        screenCenter = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        sessionRun()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        screenCenter = CGPoint(x: size.width/2, y: size.height/2)
    }
    
    private func sessionRun(){
        let configure = ARWorldTrackingConfiguration()
        // 检测平面
        //configure.planeDetection = .horizontal
        // 坐标系的y轴与重力平行，x轴与z轴定向为罗盘方向，其原点是设备的初始位置。
        configure.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        sceneView.session.run(configure, options: [])
        
        previewNode!.position = SCNVector3(x: 0, y: -1, z: -1)
    }
    
    // MARK: action
    @objc func recordBtnAction(sender: Any?){
        
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
            meScene = self.sceneView.scene
        }
    }
    @objc func saveBarBtnItemAction(sender: Any?){
        
    }
    @objc func resetBarBtnItemAction(sender: Any?){
        previewNode!.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
    }
    
    // MARK: gesture
    private lazy var geoMaterDiffContArr = [Any?]()
    private func refreshStyle(node: SCNNode, isSelect: Bool, i: Int = 0) -> Int{
        
        var k = i
        if let materials = node.geometry?.materials{
            for j in 0 ..< materials.count {
                let material = materials[j]
                if isSelect{
                    geoMaterDiffContArr.append(material.diffuse.contents)
                    material.diffuse.contents = UIColor.red
                }else{
                    if let filePath = geoMaterDiffContArr[j+k] as? String{
                        material.diffuse.contents = UIImage(named: "grass.jpg")
                    }else{
                        material.diffuse.contents = geoMaterDiffContArr[j+k]
                    }
                }
            }
            k += materials.count
            if isSelect == false && k == geoMaterDiffContArr.count {
                geoMaterDiffContArr.removeAll()
            }
        }
        
        for n in node.childNodes{
            k = self.refreshStyle(node: n, isSelect: isSelect, i: k)
        }
        
        return k
    }
    @objc func panGesture(sender: UIGestureRecognizer){
        
        // 滑动的距离
        guard let pan = sender as? UIPanGestureRecognizer else {
            return
        }
        
        let locationPoint = sender.location(in: sceneView)
        
        if pan.state == .began {
            // 点击到的 node
            let sceneHitTestResult = sceneView.hitTest(locationPoint, options: nil)
            
            if let hit = sceneHitTestResult.first {
                if hit.node.name != nil{
                    // 此处未获取到 nodeName
                    // 此处的 node.name = 模型文件中的 name
                    selectModel = true
                }
            }
        }
        
        selectModel = swit.isOn
        
        if selectModel {
            // 拖拽
            if pan.state == .began{
                let _ = refreshStyle(node: previewNode!, isSelect: true)
            }else if pan.state != .changed{
                // 拖拽 结束/失败/取消
                selectModel = false
                let _ = refreshStyle(node: previewNode!, isSelect: false)
            }
            
            let arHitTestResult = sceneView.hitTest(locationPoint, types: [ARHitTestResult.ResultType.featurePoint, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent])
            //let arHitTestResult = sceneView.hitTest(locationPoint, types: ARHitTestResult.ResultType.existingPlane)
            if let hit = arHitTestResult.first{
                // 检测到平面, 才可以拖拽
                hasPlaneOrGesture = true
                
                //previewNode?.simdTransform = hit.worldTransform // 丢失缩放 scale
                
                // extension float4x4.translation
                // hit.worldTransform.translation == hit.worldTransform.columns.3.x/y/z
                previewNode?.simdPosition = hit.worldTransform.translation
            }
            
        }else{
            // 旋转
            
            let point = pan.translation(in: self.view)
            // 根据 name 递归获取节点
            let node: SCNNode = previewNode! // self.sceneView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
            //node.eulerAngles = SCNVector3(node.eulerAngles.x + Float.pi/32, node.eulerAngles.y + Float.pi/32, node.eulerAngles.z + Float.pi/32)
            if abs(point.x) > abs(point.y) {
                // 左右拖拽, 按y 旋转
                if point.x > 0 {
                    let anglesY = Float((node.eulerAngles.y > 6) ? (Float.pi / 64) : (node.eulerAngles.y + Float.pi / 64))
                    node.eulerAngles = SCNVector3(x: node.eulerAngles.x, y: anglesY, z: node.eulerAngles.z)
                }else{
                    let anglesY = Float((node.eulerAngles.y > 6) ? (Float.pi / 64) : (node.eulerAngles.y - Float.pi / 64))
                    node.eulerAngles = SCNVector3(x: node.eulerAngles.x, y: anglesY, z: node.eulerAngles.z)
                }
            }else {
                // 上下拖拽, 按 x 旋转
                if point.y > 0{
                    let anglesX = Float((node.eulerAngles.x > 6) ? (Float.pi / 64) : (node.eulerAngles.x + Float.pi / 64))
                    node.eulerAngles = SCNVector3(x: anglesX, y: node.eulerAngles.y, z: node.eulerAngles.z)
                }else{
                    let anglesX = Float((node.eulerAngles.x > 6) ? (Float.pi / 64) : (node.eulerAngles.x - Float.pi / 64))
                    node.eulerAngles = SCNVector3(x: anglesX, y: node.eulerAngles.y, z: node.eulerAngles.z)
                }
            }
            // 每次移动完，将移动量置为0，否则下次移动会加上这次移动量
            pan.setTranslation(CGPoint.zero, in: self.sceneView)
        }
    }
    @objc func pinchGesture(sender: UIGestureRecognizer){
        
        guard let pinch = sender as? UIPinchGestureRecognizer else{
            return
        }
        // 根据 name 递归获取节点
        //let node: SCNNode = self.sceneView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
        guard let node = previewNode else{
            return
        }
        
        //2.手势开始时保存node的scale
        if pinch.state == .began{
            pinchBeginNodeScaleX = node.scale.x
        }
        //3.缩放
        //CGAffineTransform转换SCNVector3
        //转换具体参考
        //CGAffineTransform矩阵运算的原理 http://justsee.iteye.com/blog/1969933
        //node.scale SCNVector比例向量 https://developer.apple.com/documentation/scenekit/scnnode/1408050-scale
        let transf: CGAffineTransform = pinch.view!.transform
        let transfscale: CGAffineTransform = transf.scaledBy(x: pinch.scale, y: pinch.scale)
        let nodeScale = Float(transfscale.a) * self.pinchBeginNodeScaleX
        
        node.scale = SCNVector3(nodeScale, nodeScale, nodeScale)
    }
}

extension SavemeViewController: ARSCNViewDelegate{
    // MARK: SCN Scene Renderer Delegate 代理
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard hasPlaneOrGesture == false else { return }
        guard let node = previewNode else { return }
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(
            screenCenter,
            in: sceneView,
            objectPos: node.simdPosition
        )
        
        if let position = worldPosition {
            node.update(for: position, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 不检测平面
    }
    // MARK: ARSCNViewDelegate -> SCNSceneRendererDelegate 代理
    // 在SceneKit渲染场景内容之前自定义渲染内容
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        if videoRecodeBtn.isSelected {
            // 开始录制
            guard let pointOfView: SCNNode = self.sceneView.pointOfView else{ return }
            let current = pointOfView.position
            if lastPosition != nil{
                if lastPosition!.distance(vector: current) > 0.5 {
                    
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
    // MARK: ARSCNViewDelegate -> ARSessionObserver 代理
    func sessionInterruptionEnded(_ session: ARSession) {
        sessionRun()
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionRun()
    }
}
