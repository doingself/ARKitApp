//
//  FiveARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/28.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit
import ARKit

class FiveARViewController: UIViewController {
    
    // AR 场景视图
    private var arSCNView: ARSCNView!
    private var arSession: ARSession!
    private var arConfiguration: ARWorldTrackingConfiguration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "检测平面ARPlaneAnchor添加SCNBox, 1s后添加飞机SCNScene.node 点击屏幕 tap 获取 ARHitTestResult 使用 hitResult.worldTransform.columns.3 添加 SCNNode(geometry: SCNBox()).position"
        self.view.backgroundColor = UIColor.white
        
        
        arConfiguration = ARWorldTrackingConfiguration()
        // 追踪方向 平面
        // 如果启用planeDetection设置，ARKit会分析场景以查找真实世界的平面。对于检测到的每个平面，ARKit会自动向会话添加一个ARPlaneAnchor对象。
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
        
        // 显示 追踪 特征
        arSCNView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        // 显示统计数据 fps
        arSCNView.showsStatistics = true
        
        // tap
        arSCNView.isUserInteractionEnabled = true
        arSCNView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.viewTap(sender:))))
    }
    
    @objc func viewTap(sender: UIGestureRecognizer){
        
        let tapPoint = sender.location(in: self.view)
        // 获取屏幕空间坐标并传递给 ARSCNView 实例的 hitTest 方法
        // 如果射线与某个平面几何体相交，就会返回该平面，以离摄像头的距离升序排序
        let result: [ARHitTestResult] = arSCNView.hitTest(tapPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        // 如果命中多次，用距离最近的平面
        if let hitResult: ARHitTestResult = result.first{
            // physicsBody 会让 SceneKit 用物理引擎控制该几何体
            let physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: nil)
            physicsBody.mass = 2
            physicsBody.categoryBitMask = 1
            
            // 创建一个3D物体模型
            let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
            // 使用Material渲染3D模型 默认白色
            box.firstMaterial?.diffuse.contents = UIColor.blue
            
            // 创建一个基于3D物体模型的节点
            let node = SCNNode(geometry: box)
            // physicsBody 会让 SceneKit 用物理引擎控制该几何体
            node.physicsBody = physicsBody
            // 把几何体插在用户点击的点再稍高一点的位置，以便使用物理引擎来掉落到平面上
            node.position = SCNVector3(x: hitResult.worldTransform.columns.3.x, y: hitResult.worldTransform.columns.3.y + 0.5, z: hitResult.worldTransform.columns.3.z)
            
            arSCNView.scene.rootNode.addChildNode(node)
        }
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
    
    //override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
}

extension FiveARViewController: ARSCNViewDelegate{
    // MARK: AR SCNView 代理
    //    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    //        print("ARSCNViewDelegate 根据锚点获取节点")
    //        return nil
    //    }
    // 添加节点时候调用
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("ARSCNViewDelegate 添加节点")
        
        // 当 ARKit 检测到一个平面时，ARKit 会为该平面自动添加一个 ARPlaneAnchor，这个 ARPlaneAnchor 就表示了一个平面。
        // ARPlaneAnchor.Alignment: 表示该平面的方向，目前只有 horizontal 一个可能值，表示这个平面是水平面。ARKit 目前无法检测出垂直平面。
        // ARPlaneAnchor.center: 表示该平面的本地坐标系的中心点。检测到的平面都有一个三维坐标系，center 所代表的就是坐标系的原点
        // ARPlaneAnchor.extent: 表示该平面的大小范围。
        if let planeAnchor = anchor as? ARPlaneAnchor{
            
            // 添加一个3D平面模型，ARKit只有捕捉能力，锚点只是一个空间位置，要想更加清楚看到这个空间，我们需要给空间添加一个平地的3D模型来渲染他
            
            // 创建一个3D物体模型 系统捕捉到的平地是一个不规则大小的长方形
            // 参数分别是长宽高和圆角
            let planeBox: SCNBox = SCNBox(width: CGFloat(planeAnchor.extent.x) * 1, height: 0.01, length: CGFloat(planeAnchor.extent.x) * 1, chamferRadius: 0)
            // 使用Material渲染3D模型 默认白色
            planeBox.firstMaterial?.diffuse.contents = UIColor.red
            
            // 创建一个基于3D物体模型的节点
            let planeNode: SCNNode = SCNNode(geometry: planeBox)
            // 设置节点的位置为捕捉到的平地的锚点的中心位置  SceneKit框架中节点的位置position是一个基于3D坐标系的矢量坐标SCNVector3Make
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            node.addChildNode(planeNode)
            
            // 当捕捉到平地时，1s之后开始在平地上添加一个3D模型
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: {
                
                // 使用场景加载scn文件 scn格式文件是一个基于3D建模的文件，使用3DMax软件可以创建
                let scene: SCNScene = SCNScene(named: "art.scnassets/ship/ship.scn")!
                
                // 所有的场景有且只有一个根节点，其他所有节点都是根节点的子节点
                let shipNode: SCNNode = scene.rootNode.childNodes[0]
                // 设置节点的位置为捕捉到的平地的位置，如果不设置，则默认为原点位置，也就是相机位置
                shipNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
                
                //缩放
                shipNode.scale = SCNVector3Make(0.5, 0.5, 0.5);
                
                // 将飞机节点添加到当前屏幕中
                node.addChildNode(shipNode)
            })
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

extension FiveARViewController: ARSessionDelegate{
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

