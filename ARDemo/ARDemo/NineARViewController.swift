//
//  NineARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/4.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

class NineARViewController: UIViewController {

    private var arScnView: ARSCNView!
    
    private var pinchBeginNodeScaleX: Float = 0
    
    private var selectModel = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "摆放家具"
        self.view.backgroundColor = UIColor.white
        
        // gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(sender:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(sender:)))
        
        // 创建模型场景
        
        let scene: SCNScene = SCNScene(named: "art.scnassets/3DModule/BoConceptImola.dae")!
        let node: SCNNode = scene.rootNode.childNodes[0]
        node.name = "nodeName"
        //设置节点的位置
        node.position = SCNVector3(x: 0, y: 0, z: -0.5)
        //缩放
        node.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        
        
        
        // AR SCN View
        arScnView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(arScnView)
        
        arScnView.scene.rootNode.addChildNode(node)
        arScnView.delegate = self
        
        arScnView.automaticallyUpdatesLighting = true
        arScnView.autoenablesDefaultLighting = true
        
        arScnView.showsStatistics = true
        arScnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        arScnView.isUserInteractionEnabled = true
        arScnView.addGestureRecognizer(tap)
        arScnView.addGestureRecognizer(pan)
        arScnView.addGestureRecognizer(pinch)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if ARWorldTrackingConfiguration.isSupported == false{
            // 不支持
            return
        }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.isLightEstimationEnabled = true
        arScnView.session.run(config, options: ARSession.RunOptions.resetTracking)
        
        // 取消自动锁定屏幕
        UIApplication.shared.isIdleTimerDisabled = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        arScnView.session.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }

}
extension NineARViewController{
    // MARK: 手势事件
    @objc func tapGesture(sender: UIGestureRecognizer){
        guard let tap = sender as? UITapGestureRecognizer else {
            return
        }
        
        let tapPoint: CGPoint = tap.location(in: self.arScnView)
        
        let scnOptions = [SCNHitTestOption : Any]()
        // 点击到的 node
        let scnHitTestResultArr: [SCNHitTestResult] = self.arScnView.hitTest(tapPoint, options: scnOptions)
        print("scnHitTestResultArr = \(scnHitTestResultArr.count)")
        if let hit = scnHitTestResultArr.first{
            print("SCNHitTestResult = \(hit)")
        }
        
        let arHitTestResultArr: [ARHitTestResult] = self.arScnView.hitTest(
            tapPoint,
            types: [ARHitTestResult.ResultType.existingPlaneUsingExtent, .existingPlane, .estimatedHorizontalPlane, .featurePoint])
        print("arHitTestResultArr = \(arHitTestResultArr.count)")
        if let hit = arHitTestResultArr.first{
            let worldTrans = hit.worldTransform.columns.3
            print("ARHitTestResult.worldTrans = \(worldTrans)")
            // 根据 name 递归获取节点
            //let node: SCNNode = self.arScnView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
            //node.position = SCNVector3(x: worldTrans.x, y: worldTrans.y, z: worldTrans.z)
            //node.simdPosition = float3( worldTrans.x,  worldTrans.y,  worldTrans.z)
        }
    }
    
