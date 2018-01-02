//
//  TwoARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/27.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit

import ARKit

import Photos

// ReplayKit不需要太大电量损耗和性能损耗就可以产出高清的视频记录。ReplayKit支持使用A7芯片以上，操作系统为iOS 9或更高版本的设备。
import ReplayKit

class TwoARViewController: UIViewController {
    
    // AR 场景视图
    private var arSCNView: ARSCNView!
    private var arSession: ARSession!
    private var arConfiguration: ARWorldTrackingConfiguration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "检测平面,添加飞机 tap拍照, long录制"
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
        
        arSCNView.isUserInteractionEnabled = true
        // tap gesture
        arSCNView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(sender:))))
        // long press gesture
        let long = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(sender:)))
        long.minimumPressDuration = 0.5
        long.allowableMovement = 100
        long.delegate = self
        arSCNView.addGestureRecognizer(long)
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

extension TwoARViewController: ARSessionDelegate{
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

extension TwoARViewController: ARSCNViewDelegate{
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
            
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let img = UIImage(named: "grass.jpg")
            let material = SCNMaterial()
            material.diffuse.contents = img
            material.isDoubleSided = true
            plane.materials = [material]
            
            // 创建一个基于3D物体模型的节点
            let planeNode: SCNNode = SCNNode(geometry: plane)
            // 设置节点的位置为捕捉到的平地的锚点的中心位置  SceneKit框架中节点的位置position是一个基于3D坐标系的矢量坐标SCNVector3Make
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
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

extension TwoARViewController: UIGestureRecognizerDelegate{
    // MARK: gesture 代理
    
    
    // MARK: gesture 事件
    @objc func tapGesture(sender: Any?){
        let block = {
            // 保存截图到相册
            UIImageWriteToSavedPhotosAlbum(self.arSCNView.snapshot(), nil, nil, nil)
            DispatchQueue.main.async(execute: {
                let v = UIView(frame: self.arSCNView.bounds)
                v.backgroundColor = UIColor.white
                self.arSCNView.addSubview(v)
                UIView.animate(withDuration: 0.25, animations: {
                    v.alpha = 0.0
                }, completion: { (suc) in
                    v.removeFromSuperview()
                })
            })
        }
        switch PHPhotoLibrary.authorizationStatus() {
        case PHAuthorizationStatus.authorized:
            block()
        case PHAuthorizationStatus.notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == PHAuthorizationStatus.authorized{
                    block()
                }
            })
        default:
            break
        }
    }
    @objc func longPressGesture(sender: UIGestureRecognizer){
        if sender.state == UIGestureRecognizerState.began{
            if RPScreenRecorder.shared().isAvailable{
                // 是否开启设备的麦克风
                RPScreenRecorder.shared().isMicrophoneEnabled = true
                RPScreenRecorder.shared().startRecording(handler: { (err: Error?) in
                    if let e = err {
                        print("err = \(e)")
                    }
                })
            }
        }else if sender.state == UIGestureRecognizerState.ended{
            if RPScreenRecorder.shared().isRecording {
                RPScreenRecorder.shared().stopRecording(handler: { (previewVC: RPPreviewViewController?, err: Error?) in
                    if let e = err {
                        print("err = \(e)")
                    }
                    guard let preview = previewVC else{
                        return
                    }
                    let needSave = true
                    if needSave {
                        // 回看
                        DispatchQueue.main.async(execute: {
                            self.present(preview, animated: true, completion: {
                                
                            })
                        })
                    }else{
                        // 丢弃记录
                        RPScreenRecorder.shared().discardRecording {
                            // ......
                        }
                    }
                })
            }
        }
    }
}
