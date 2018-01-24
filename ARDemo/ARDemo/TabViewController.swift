//
//  TabViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/27.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit

// 弧度 ＝ 度 × π / 180
// 度 ＝ 弧度 × 180° / π
// 180度 ＝ π弧度

// 90°＝ 90 × π / 180 ＝ π/2 弧度
// 60°＝ 60 × π / 180 ＝ π/3 弧度



import CoreLocation
import ARKit

// 保存轨迹, 可以通过 key archive 归档
var singleScene: SCNScene!
// 保存圆点的 GPS
var lastLocation: CLLocation!


class TabViewController: UIViewController {
    
    private var tabView: UITableView!
    private let cellIdentifices = "cell"
    private lazy var datas: [String] = {
        let arr = [
            // touchbegin
            "点击屏幕touchesBegan 添加飞机 SCNScene.node self.arSCNView.scene.rootNode.addChildNode(node)",
            "检测平面ARPlaneAnchor添加SCNPlane, 1s后添加飞机SCNScene.node tap截图arSCNView.snapshot(), long录制RPScreenRecorder",
            "检测平面ARPlaneAnchor添加SCNBox, 点击屏幕touchesBegan 添加飞机 SCNScene.node + 跟随相机移动 ARSessionDelegate.didUpdate position=frame.camera.transform.columns.3",
            "点击屏幕touchesBegan 添加飞机 SCNScene.node, 添加旋转动画CABasicAnimation 类似地球公转",
            
            // gesture
            "检测平面ARPlaneAnchor添加SCNBox, 1s后添加飞机SCNScene.node 点击屏幕 tap 获取 ARHitTestResult 使用 hitResult.worldTransform.columns.3 添加 SCNNode(geometry: SCNBox()).position",
            "检测平面ARPlaneAnchor设置模型simdTransform=anchor.transform, tap/pan 设置 模型simdTransform = ARHitTestResult.worldTransform",
            "pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform",
            "tap/pan/pinch, tap 设置 模型 position = ARHitTestResult.worldTransform.cloumn.3,  pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform",
            "基于上一个 item 摆放家具 pan选中模型进行拖拽, 否则旋转",
            
            // apple demo
            //1. AudioinARKit is 茶杯 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd
            //2. InteractiveContentwithARKit is 变色龙 点击变色+拖拽
            "基于AudioinARKit 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd, 添加 pan/pinch pan拖拽时改变模型样式material.diffuse.contents",
            "基于上一个 item, 添加截图sceneView.snapshot(), 复位previewNode!.eulerAngles",
            "基于上一个 item, 添加摄像ReplayKit.RPScreenRecorder",
            
            // 定位 https://github.com/chriswebb09/ARKitSpitfire
            "根据 location 移动模型",
            
            // CoreML
            "Core ML + ARSCNView 图像识别",
            "Core ML + ImagePicker 图像识别",
            
            // find me 保存设备运动轨迹并查看 https://github.com/mmoaay/Findme
            "保存设备的运动轨迹 运动过程中 添加 node 到 ARSCNView.scene.rootNode.childeNodes 中, 将当前 ARSCNView.scene 保存到起来( SCNScene )",
            "查看设备的运动轨迹 使用 ARSCNView.scene 加载已经保存的 SCNScene",
            "find me + spitfire"
        ]
        return arr
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "AR Demo"
        
        tabView = UITableView(frame: self.view.bounds, style: UITableViewStyle.plain)
        tabView.delegate = self
        tabView.dataSource = self
        
        tabView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifices)
        tabView.tableFooterView = UIView()
        
        tabView.rowHeight = UITableViewAutomaticDimension
        tabView.estimatedRowHeight = 44.0
        
        self.view.addSubview(tabView)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension TabViewController: UITableViewDataSource{
    // MARK: table data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifices, for: indexPath)
        cell.selectionStyle = .gray
        cell.accessoryType = .disclosureIndicator
        
        let data = self.datas[indexPath.row]
        cell.textLabel?.text = data
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension TabViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var v: UIViewController?
        
        switch indexPath.row {
            
            // touchbegin
            //"点击屏幕touchesBegan 添加飞机 SCNScene.node self.arSCNView.scene.rootNode.addChildNode(node)",
            //"检测平面ARPlaneAnchor添加SCNPlane, 1s后添加飞机SCNScene.node tap截图arSCNView.snapshot(), long录制RPScreenRecorder",
            //"检测平面ARPlaneAnchor添加SCNBox, 点击屏幕touchesBegan 添加飞机 SCNScene.node + 跟随相机移动 ARSessionDelegate.didUpdate position=frame.camera.transform.columns.3",
            //"点击屏幕touchesBegan 添加飞机 SCNScene.node, 添加旋转动画CABasicAnimation 类似地球公转",
            
        case 0:
            v = OneARViewController()
        case 1:
            v = TwoARViewController()
        case 2:
            v = ThreeARViewController()
        case 3:
            v = FourARViewController()
            
            // gesture
            //"检测平面ARPlaneAnchor添加SCNBox, 1s后添加飞机SCNScene.node 点击屏幕 tap 获取 ARHitTestResult 使用 hitResult.worldTransform.columns.3 添加 SCNNode(geometry: SCNBox()).position",
            //"检测平面ARPlaneAnchor设置模型simdTransform=anchor.transform, tap/pan 设置 模型simdTransform = ARHitTestResult.worldTransform",
            //"pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform",
            //"tap/pan/pinch, tap 设置 模型 position = ARHitTestResult.worldTransform.cloumn.3,  pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform",
            //"基于上一个 item 摆放家具 pan选中模型进行拖拽, 否则旋转",

        case 4:
            v = FiveARViewController()
        case 5:
            v = SixARViewController()
        case 6:
            v = SevenARViewController()
        case 7:
            v = EightARViewController()
        case 8:
            v = NineARViewController()
            
            // apple demo
            //1. AudioinARKit is 茶杯 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd
            //2. InteractiveContentwithARKit is 变色龙 点击变色+拖拽
            //"基于AudioinARKit 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd, 添加 pan/pinch pan拖拽时改变模型样式material.diffuse.contents",
            //"基于上一个 item, 添加截图sceneView.snapshot(), 复位previewNode!.eulerAngles",
            //"基于上一个 item, 添加摄像ReplayKit.RPScreenRecorder",
        case 9:
            v = TenARViewController()
        case 10:
            v = ElevenARViewController()
        case 11:
            v = TwelveARViewController()
            
        case 12:
            // 根据 location 移动模型
            v = ThirteenARViewController()

        case 13:
            //"Core ML + ARSCNView",
            v = MLDemoViewController()
            
        case 14:
            //"Core ML + ImagePicker"
            v = ML_ImgViewController()
            
            // find me
        case 15:
            v = SavemeViewController()
        case 16:
            v = FindmeViewController()
        case 17:
            v = FindmeByLocationViewController()
            
        default:
            break
        }
        if v != nil{
            self.navigationController?.pushViewController(v!, animated: true)
        }
        
    }
}