    @objc func panGesture(sender: UIGestureRecognizer){
        // 滑动的距离
        guard let pan = sender as? UIPanGestureRecognizer else {
            return
        }
        
        let localtionPoint = pan.location(in: self.arScnView)
        
        if pan.state != .changed {
            selectModel = false
        }
        
        if pan.state == .began {
            let scnOptions = [SCNHitTestOption : Any]()
            // 点击到的 node
            let scnHitTestResultArr: [SCNHitTestResult] = self.arScnView.hitTest(localtionPoint, options: scnOptions)
            if let hit = scnHitTestResultArr.first{
                if hit.node.name == "nodeName"{
                    selectModel = true
                }
            }
        }

        if selectModel{
            // 如果一开始就点中模型,则拖拽,否则旋转
        
            // 根据 name 递归获取节点
            let node: SCNNode = self.arScnView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
            let arHitTestResultArr: [ARHitTestResult] = self.arScnView.hitTest(
                localtionPoint,
                types: [ARHitTestResult.ResultType.existingPlaneUsingExtent, .existingPlane, .estimatedHorizontalPlane, .featurePoint])
            if let hit = arHitTestResultArr.first{
                let worldTrans = hit.worldTransform.columns.3
                node.position = SCNVector3(x: worldTrans.x, y: worldTrans.y, z: worldTrans.z)
                //node.simdPosition = float3( worldTrans.x,  worldTrans.y,  worldTrans.z)
            }
            
//            let point = pan.translation(in: self.view)
//            let pointX = Float(point.x / self.view.bounds.size.width) * 0.1
//            let pointY = Float(point.y / self.view.bounds.size.height) * 0.1
//            // 节点位置
//            let nodePosition = node.position
//            // 相机
//            let camera: ARCamera = self.arScnView.session.currentFrame!.camera
//            // 相机在当前空间的位置
//            let translation = camera.transform.columns.3
//            // 更新位置
//            let newX = pointX + nodePosition.x
//            let newY = -pointY + nodePosition.y
//            // 保持在 前面1m
//            let newZ = (translation.z - 1 < pointY+nodePosition.z) ? (translation.z - 1) : (pointY+nodePosition.z)
//            node.position = SCNVector3(newX, newY, newZ)
            
        }else{
            // FIXME: 旋转需要优化
            let point = pan.translation(in: self.view)
            print("pan.translation = \(point)")
            // 根据 name 递归获取节点
            let node: SCNNode = self.arScnView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
            //node.eulerAngles = SCNVector3(node.eulerAngles.x + Float.pi/32, node.eulerAngles.y + Float.pi/32, node.eulerAngles.z + Float.pi/32)
            if abs(point.x) > 20 {
                // 左右拖拽
                if point.x > 0 {
                    node.eulerAngles = SCNVector3(x: node.eulerAngles.x, y: node.eulerAngles.y + Float.pi/16, z: node.eulerAngles.z)
                }else{
                    node.eulerAngles = SCNVector3(x: node.eulerAngles.x, y: node.eulerAngles.y - Float.pi/16, z: node.eulerAngles.z)
                }
            }else if abs(point.y) > 20 {
                // 上下拖拽
                if point.y > 0{
                    node.eulerAngles = SCNVector3(x: node.eulerAngles.x + Float.pi/16, y: node.eulerAngles.y, z: node.eulerAngles.z)
                }else{
                    node.eulerAngles = SCNVector3(x: node.eulerAngles.x - Float.pi/16, y: node.eulerAngles.y, z: node.eulerAngles.z)
                }
            }
            // 每次移动完，将移动量置为0，否则下次移动会加上这次移动量
            pan.setTranslation(CGPoint.zero, in: self.arScnView)
        }
        
    }
    @objc func pinchGesture(sender: UIGestureRecognizer){
        guard let pinch = sender as? UIPinchGestureRecognizer else{
            return
        }
        // 根据 name 递归获取节点
        let node: SCNNode = self.arScnView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
        
        if pinch.state == .began{
            pinchBeginNodeScaleX = node.scale.x
        }
        let transf: CGAffineTransform = pinch.view!.transform
        let transfscale: CGAffineTransform = transf.scaledBy(x: pinch.scale, y: pinch.scale)
        let nodeScale = Float(transfscale.a) * self.pinchBeginNodeScaleX
        
        node.scale = SCNVector3(nodeScale, nodeScale, nodeScale)
    }
}
extension NineARViewController: ARSCNViewDelegate{
    // MARK: SCN Scene Renderer Delegate 代理
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        let point = CGPoint(x: self.view.bounds.size.width/2, y: self.view.bounds.size.height/2)
//        let hitTests = self.arScnView.hitTest(point, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
//        if let hit = hitTests.first{
//            let position = hit.worldTransform.columns.3
//            let aa = float3(position.x, position.y, position.z)
//
//            // 根据 name 递归获取节点
//            let node: SCNNode = self.arScnView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
//            node.simdPosition = aa
//        }
    }
    // MARK: AR SCNView 代理
    // 添加节点时候调用
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("ARSCNViewDelegate 添加节点")
        
        if let planeAnchor = anchor as? ARPlaneAnchor{
            // 平面
            let planeBox: SCNBox = SCNBox(width: CGFloat(planeAnchor.extent.x) * 1, height: 0.1, length: CGFloat(planeAnchor.extent.x) * 1, chamferRadius: 0)
            // 使用Material渲染3D模型 默认白色
            planeBox.firstMaterial?.diffuse.contents = UIColor.red
            
            // 创建一个基于3D物体模型的节点
            let planeNode: SCNNode = SCNNode(geometry: planeBox)
            // 设置节点的位置为捕捉到的平地的锚点的中心位置  SceneKit框架中节点的位置position是一个基于3D坐标系的矢量坐标SCNVector3Make
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            node.addChildNode(planeNode)
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        print("ARSCNViewDelegate 节点更新中")
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("ARSCNViewDelegate 更新节点")
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("ARSCNViewDelegate 节点移除")
    }
}
