//
//  ThirteenARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/15.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

import Photos
// ReplayKit不需要太大电量损耗和性能损耗就可以产出高清的视频记录。ReplayKit支持使用A7芯片以上，操作系统为iOS 9或更高版本的设备。
import ReplayKit

// 参考 https://github.com/chriswebb09/ARKitSpitfire
class ThirteenARViewController: UIViewController {
    
    private lazy var locationService: LocationService = {
        return LocationService()
    }()
    
    private var sceneView: ARSCNView!
    private var previewNode: PreviewNode?
    private var swit: UISwitch!
    
    // 中心
    private var screenCenter: CGPoint = .zero
    // 检测到地面或者被拖拽, 取消 update at time
    private var hasPlaneOrGesture = false
    // 是否选中模型,用于 拖拽 / 旋转
    private var selectModel = false
    // 拖拽
    private var pinchBeginNodeScaleX: Float = 0.0
    
    // 录像
    private var videoRecodeBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "根据 location 移动模型 + 手势 复位 截图 录制"
        self.view.backgroundColor = UIColor.white
        
        let save = UIBarButtonItem(title: "保存", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.saveBarBtnItemAction(sender:)))
        let reset = UIBarButtonItem(title: "复位", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.resetBarBtnItemAction(sender:)))
        swit = UISwitch()
        let switBtn = UIBarButtonItem(customView: swit)
        // 录像
        videoRecodeBtn = UIButton(type: UIButtonType.system)
        videoRecodeBtn.setTitle("开始", for: UIControlState.normal)
        videoRecodeBtn.setTitle("结束", for: UIControlState.selected)
        videoRecodeBtn.addTarget(self, action: #selector(self.recordBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        let recordBarBtnItem = UIBarButtonItem(customView: videoRecodeBtn)
        self.navigationItem.rightBarButtonItems = [save,reset,switBtn, recordBarBtnItem]
        
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
        
        locationService.startLocation()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        locationService.stopLocation()
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        screenCenter = CGPoint(x: size.width/2, y: size.height/2)
    }
    
    private func sessionRun(){
        let configure = ARWorldTrackingConfiguration()
        configure.planeDetection = .horizontal
        sceneView.session.run(configure, options: [])
        
        previewNode!.position = SCNVector3(x: 0, y: 0, z: -1)
        
        // FIXME: 移动到指定位置
        hasPlaneOrGesture = true
        let from: CLLocation = CLLocation(latitude: 116.4225172340665, longitude: 39.881984894921175)
        let to: CLLocation = CLLocation(latitude: 116.4225172340665, longitude: 39.88199646)
        previewNode?.moveFrom(location: from, to: to)
    }
    
    // MARK: action
    @objc func recordBtnAction(sender: Any?){
        
        // 是否支持录像
        guard RPScreenRecorder.shared().isAvailable else {
            return
        }
        
        videoRecodeBtn.isSelected = !videoRecodeBtn.isSelected
        
        if videoRecodeBtn.isSelected {
            // 开始录像
            if RPScreenRecorder.shared().isRecording == false{
                let recorder = RPScreenRecorder.shared()
                recorder.delegate = self
                recorder.startRecording(handler: { (err: Error?) in
                    if let e = err{
                        print(" start err = \(e)")
                    }
                })
            }
        }else{
            // 结束录像, 保存
            if RPScreenRecorder.shared().isRecording == true{
                
                RPScreenRecorder.shared().stopRecording(handler: { (previewVC: RPPreviewViewController?, err: Error?) in
                    
                    if let e = err{
                        print(" start err = \(e)")
                    }
                    
                    guard let preview = previewVC else {
                        print("Preview controller is not available.")
                        return
                    }
                    print("stop vc = \(previewVC!)")
                    
                    let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
                    
                    let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                        RPScreenRecorder.shared().discardRecording(handler: {
                            print("RPScreenRecorder.shared().discardRecording")
                        })
                    })
                    
                    let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                        preview.previewControllerDelegate = self
                        /*
                         2018-01-17 15:48:24.291547+0800 ARDemo[3122:1306086] *** Terminating app due to uncaught exception 'NSGenericException', reason: 'UIPopoverPresentationController (<UIPopoverPresentationController: 0x110694600>) should have a non-nil sourceView or barButtonItem set before the presentation occurs.'
                         *** First throw call stack:
                         (0x182a82364 0x181cc8528 0x18cbaafec 0x18c2b1c18 0x18c2af6dc 0x18c1d1b3c 0x18c1c4ef0 0x18bf5654c 0x182a29edc 0x182a27894 0x182a27e50 0x182947e58 0x1847f4f84 0x18bfc767c 0x100ef12dc 0x18246456c)
                         libc++abi.dylib: terminating with uncaught exception of type NSException
                         */
                        self.present(preview, animated: true, completion: nil)
                    })
                    
                    alert.addAction(editAction)
                    alert.addAction(deleteAction)
                    self.present(alert, animated: true, completion: nil)
                })
            }
        }
    }
    @objc func saveBarBtnItemAction(sender: Any?){
        let block = {
            // 保存截图到相册
            let img = self.sceneView.snapshot()
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
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
    @objc func resetBarBtnItemAction(sender: Any?){
        previewNode!.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
    }
    
    // MARK: gesture
    private lazy var geoMaterDiffContArr = [Any?]()
    private func refreshStyle(node: SCNNode, isSelect: Bool, i: Int = 0) -> Int{
        
        var k = i
        if let materials = node.geometry?.materials{
            for j in 0 ..< materials.count {
                let material = materials[j]
                if isSelect{
                    geoMaterDiffContArr.append(material.diffuse.contents)
                    material.diffuse.contents = UIColor.red
                }else{
                    if let filePath = geoMaterDiffContArr[j+k] as? String{
                        // FIXME: Failed loading : <C3DImage 0x1c02f2200 src:file:/../../...png [0.000000x0.000000]>
                        //                        material.diffuse.contents = UIImage(named: filePath)
                        //                        material.diffuse.contents = UIImage(named: "art.scnassets/" + filePath)
                        //                        let fileName = (filePath as NSString).lastPathComponent //.replacingOccurrences(of: ".png", with: "")
                        //                        material.diffuse.contents = UIImage(named: fileName)
                        
                        material.diffuse.contents = UIImage(named: "grass.jpg")
                    }else{
                        material.diffuse.contents = geoMaterDiffContArr[j+k]
                    }
                    //material.diffuse.contents = geoMaterDiffContArr[j+k]
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
        if sender.state != .ended {
            return
        }
        guard let local = locationService.currentLocation else{ return }
        print("panGesture local \(local)")
        
        // FIXME: 移动到指定位置
        let from: CLLocation = CLLocation(latitude: 116.4225172340665, longitude: 39.88199646)
        let to: CLLocation = local
        print("pangesture \(local)")
        previewNode?.moveFrom(location: from, to: to)
        
    }
    @objc func panGesture2(sender: UIGestureRecognizer){
        // 滑动的距离
        guard let pan = sender as? UIPanGestureRecognizer else {
            return
        }
        
        let locationPoint = sender.location(in: sceneView)
        
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
        
        selectModel = swit.isOn
        
        if selectModel {
            // 拖拽
            if pan.state == .began{
                let _ = refreshStyle(node: previewNode!, isSelect: true)
            }else if pan.state != .changed{
                // 拖拽 结束/失败/取消
                selectModel = false
                let _ = refreshStyle(node: previewNode!, isSelect: false)
            }
            
            let arHitTestResult = sceneView.hitTest(locationPoint, types: [ARHitTestResult.ResultType.featurePoint, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent])
            //let arHitTestResult = sceneView.hitTest(locationPoint, types: ARHitTestResult.ResultType.existingPlane)
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

extension ThirteenARViewController: ARSCNViewDelegate{
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
        // 不检测平面
    }
    // MARK: ARSessionObserver 代理
    func sessionInterruptionEnded(_ session: ARSession) {
        sessionRun()
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        sessionRun()
    }
}
extension ThirteenARViewController: RPScreenRecorderDelegate{
    // MARK: replay kit rp screen recorder delegate 代理
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        print("screenRecorder did stop recording")
    }
}
extension ThirteenARViewController: RPPreviewViewControllerDelegate{
    // MARK: replay kit rp preview view controller delegate 代理
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        print("previewControllerDidFinish")
        previewController.dismiss(animated: true) {
            print("previewControllerDidFinish dismiss blok")
        }
    }
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        print("previewController didFinishWithActivityTypes")
    }
}


