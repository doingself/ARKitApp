//
//  EightARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/3.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

class EightARViewController: UIViewController {

    private var arSCNView: ARSCNView!
    private var pinchBeginNodeScaleX: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "手势拖拽/缩放 SCNScene"
        self.view.backgroundColor = UIColor.white
        
        // 创建模型场景
        //let scene: SCNScene = SCNScene(named: "art.scnassets/3DModule/BoConceptImola.obj")!
        let scene: SCNScene = SCNScene(named: "art.scnassets/3DModule/BoConceptImola.dae")!
        
        let node: SCNNode = scene.rootNode.childNodes[0]
        node.name = "nodeName"
        //设置节点的位置
        node.position = SCNVector3(x: 0, y: 0, z: -0.5)
        //缩放
        node.scale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        
        
        arSCNView = ARSCNView(frame: self.view.bounds)
        arSCNView.delegate = self
        // 显示场景
        arSCNView.scene = scene
        
        arSCNView.showsStatistics = true
        arSCNView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        arSCNView.automaticallyUpdatesLighting = true
        arSCNView.autoenablesDefaultLighting = true
        
        // tap 点击
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(sender:)))
        // pan 拖拽
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
        pan.maximumNumberOfTouches = 1
        // pinch 捏
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(sender:)))
        
        arSCNView.isUserInteractionEnabled = true
        arSCNView.addGestureRecognizer(tap)
        arSCNView.addGestureRecognizer(pan)
        arSCNView.addGestureRecognizer(pinch)
        
        self.view.addSubview(arSCNView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        self.arSCNView.session.run(config, options: ARSession.RunOptions.resetTracking)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.arSCNView.session.pause()
    }
    
    @objc func tapGesture(sender: UIGestureRecognizer){
        guard let tap = sender as? UITapGestureRecognizer else {
            return
        }
        
        let tapPoint: CGPoint = tap.location(in: self.arSCNView)
        // 根据 name 递归获取节点
        let node: SCNNode = self.arSCNView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
        
        var scnOptions: [SCNHitTestOption : Any]?
        // 点击到的 node
        let scnHitTestResultArr: [SCNHitTestResult] = self.arSCNView.hitTest(tapPoint, options: scnOptions)
        print("scnHitTestResultArr = \(scnHitTestResultArr.count)")
        if let hit = scnHitTestResultArr.first{
            print("hit = \(hit)")
        }
        
        let arHitTestResultArr: [ARHitTestResult] = self.arSCNView.hitTest(
            tapPoint,
            types: [ARHitTestResult.ResultType.existingPlaneUsingExtent, .existingPlane, .estimatedHorizontalPlane, .featurePoint])
        print("arHitTestResultArr = \(arHitTestResultArr.count)")
        if let hit = arHitTestResultArr.first{
            let worldTrans = hit.worldTransform.columns.3
            node.position = SCNVector3(x: worldTrans.x, y: worldTrans.y, z: worldTrans.z)
        }
    }
    @objc func panGesture(sender: UIGestureRecognizer){
        // 滑动的距离
        guard let pan = sender as? UIPanGestureRecognizer else {
            return
        }
        let point = pan.translation(in: self.view)
        let pointX = Float(point.x / self.view.bounds.size.width) * 0.1
        let pointY = Float(point.y / self.view.bounds.size.height) * 0.1
        
        
        // 根据 name 递归获取节点
        let node: SCNNode = self.arSCNView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
        // 节点位置
        let nodePosition = node.position
        
        // 相机
        let camera: ARCamera = self.arSCNView.session.currentFrame!.camera
        // 相机在当前空间的位置
        let translation = camera.transform.columns.3
        
        
        // 更新位置
        let newX = pointX + nodePosition.x
        let newY = -pointY + nodePosition.y
        // 保持在 前面1m
        let newZ = (translation.z - 1 < pointY+nodePosition.z) ? (translation.z - 1) : (pointY+nodePosition.z)
        node.position = SCNVector3(newX, newY, newZ)
        
        // 旋转
        let angles = Float((node.eulerAngles.x > 6) ? (Float.pi / 32) : (node.eulerAngles.x + Float.pi / 32))
        node.eulerAngles = SCNVector3(angles, angles, 0)
        
        pan.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @objc func pinchGesture(sender: UIGestureRecognizer){
        guard let pinch = sender as? UIPinchGestureRecognizer else{
            return
        }
        // 根据 name 递归获取节点
        let node: SCNNode = self.arSCNView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
        
        if pinch.state == .began{
            pinchBeginNodeScaleX = node.scale.x
        }
        let transf: CGAffineTransform = pinch.view!.transform
        let transfscale: CGAffineTransform = transf.scaledBy(x: pinch.scale, y: pinch.scale)
        let nodeScale = Float(transfscale.a) * self.pinchBeginNodeScaleX
        
        node.scale = SCNVector3(nodeScale, nodeScale, nodeScale)
    }

}

extension EightARViewController: ARSCNViewDelegate{
    // MARK: AR SCN View 代理
    
}
