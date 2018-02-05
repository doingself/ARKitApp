//
//  SceneLocationViewDemoViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/26.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

class SceneLocationViewDemoViewController: UIViewController {
    
    private var sceneLocationView: SceneLocationView!
    private var tempLocation: CLLocation?
    private var infoLabel: UILabel!
    private var updateInfoLabelTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "SceneLocationView(ARKit+CoreLocation) 根据location放置node"
        self.view.backgroundColor = UIColor.white
        
        let curr = UIBarButtonItem(title: "放置当前位置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.onCurrent))
        let temp = UIBarButtonItem(title: "放置temp位置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.onTemp))
        let save = UIBarButtonItem(title: "保存temp位置", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.saveTemp))
        self.navigationItem.rightBarButtonItems = [curr, temp, save].reversed()
        
        
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
        
        sceneLocationView.run()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if updateInfoLabelTimer != nil{
            updateInfoLabelTimer.invalidate()
            updateInfoLabelTimer = nil
        }
        
        sceneLocationView.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("view did layout subviews")
    }
    @objc func onCurrent(){
        // 使用当前位置添加 node
        let annotationNode = LocationTextAnnotationNode(location: nil, color: UIColor.blue, text: "当前")
        sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
    }
    @objc func onTemp(){
        // 使用保存的位置添加 node
        guard let location = tempLocation else { return }
        let annotationNode = LocationTextAnnotationNode(location: location, color: UIColor.red, text: "temp")
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
    }
    @objc func saveTemp(){
        // 保存当前位置
        print("\(#function)")
        print("\t\t currentLocation = \(sceneLocationView.currentLocation()!.coordinate)")
        print("\t\t locationManager = \(sceneLocationView.locationManager.currentLocation!.coordinate)")
        tempLocation = sceneLocationView.currentLocation()
    }
    @objc func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition() {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let location = tempLocation {
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
extension SceneLocationViewDemoViewController: SceneLocationViewDelegate{
    
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
        
    }
}
