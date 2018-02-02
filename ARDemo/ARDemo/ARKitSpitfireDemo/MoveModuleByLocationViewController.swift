//
//  MoveModuleByLocationViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/25.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

class MoveModuleByLocationViewController: UIViewController {

    private lazy var locationService: LocationService = {
        return LocationService()
    }()
    
    private var sceneView: ARSCNView!
    private var previewNode: PreviewNode!
    private var endLocation: CLLocation!
    
    var infoLab: UILabel!
    var updateInfoLabelTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "根据 location/SCNVector3 移动模型"
        self.view.backgroundColor = UIColor.white
        
        
        let save = UIBarButtonItem(title: "保存当前坐标", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.save(sender:)))
        let move = UIBarButtonItem(title: "移动到保存的坐标", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.move(sender:)))
        let addX = UIBarButtonItem(title: "addX", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.addX(sender:)))
        let addY = UIBarButtonItem(title: "addY", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.addY(sender:)))
        let addZ = UIBarButtonItem(title: "addZ", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.addZ(sender:)))
        let reset = UIBarButtonItem(title: "reset", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.reset(sender:)))
        self.navigationItem.rightBarButtonItems = [save, move, addX, addY, addZ, reset]
        
        // 获取位置信息
        locationService.startLocation()
        
        // ar kit
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        
        // scn scene
        let modelScene = SCNScene(named: "art.scnassets/cup/cup.scn")!
        let cup = modelScene.rootNode.childNodes[0]
        previewNode = PreviewNode(node: cup)
        
        previewNode.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        previewNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        sceneView.scene.rootNode.addChildNode(previewNode)
        
        infoLab = UILabel()
        infoLab.backgroundColor = UIColor(white: 0.3, alpha: 0.3)
        infoLab.frame = CGRect(x: 6, y: 200, width: self.view.frame.size.width - 12, height: 14 * 10)
        
        infoLab.font = UIFont.systemFont(ofSize: 10)
        infoLab.textAlignment = .left
        infoLab.textColor = UIColor.white
        infoLab.numberOfLines = 0
        sceneView.addSubview(infoLab)
        
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
        
        sessionRun()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if updateInfoLabelTimer != nil{
            updateInfoLabelTimer.invalidate()
            updateInfoLabelTimer = nil
        }
        
        locationService.stopLocation()
        
        sceneView.session.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    func sessionRun(){
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.worldAlignment = .gravityAndHeading
        sceneView.session.run(config)
    }
    @objc func updateInfoLabel() {
        // 摄像头 相对于 previewNode 的 position
        let position = sceneView.scene.rootNode.convertPosition(sceneView.pointOfView!.position, to: previewNode)
        infoLab.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        
        if let eulerAngles = sceneView.pointOfView?.eulerAngles {
            infoLab.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let heading = locationService.heading,
            let accuracy = locationService.currentHeadingAccuracy{
            infoLab.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }
        
        if let location = locationService.currentLocation {
            infoLab.text!.append("f location = \(location.coordinate)\n")
        }
        if endLocation != nil {
            infoLab.text!.append("t location = \(endLocation.coordinate)\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLab.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
    @objc func save(sender: Any?){
        guard let location = locationService.currentLocation else { return }
        endLocation = location
    }
    @objc func move(sender: Any?){
        guard let location = locationService.currentLocation else { return }
        if endLocation != nil {
            previewNode.moveFrom(location: endLocation, to: location)
        }
    }
    @objc func addX(sender: Any?){
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        
        let position: SCNVector3 = previewNode.position
        previewNode.position = SCNVector3(x: position.x - 0.1, y: position.y, z: position.z)
        
        SCNTransaction.commit()
    }
    @objc func addY(sender: Any?){
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        
        let position: SCNVector3 = previewNode.position
        previewNode.position = SCNVector3(x: position.x, y: position.y - 0.1, z: position.z)
        
        SCNTransaction.commit()
    }
    @objc func addZ(sender: Any?){
        
        //print("previewNode = \(previewNode)")
        //print("position = \(previewNode.position)")
        //print("simdPosition = \(previewNode.simdPosition)")
        //print("worldPosition = \(previewNode.worldPosition)")
        //print("simdWorldPosition = \(previewNode.simdWorldPosition)")
        //print("transform = \(previewNode.transform)")
        //print("simdTransform = \(previewNode.simdTransform)")
        //print("worldTransform = \(previewNode.worldTransform)")
        //print("simdWorldTransform = \(previewNode.simdWorldTransform)")
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        
        let position: SCNVector3 = previewNode.position
        previewNode.position = SCNVector3(x: position.x, y: position.y, z: position.z - 0.1)
        
        SCNTransaction.commit()
    }
    @objc func reset(sender: Any?){
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        
        previewNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        SCNTransaction.commit()
    }
    
}

extension MoveModuleByLocationViewController: ARSCNViewDelegate{
    
}
