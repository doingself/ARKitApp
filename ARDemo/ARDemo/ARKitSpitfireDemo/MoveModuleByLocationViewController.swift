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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "根据 location/SCNVector3 移动模型"
        self.view.backgroundColor = UIColor.white
        
        
        let move = UIBarButtonItem(title: "move", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.move(sender:)))
        let addX = UIBarButtonItem(title: "addX", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.addX(sender:)))
        let addY = UIBarButtonItem(title: "addY", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.addY(sender:)))
        let addZ = UIBarButtonItem(title: "addZ", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.addZ(sender:)))
        let reset = UIBarButtonItem(title: "reset", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.reset(sender:)))
        self.navigationItem.rightBarButtonItems = [move, addX, addY, addZ, reset]
        
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
        
        locationService.stopLocation()
        
        sceneView.session.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    func sessionRun(){
        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        sceneView.session.run(config)
    }
    @objc func move(sender: Any?){
        guard let location = locationService.currentLocation else { return }
        if endLocation == nil {
            endLocation = location
            return
        }
        print("endLocation \t\t= \(endLocation!)")
        print("currentLocation \t= \(location)")
        print("distance = \(endLocation.distance(from: location))")
        previewNode.moveFrom(location: endLocation, to: location)
        endLocation = location
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
