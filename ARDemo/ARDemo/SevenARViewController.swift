//
//  SevenARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/3.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

class SevenARViewController: UIViewController {

    private var arSCNView: ARSCNView!
    private var pinchBeginNodeScaleX: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform"
        self.view.backgroundColor = UIColor.white
        
        
        // scnmaterial 渲染器
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red // UIImage(named: "grass.jpg")
        
        // scnbox 立体, scnplane 平面
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        box.materials = [material]
        
        // 基于 box 创建节点
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "nodeName"
        boxNode.position = SCNVector3(x: 0, y: 0, z: 0.2)
        
        // 创建模型场景
        // let scene = SCNScene(named: "../../ship.scn")
        // 空场景
        let scene: SCNScene = SCNScene()
        scene.rootNode.addChildNode(boxNode)
        
        
        
        
        arSCNView = ARSCNView(frame: self.view.bounds)
        arSCNView.delegate = self
        // 显示场景
        arSCNView.scene = scene
        
        arSCNView.showsStatistics = true
        arSCNView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        arSCNView.automaticallyUpdatesLighting = true
        arSCNView.autoenablesDefaultLighting = true
        
        // pan 拖拽
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
        pan.maximumNumberOfTouches = 1
        // pinch 捏
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(sender:)))
        
        arSCNView.isUserInteractionEnabled = true
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
        // 模型z坐标保持在距离摄像头0.1
        let newZ = (translation.z-0.1 < pointY+nodePosition.z) ? (translation.z-0.1) : (pointY + nodePosition.z);
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
extension SevenARViewController: ARSCNViewDelegate{
    // MARK: AR SCN View 代理
    
}
