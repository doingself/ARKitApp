//
//  OneARViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/27.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit
import ARKit

class OneARViewController: UIViewController {

    // AR 场景视图
    private var arSCNView: ARSCNView!
    private var arSession: ARSession!
    private var arConfiguration: ARWorldTrackingConfiguration!
    private var planeNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "点击屏幕添加飞机"
        self.view.backgroundColor = UIColor.white
        
        
        arConfiguration = ARWorldTrackingConfiguration()
        // 追踪方向
        arConfiguration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        // 自适应灯光（相机从暗到强光快速过渡效果会平缓一些）
        arConfiguration.isLightEstimationEnabled = true
        
        arSession = ARSession()
        
        arSCNView = ARSCNView(frame: self.view.bounds)
        arSCNView.session = arSession
        // 自动刷新灯光。默认值为 true
        arSCNView.automaticallyUpdatesLighting = true
        // 自动照亮没有光源的场景。默认值为 false
        arSCNView.autoenablesDefaultLighting = true
        
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard planeNode == nil else{
            return
        }
        
        // 使用场景加载scn文件 scn格式文件是一个基于3D建模的文件，使用3DMax软件可以创建
        let scene: SCNScene = SCNScene(named: "art.scnassets/ship/ship.scn")!
        
        // 所有的场景有且只有一个根节点，其他所有节点都是根节点的子节点
        let node: SCNNode = scene.rootNode.childNodes[0]
        //设置节点的位置
        node.position = SCNVector3(x: 0, y: -1, z: -1)
        //缩放
        node.scale = SCNVector3Make(0.5, 0.5, 0.5);
        
        // 将飞机节点添加到当前屏幕中
        self.arSCNView.scene.rootNode.addChildNode(node)
        
        planeNode = node
    }
}
