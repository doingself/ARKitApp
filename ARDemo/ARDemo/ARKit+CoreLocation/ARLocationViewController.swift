//
//  ARLocationViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/2/1.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

var locationService: LocationService!

class ARLocationViewController: UIViewController {
    
    private var sceneView: ARSCNView!
    private var sceneNode: SCNNode!
    private var cupNode: LocationNode!
    
    private var infoLabel: UILabel!
    private var updateInfoLabelTimer: Timer!
    private var tempLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "提取 ARKit+Location 中的 ARSCNView"
        self.view.backgroundColor = UIColor.white
        
        if locationService == nil{
            locationService = LocationService()
            locationService.startLocation()
        }
        
        // ui
        setupBarBtnItem()
        setupARSCNView()
        setupGesture()
        setupTimer()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let configure = ARWorldTrackingConfiguration()
        configure.planeDetection = .horizontal
        configure.worldAlignment = .gravityAndHeading
        sceneView.session.run(configure, options: [])
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if updateInfoLabelTimer != nil{
            updateInfoLabelTimer.invalidate()
            updateInfoLabelTimer = nil
        }
        
        sceneView.session.pause()
    }
    
    // MARK: setup ui
    private func setupBarBtnItem(){
        let save = UIBarButtonItem(title: "暂存", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.barBtnItemAction(sender:)))
        let update = UIBarButtonItem(title: "放置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.barBtnItemAction2(sender:)))
        self.navigationItem.rightBarButtonItems = [save, update]
    }
    private func setupGesture(){
        // tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(sender:)))
        // pan 拖拽
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(sender:)))
        pan.maximumNumberOfTouches = 1
        // pinch 捏
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(sender:)))
        
        sceneView.isUserInteractionEnabled = true
        sceneView.addGestureRecognizer(tap)
        sceneView.addGestureRecognizer(pan)
        sceneView.addGestureRecognizer(pinch)
    }
    private func setupTimer(){
        infoLabel = UILabel()
        infoLabel.backgroundColor = UIColor(white: 0.3, alpha: 0.3)
        infoLabel.frame = CGRect(x: 6, y: 200, width: self.view.frame.size.width - 12, height: 14 * 16)
        
        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        self.view.addSubview(infoLabel)
        
        updateInfoLabelTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(self.updateInfoLabel),
            userInfo: nil,
            repeats: true)
        
    }
    private func setupARSCNView(){
        sceneView = ARSCNView(frame: self.view.bounds)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        self.view.addSubview(sceneView)
        
        sceneNode = SCNNode()
        sceneView.scene.rootNode.addChildNode(sceneNode)
    }
    @objc func updateInfoLabel(){
        infoLabel.text = "\n"
        if tempLocation != nil {
            infoLabel.text?.append("\n temp location = \(tempLocation.coordinate)")
        }
        if let location = currentLocation(){
            infoLabel.text?.append("\n current location = \(location.coordinate)")
        }
        if let position = currentScenePosition(){
            infoLabel.text?.append("\n current position = \(position)")
        }
        if let eulerAngles = sceneView.pointOfView?.eulerAngles{
            infoLabel.text?.append("\n euler angles = \(eulerAngles)")
        }
        if let heading = locationService.heading{
            infoLabel.text?.append("\n heading = \(heading)")
        }
        if let accuracy = locationService.currentHeadingAccuracy{
            infoLabel.text?.append("\n current heading accuracy = \(accuracy)")
        }
                
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))\n")
        }
    }
    // MARK: bar button item
    @objc func barBtnItemAction(sender: Any?){
        if let location = locationService.currentLocation {
            tempLocation = location
        }
    }
    @objc func barBtnItemAction2(sender: Any?){
        if tempLocation != nil {
            cupNode.location = tempLocation
            updatePositionAndScaleOfLocationNode(locationNode: cupNode, animated: true, duration: 10)
        }
    }
    // MARK: gesture
    @objc func tapGesture(sender: Any?){
        if cupNode == nil{
            // scn scene
            let modelScene = SCNScene(named: "art.scnassets/cup/cup.scn")!
            let cup = modelScene.rootNode.childNodes[0]
            // 添加到当前位置
            cupNode = LocationNode(location: nil)
            cupNode.addChildNode(cup)
            addLocationNodeForCurrentPosition(locationNode: cupNode)
        }else{
            // 移动到当前位置
            cupNode.location = currentLocation()
            updatePositionAndScaleOfLocationNode(locationNode: cupNode, animated: true, duration: 10)
        }
    }
    @objc func panGesture(sender: Any?){
        guard cupNode != nil else{ return }
        // 滑动的距离
        guard let pan = sender as? UIPanGestureRecognizer else {
            return
        }
        if pan.state == .began{
            refreshStyle(node: cupNode)
        }
        let locationPoint = pan.location(in: sceneView)
        // 拖拽
        let arHitTestResult = sceneView.hitTest(locationPoint, types: [ARHitTestResult.ResultType.featurePoint, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent])
        if let hit = arHitTestResult.first{
            cupNode.simdPosition = hit.worldTransform.translation
            
            let location = locationOfLocationNode(cupNode)
            cupNode.location = location
            //updatePositionAndScaleOfLocationNode(locationNode: cupNode, animated: true, duration: 10)
        }
    }
    @objc func pinchGesture(sender: Any?){
        
    }
    private func refreshStyle(node: SCNNode) {
        if let materials = node.geometry?.materials{
            for j in 0 ..< materials.count {
                let material = materials[j]
                material.diffuse.contents = UIColor.randomColor()
            }
        }
        for n in node.childNodes{
            self.refreshStyle(node: n)
        }
    }
}
extension ARLocationViewController{
    // MARK: AR SCN View
    private func currentScenePosition() -> SCNVector3? {
        guard let pointOfView = sceneView.pointOfView else {
            return nil
        }
        return sceneView.scene.rootNode.convertPosition(pointOfView.position, to: sceneNode)
    }
    private func currentLocation() -> CLLocation?{
        return locationService.currentLocation
    }
    private func addLocationNodeForCurrentPosition(locationNode: LocationNode) {
        guard let currentPosition: SCNVector3 = currentScenePosition(),
            let currentLocation: CLLocation = currentLocation() else {
                return
        }
        
        locationNode.location = currentLocation
        locationNode.position = currentPosition
        
        sceneNode.addChildNode(locationNode)
    }
    private func addLocationNodeWithConfirmedLocation(locationNode: LocationNode) {
        if locationNode.location == nil {
            return
        }
        
        updatePositionAndScaleOfLocationNode(locationNode: locationNode, animated: false, duration: 0.1)
        
        sceneNode?.addChildNode(locationNode)
    }
    private func updatePositionAndScaleOfLocationNode(locationNode: LocationNode, animated: Bool, duration: TimeInterval) {
        // FIXME: updatePositionAndScaleOfLocationNode
        guard let currentPosition: SCNVector3 = currentScenePosition(),
            let currentLocation: CLLocation = currentLocation() else{
                return
        }
        
        let locationNodePostion: SCNVector3 = locationNode.position
        //let locationNodeLocation = locationOfLocationNode(locationNode)
        let locationNodeLocation: CLLocation = locationNode.location!
        let locationTranslation: LocationTranslation = currentLocation.translation(toLocation: locationNodeLocation)
        
        let position = SCNVector3(
            x: currentPosition.x + Float(locationTranslation.longitudeTranslation),
            y: currentPosition.y + Float(locationTranslation.altitudeTranslation),
            z: currentPosition.z - Float(locationTranslation.latitudeTranslation))
        
        let position2 = SCNVector3(
            x: position.x + locationNodePostion.x,
            y: position.y + locationNodePostion.y,
            z: position.z + locationNodePostion.z)
        
        
        print("locationNodeLocation \(locationNodeLocation.coordinate)")
        print("locationTranslation \(locationTranslation)")
        print("position \(position)")
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 5
        locationNode.position = position2
        //locationNode.position = position
        //locationNode.scale = SCNVector3(x: 1, y: 1, z: 1)
        SCNTransaction.commit()
    }
    private func locationOfLocationNode(_ locationNode: LocationNode) -> CLLocation{
        // FIXME: locationOfLocationNode
        guard let position = currentScenePosition(),
            let location = currentLocation() else{
                return locationNode.location
        }
        let locationEstimate = SceneLocationEstimate(location: location, position: position)
        let translatedLocation = locationEstimate.translatedLocation(to: locationNode.position)
        return translatedLocation
    }
    
    
}
extension ARLocationViewController: ARSCNViewDelegate{

    // MARK: AR SCN View Delegate
    
}
