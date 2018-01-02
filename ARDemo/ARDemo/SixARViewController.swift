//
//  SixARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/2.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

class SixARViewController: UIViewController {

    private var arSCNView: ARSCNView!
    private var shipScene: SCNScene!
    private var contentRootNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "检测平面添加模型, 手势拖拽"
        self.view.backgroundColor = UIColor.white
        
        arSCNView = ARSCNView(frame: self.view.bounds)
        arSCNView.delegate = self
        // 灯光
        arSCNView.automaticallyUpdatesLighting = true
        arSCNView.autoenablesDefaultLighting = true
        // 显示 特征
        arSCNView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        // 显示 fps
        arSCNView.showsStatistics = true
        
        arSCNView.isUserInteractionEnabled = true
        // tap
        arSCNView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(sender:))))
        // pan
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
        pan.maximumNumberOfTouches = 1
        arSCNView.addGestureRecognizer(pan)
        self.view.addSubview(arSCNView)
        
        
        
        
        shipScene = SCNScene()
        contentRootNode = SCNNode()
        let virtualObjectScene = SCNScene(named: "art.scnassets/ship/ship.scn")!
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        shipScene.rootNode.addChildNode(contentRootNode)
        contentRootNode.addChildNode(wrapperNode)
        
        
        /*
        // 使用场景加载scn文件 scn格式文件是一个基于3D建模的文件，使用3DMax软件可以创建
        shipScene = SCNScene(named: "art.scnassets/spitfire/spitfiremodelplane.scn")!
        // 所有的场景有且只有一个根节点，其他所有节点都是根节点的子节点
        shipNode = shipScene.rootNode
        //设置节点的位置
        shipNode.position = SCNVector3(x: 0.5, y: 0.5, z: -1)
        //缩放
        shipNode.scale = SCNVector3(x: 0.2, y: 0.2, z: 0.2)
        // 螺旋桨 动画
        if let engineNode = shipNode.childNode(withName: "engine", recursively: false){
            let rotate = SCNAction.rotateBy(x: 0, y: 0, z: 85, duration: 0.5)
            let moveSequence = SCNAction.sequence([rotate])
            let moveLoop = SCNAction.repeatForever(moveSequence)
            engineNode.runAction(moveLoop, forKey: "engine")
        }
         */
        
        
        // 将飞机节点添加到当前屏幕中
        self.arSCNView.scene = shipScene
    }
    
    @objc func tapGesture(sender: UIGestureRecognizer){
        let location: CGPoint = sender.location(in: self.arSCNView)
        
//        if let sceneHitTestResult: [SCNHitTestResult] = self.arSCNView.hitTest(location, options: nil){
//            SCNTransaction.begin()
//            SCNTransaction.animationDuration = 1.5
//            SCNTransaction.commit()
//            return
//        }
        let arHitTestResult: [ARHitTestResult] = self.arSCNView.hitTest(location, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        print("ar hit test result = \(arHitTestResult.count)")
        if let hit = arHitTestResult.first{
            
            print("self.node.simdTransform = \(self.contentRootNode.simdTransform)")
            print("hit.worldTransform = \(hit.worldTransform)")
            self.contentRootNode.simdTransform = hit.worldTransform
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.5
            SCNTransaction.commit()
        }
        
    }
    @objc func panGesture(sender: UIGestureRecognizer){
        let location: CGPoint = sender.location(in: self.arSCNView)
        
        let arHitTestResult = self.arSCNView.hitTest(location, types: ARHitTestResult.ResultType.existingPlane)
        if let hit: ARHitTestResult = arHitTestResult.first{
            
            self.contentRootNode.simdTransform = hit.worldTransform
            
            if sender.state == .ended{
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.5
                SCNTransaction.commit()
            }
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        // 追踪 平面
        config.planeDetection = .horizontal
        // 灯光
        config.isLightEstimationEnabled = true
        
        self.arSCNView.session.run(config, options: ARSession.RunOptions.resetTracking)
        
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.arSCNView.session.pause()
    }
}
extension SixARViewController: ARSCNViewDelegate{
    // MARK: AR SCNView 代理
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        print("ARSCNViewDelegate 根据锚点获取节点")
//        return nil
//    }
    // 添加节点时候调用
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("ARSCNViewDelegate 添加节点")
        if anchor is ARPlaneAnchor{
            self.contentRootNode.simdTransform = anchor.transform
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
extension SixARViewController: ARSessionDelegate{
    // MARK: AR Session 代理
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //print("ARSessionDelegate 相机移动 frame = \(frame)")
    }
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("ARSessionDelegate 添加锚点 anchors = \(anchors)")
        
    }
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("ARSessionDelegate 更新锚点 anchors = \(anchors)")
        
    }
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("ARSessionDelegate 移除锚点 anchors = \(anchors)")
    }
}
