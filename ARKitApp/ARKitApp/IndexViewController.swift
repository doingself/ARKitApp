//
//  IndexViewController.swift
//  ArKitDemo
//
//  Created by 623971951 on 2018/2/7.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

class IndexViewController: UIViewController {

    // MARK: UI
    private lazy var popVC: PopViewController = {
        let pop = PopViewController()
        pop.preferredContentSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.height/2)
        return pop
    }()
    
    // MARK: ARKit
    private var sceneLocationView: SceneLocationView!
    private var locationPreviewNode: AudioinARKitLocationNode!
    private var swit: UISwitch!
    private var screenCenter: CGPoint = .zero
    private var hasPlaneOrGesture = false
    private var pinchBeginNodeScaleX: Float = 0.0
    private lazy var geoMaterDiffContArr = [Any?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "ARKit App"
        self.view.backgroundColor = UIColor.white
        
        let left = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(self.leftItemAction(sender:)))
        self.navigationItem.leftBarButtonItem = left
        
        let right = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(self.rightItemAction(sender:)))
        
        let reset = UIBarButtonItem(title: "复位", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.resetBarBtnItemAction(sender:)))
        swit = UISwitch()
        swit.isOn = true
        let switBtn = UIBarButtonItem(customView: swit)
        
        self.navigationItem.rightBarButtonItems = [right, reset, switBtn]
        
        // ARKit
        sceneLocationView = SceneLocationView(frame: self.view.bounds)
        
        self.view.addSubview(sceneLocationView)
        sceneLocationView.automaticallyUpdatesLighting = true
        sceneLocationView.autoenablesDefaultLighting = true
        sceneLocationView.showsStatistics = true
        sceneLocationView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        sceneLocationView.locationDelegate = self
        sceneLocationView.showAxesNode = true
        sceneLocationView.showFeaturePoints = true
        //sceneLocationView.orientToTrueNorth = false
        //sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        
        
        // pan 拖拽
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
        pan.maximumNumberOfTouches = 1
        // pinch 捏
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(sender:)))
        
        sceneLocationView.isUserInteractionEnabled = true
        sceneLocationView.addGestureRecognizer(pan)
        sceneLocationView.addGestureRecognizer(pinch)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        screenCenter = CGPoint(x: self.sceneLocationView.bounds.midX, y: self.sceneLocationView.bounds.midY)
        
        sceneLocationView.run()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 保存位置信息
        for node in sceneLocationView.locationNodes{
            let location = sceneLocationView.locationOfLocationNode(node)
            node.location = location
        }
        for model in RootViewController.shared!.selectModel{
            model.location = model.node.location
        }
        
        sceneLocationView.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        screenCenter = CGPoint(x: size.width/2, y: size.height/2)
    }
    
}

// MARK: UI
extension IndexViewController{
    @objc func leftItemAction(sender: Any?){
        RootViewController.shared?.openLeft()
    }
    @objc func rightItemAction(sender: Any?){
        popVC.datas = RootViewController.shared!.selectModel
        
        //popVC.preferredContentSize = CGSize(width: self.view.frame.size.width/3, height: self.view.frame.size.height/2)
        //  弹出视图的显示样式
        popVC.modalPresentationStyle = .popover
        popVC.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        popVC.popoverPresentationController?.delegate = self
        if locationPreviewNode != nil{
            popVC.selectModel = locationPreviewNode.name
        }
        self.present(popVC, animated: true, completion: nil)
    }
}
extension IndexViewController: RootViewControllerDelegate{
    // MARK: root view controller delegate
    // 添加模型后,更新
    func refreshModel() {
        if let model = RootViewController.shared?.selectModel.last{
            // 从模型中获取 node, 添加到 scene
            locationPreviewNode = model.node
            if locationPreviewNode.location == nil{
                // 放置当前位置
                sceneLocationView.addLocationNodeForCurrentPosition(locationNode: locationPreviewNode)
                hasPlaneOrGesture = false
            }else{
                // 放置固定位置
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: locationPreviewNode)
            }
        }
    }
    // pop 选中的模型
    func selectModelByPop(index: Int) {
        if let node = sceneLocationView.locationNodes[index] as? AudioinARKitLocationNode{
            locationPreviewNode = node
            if locationPreviewNode.location == nil{
                hasPlaneOrGesture = false
            }else{                
                hasPlaneOrGesture = true
            }
        }
    }
    func deleteModelByPop(model: ScnModel, index: Int) {
        if let node = sceneLocationView.locationNodes[index] as? AudioinARKitLocationNode, node.name == model.scnName{
            node.removeFromParentNode()
        }
    }
}
extension IndexViewController: UIPopoverPresentationControllerDelegate{
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        //默认返回的是覆盖整个屏幕，需设置成UIModalPresentationNone
        return UIModalPresentationStyle.none
    }
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
}

