//
//  ARLocationGestureViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/2/5.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

class ARLocationGestureViewController: UIViewController {
    
    private var sceneLocationView: SceneLocationView!
    private var locationPreviewNode: AudioinARKitLocationNode!
    
    //var lastLocation: CLLocation? // appdelegate.swift
    
    private var infoLabel: UILabel!
    private var updateInfoLabelTimer: Timer!
    
    private var swit: UISwitch!
    // 中心
    private var screenCenter: CGPoint = .zero
    // 被拖拽, 取消 update at time
    private var hasPlaneOrGesture = false
    // 缩放
    private var pinchBeginNodeScaleX: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "(ARKit+CoreLocation) + gesture"
        self.view.backgroundColor = UIColor.white
        
        let curr = UIBarButtonItem(title: "放置当前位置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.onCurrent))
        let temp = UIBarButtonItem(title: "放置temp位置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.onTemp))
        let save = UIBarButtonItem(title: "保存temp位置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.saveTemp))
        
        let reset = UIBarButtonItem(title: "复位", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.resetBarBtnItemAction(sender:)))
        swit = UISwitch()
        swit.isOn = true
        let switBtn = UIBarButtonItem(customView: swit)
        
        self.navigationItem.rightBarButtonItems = [curr, temp, save, reset, switBtn].reversed()
        
        
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
        
        
        //let coordinate = CLLocationCoordinate2D(latitude: 39.881969601674015, longitude: 116.42249838655647)
        //let location = CLLocation(coordinate: coordinate, altitude: 40)
        
        infoLabel = UILabel()
        infoLabel.backgroundColor = UIColor(white: 0.3, alpha: 0.3)
        infoLabel.frame = CGRect(x: 6, y: 200, width: self.view.frame.size.width - 12, height: 14 * 10)
        
        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        sceneLocationView.addSubview(infoLabel)
        
        updateInfoLabelTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(self.updateInfoLabel),
            userInfo: nil,
            repeats: true)
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
        
        onTemp()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if updateInfoLabelTimer != nil{
            updateInfoLabelTimer.invalidate()
            updateInfoLabelTimer = nil
        }
        
        if locationPreviewNode != nil{
            let location = sceneLocationView.getLocationByPosition(locationPreviewNode)
            lastLocation = location
            UserDefaults.standard.set(location.coordinate.latitude, forKey: "latitude")
            UserDefaults.standard.set(location.coordinate.longitude, forKey: "longitude")
            UserDefaults.standard.set(location.altitude, forKey: "altitude")
        }
        
        sceneLocationView.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        screenCenter = CGPoint(x: size.width/2, y: size.height/2)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("view did layout subviews")
    }
    // MARK: rightBarButtonItems action
    @objc func resetBarBtnItemAction(sender: Any?){
        locationPreviewNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
    }
    @objc func onCurrent(){
        // 使用当前位置添加 node
        if locationPreviewNode == nil{
            // scn scene
            let modelScene = SCNScene(named: "art.scnassets/cup/cup.scn")!
            let cup = modelScene.rootNode.childNodes[0]
            locationPreviewNode = AudioinARKitLocationNode(location: nil, node: cup)
            sceneLocationView.addLocationNodeForCurrentPosition(locationNode: locationPreviewNode)
        }else{
            locationPreviewNode.location = sceneLocationView.currentLocation()
            sceneLocationView.updatePositionAndScaleOfLocationNode(locationNode: locationPreviewNode)
        }
        //let annotationNode = LocationTextAnnotationNode(location: nil, color: UIColor.blue, text: "当前")
        //sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
    }
    @objc func onTemp(){
        // 使用保存的位置添加 node
        guard let location = lastLocation else { return }
        
        let annotationNode = LocationTextAnnotationNode(location: location, color: UIColor.randomColor(), text: "temp")
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        let position = annotationNode.position
        annotationNode.position = SCNVector3(x: 0, y: 0, z: 0)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        annotationNode.position = position
        SCNTransaction.commit()
        
        hasPlaneOrGesture = true
        if locationPreviewNode == nil{
            // scn scene
            let modelScene = SCNScene(named: "art.scnassets/cup/cup.scn")!
            let cup = modelScene.rootNode.childNodes[0]
            locationPreviewNode = AudioinARKitLocationNode(location: location, node: cup)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: locationPreviewNode)
        }else{
            locationPreviewNode.location = location
            sceneLocationView.updatePositionAndScaleOfLocationNode(locationNode: locationPreviewNode)
        }
        
        //let annotationNode = LocationTextAnnotationNode(location: location, color: UIColor.red, text: "temp")
        //sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        
        
        print("\(#function)")
        print("\t\t currentLocation = \(sceneLocationView.currentLocation()!.coordinate)")
        print("\t\t locationManager = \(sceneLocationView.locationManager.currentLocation!.coordinate)")
        print("\t\t is lastLocation = \(location.coordinate)")
        
        print("\t\t node location = \(annotationNode.location.coordinate)")
        print("\t\t location of 1 = \(sceneLocationView.locationOfLocationNode(annotationNode).coordinate)")
        print("\t\t location of 2 = \(sceneLocationView.getLocationByPosition(annotationNode).coordinate)")
        
    }
    @objc func saveTemp(){
        // 保存当前位置
        print("\(#function)")
        print("\t\t currentLocation = \(sceneLocationView.currentLocation()!.coordinate)")
        print("\t\t locationManager = \(sceneLocationView.locationManager.currentLocation!.coordinate)")
        
        if locationPreviewNode != nil{
            print("\t\t node location = \(locationPreviewNode.location.coordinate)")
            print("\t\t location of 1 = \(sceneLocationView.locationOfLocationNode(locationPreviewNode).coordinate)")
            print("\t\t location of 2 = \(sceneLocationView.getLocationByPosition(locationPreviewNode).coordinate)")
        }
        
        lastLocation = sceneLocationView.currentLocation()
    }
    // MARK: gesture action
    private lazy var geoMaterDiffContArr = [Any?]()
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
    
    @objc func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition() {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let location = sceneLocationView.currentLocation(){
            infoLabel.text!.append("currLocation: \(location.coordinate)\n")
        }
        if let location = lastLocation {
            infoLabel.text!.append("tempLocation: \(location.coordinate)\n")
        }
        
        if let heading = sceneLocationView.locationManager.heading,
            let accuracy = sceneLocationView.locationManager.headingAccuracy {
            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
}
extension ARLocationGestureViewController: SceneLocationViewDelegate{
    
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
