//
//  FourARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/27.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit
import ARKit

class FourARViewController: UIViewController {
    
    // AR 场景视图
    private var arSCNView: ARSCNView!
    private var arSession: ARSession!
    private var arConfiguration: ARWorldTrackingConfiguration!
    private var planeNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "点击屏幕touchesBegan 添加飞机 SCNScene.node, 添加旋转动画CABasicAnimation 类似地球公转"
        self.view.backgroundColor = UIColor.white
        
        
        arConfiguration = ARWorldTrackingConfiguration()
        // 追踪方向
        arConfiguration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        // 自适应灯光（相机从暗到强光快速过渡效果会平缓一些）
        arConfiguration.isLightEstimationEnabled = true
        
        arSession = ARSession()
        arSession.delegate = self
        
        arSCNView = ARSCNView(frame: self.view.bounds)
        arSCNView.delegate = self
        arSCNView.session = arSession
        // 自动刷新灯光
        arSCNView.automaticallyUpdatesLighting = true
        arSCNView.autoenablesDefaultLighting = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.addSubview(arSCNView)
        self.arSession.run(self.arConfiguration)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.arSession.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard planeNode == nil else{
            return
        }
        
        // 使用场景加载scn文件 scn格式文件是一个基于3D建模的文件，使用3DMax软件可以创建
        let scene: SCNScene = SCNScene(named: "art.scnassets/ship/ship.scn")!
        
        // 所有的场景有且只有一个根节点，其他所有节点都是根节点的子节点
        let node: SCNNode = scene.rootNode.childNodes[0]
        //设置节点的位置
        node.position = SCNVector3(x: 0, y: -1, z: -1)
        //缩放
        node.scale = SCNVector3Make(0.5, 0.5, 0.5);
        planeNode = node
        
        // 绕相机旋转的关键点在于：在相机的位置创建一个空节点，然后添加到这个空节点，最后让这个空节点自身旋转，就可以实现围绕相机旋转
        let centerNode: SCNNode = SCNNode()
        //空节点位置与相机节点位置一致
        centerNode.position = self.arSCNView.scene.rootNode.position
        //将空节点添加到相机的根节点
        self.arSCNView.scene.rootNode.addChildNode(centerNode)
        centerNode.addChildNode(node)
        
        //旋转核心动画
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "rotation")
        //旋转周期
        animation.duration = 30
        //围绕Y轴旋转360度  （不明白ARKit坐标系的可以看笔者之前的文章）
        animation.toValue = SCNVector4(0, 1, 0, CGFloat.pi * 2)
        //无限旋转  重复次数为无穷大
        animation.repeatCount = 100
        
        //开始旋转  ！！！：切记这里是让空节点旋转，而不是台灯节点。  理由同上
        centerNode.addAnimation(animation, forKey: "moon rotation around earth")
        
    }
}
extension FourARViewController: ARSessionDelegate{
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
extension FourARViewController: ARSCNViewDelegate{
    // MARK: AR SCNView 代理
    //    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    //        print("ARSCNViewDelegate 根据锚点获取节点")
    //        return nil
    //    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("ARSCNViewDelegate 添加节点")
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
