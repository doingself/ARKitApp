//
//  TenARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/8.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

// AudioinARKit is 茶杯 始终在平面中央, 检测到地面后固定
// InteractiveContentwithARKit is 变色龙 点击变色+拖拽
class TenARViewController: UIViewController {
    
    private var sceneView: ARSCNView!
    private var previewNode: PreviewNode?
    
    // 中心
    private var screenCenter: CGPoint = .zero
    // 检测到地面或者被拖拽, 取消 update at time
    private var hasPlaneOrGesture = false
    // 是否选中模型,用于 拖拽 / 旋转
    private var selectModel = false
    // 拖拽
    private var pinchBeginNodeScaleX: Float = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "基于 Apple Demo 实现家具摆放"
        self.view.backgroundColor = UIColor.white
        
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
    
    func sessionRun(){
        let configure = ARWorldTrackingConfiguration()
        configure.planeDetection = .horizontal
        sceneView.session.run(configure, options: [])
    }
    
    @objc func panGesture(sender: UIGestureRecognizer){
        
        // 滑动的距离
        guard let pan = sender as? UIPanGestureRecognizer else {
            return
        }
        
        let locationPoint = sender.location(in: sceneView)
        
        if pan.state != .changed {
            selectModel = false
        }
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
        
        if selectModel {
            // 拖拽
            let arHitTestResult = sceneView.hitTest(locationPoint, types: .existingPlane)
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
extension TenARViewController: ARSCNViewDelegate{
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
        guard anchor is ARPlaneAnchor && previewNode != nil
            else { return }
        
        guard let cameraTransform: matrix_float4x4 = sceneView.session.currentFrame?.camera.transform
            else { return }
        
        hasPlaneOrGesture = true
        
        let cameraWorldPosition = cameraTransform.translation
        var cameraToPosition = anchor.transform.translation - cameraWorldPosition
        
        if simd_length(cameraToPosition) > 10 {
            cameraToPosition = simd_normalize(cameraToPosition)
            cameraToPosition *= 10
        }
        
        previewNode?.simdPosition = cameraWorldPosition + cameraToPosition
    }
    // MARK: ARSessionObserver 代理
    func sessionInterruptionEnded(_ session: ARSession) {
        sessionRun()
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionRun()
    }
}
