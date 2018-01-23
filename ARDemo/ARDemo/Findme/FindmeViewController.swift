//
//  FindmeViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/23.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import ARKit

class FindmeViewController: UIViewController {
    
    private var sceneView: ARSCNView!
    
    // 录像
    private var videoRecodeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "查看设备的运动轨迹 使用 ARSCNView.scene 加载已经保存的 SCNScene"
        self.view.backgroundColor = UIColor.white
        
        // 录像
        videoRecodeBtn = UIButton(type: UIButtonType.system)
        videoRecodeBtn.setTitle("查询", for: UIControlState.normal)
        videoRecodeBtn.setTitle("返回", for: UIControlState.selected)
        videoRecodeBtn.addTarget(self, action: #selector(self.recordBtnAction(sender:)), for: UIControlEvents.touchUpInside)
        let recordBarBtnItem = UIBarButtonItem(customView: videoRecodeBtn)
        self.navigationItem.rightBarButtonItem = recordBarBtnItem
        
        // ar scn view
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
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
        
        sceneView.session.pause()
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    private func sessionRun(){
        let configure = ARWorldTrackingConfiguration()
        configure.planeDetection = .horizontal
        sceneView.session.run(configure, options: [])
        
    }
    
    // MARK: action
    @objc func recordBtnAction(sender: Any?){
        
        videoRecodeBtn.isSelected = !videoRecodeBtn.isSelected
        
        if videoRecodeBtn.isSelected {
            // 开始
            sceneView.scene = meScene
            
            sessionRun()
        }else{
            // 结束
            sceneView.session.pause()
        }
    }
}
extension FindmeViewController: ARSCNViewDelegate{
    // MARK: SCN Scene Renderer Delegate 代理
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
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