// MARK: ARKit
extension IndexViewController{
    // MARK: rightBarButtonItems action
    @objc func resetBarBtnItemAction(sender: Any?){
        if locationPreviewNode != nil{
            locationPreviewNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        }
    }
    
    // MARK: gesture action
    private func refreshStyle(node: SCNNode, isSelect: Bool, i: Int = 0) -> Int{
        var k = i
        if let materials = node.geometry?.materials{
            for j in 0 ..< materials.count {
                let material = materials[j]
                if isSelect{
                    geoMaterDiffContArr.append(material.diffuse.contents)
                    material.diffuse.contents = UIColor.randomColor()
                }else{
                    material.diffuse.contents = geoMaterDiffContArr[j+k]
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
        guard locationPreviewNode != nil else {
            return
        }
        // 滑动的距离
        guard let pan = sender as? UIPanGestureRecognizer else {
            return
        }
        
        let locationPoint = sender.location(in: sceneLocationView)
        
        if swit.isOn {
            // 拖拽
            if pan.state == .began{
                let _ = refreshStyle(node: locationPreviewNode, isSelect: true)
            }else if pan.state != .changed{
                // 拖拽 结束/失败/取消
                let _ = refreshStyle(node: locationPreviewNode, isSelect: false)
            }
            
            let arHitTestResult = sceneLocationView.hitTest(locationPoint, types: [ARHitTestResult.ResultType.featurePoint, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent])
            //let arHitTestResult = sceneView.hitTest(locationPoint, types: ARHitTestResult.ResultType.existingPlane)
            if let hit = arHitTestResult.first{
                // 检测到平面, 才可以拖拽
                hasPlaneOrGesture = true
                
                //previewNode?.simdTransform = hit.worldTransform // 丢失缩放 scale
                
                // extension float4x4.translation
                // hit.worldTransform.translation == hit.worldTransform.columns.3.x/y/z
                locationPreviewNode.simdPosition = hit.worldTransform.translation
            }
            
        }else{
            // 旋转
            let point = pan.translation(in: self.view)
            // 根据 name 递归获取节点
            let node: SCNNode = locationPreviewNode
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
            pan.setTranslation(CGPoint.zero, in: self.sceneLocationView)
        }
    }
    @objc func pinchGesture(sender: UIGestureRecognizer){
        
        guard let pinch = sender as? UIPinchGestureRecognizer else{
            return
        }
        // 根据 name 递归获取节点
        //let node: SCNNode = self.sceneView.scene.rootNode.childNode(withName: "nodeName", recursively: true)!
        guard let node = locationPreviewNode else{
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
extension IndexViewController: SceneLocationViewDelegate{
    
    //MARK: SceneLocationViewDelegate
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("SceneLocationViewDelegate + add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("SceneLocationViewDelegate + remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
        print("SceneLocationViewDelegate + did confirm location of node = \(node)")
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        print("SceneLocationViewDelegate + did setup scene node = \(sceneNode)")
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        //print("SceneLocationViewDelegate + did update location and scale of location node")
    }
    
    /// ARSCNViewDelegate SCNSceneRendererDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval){
        guard hasPlaneOrGesture == false else { return }
        guard let node = locationPreviewNode else { return }
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(
            screenCenter,
            in: sceneLocationView,
            objectPos: node.simdPosition
        )
        
        if let position = worldPosition {
            node.update(for: position, planeAnchor: planeAnchor, camera: sceneLocationView.session.currentFrame?.camera)
        }
    }
}
