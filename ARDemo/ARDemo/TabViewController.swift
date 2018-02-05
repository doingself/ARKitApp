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

class TabViewController: UIViewController {
    
    private var tabView: UITableView!
    private let cellIdentifices = "cell"
    private let navTitle = "title"
    private let vc = "vc"
    
    private lazy var groups: [String] = {
        let arr = [
            "touch begin",
            "gesture",
            //1. AudioinARKit is 茶杯 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd
            //2. InteractiveContentwithARKit is 变色龙 点击变色+拖拽
            "apple demo AudioinARKit/InteractiveContentwithARKit",
            // 定位 https://github.com/chriswebb09/ARKitSpitfire
            "location ARKitSpitfire",
            "CoreML",
            // find me 保存设备运动轨迹并查看 https://github.com/mmoaay/Findme
            "保存查看SCNScene Findme",
            // ARKit+CoreLocation https://github.com/ProjectDent/ARKit-CoreLocation
            "ARKit+CoreLocation"
        ]
        return arr
    }()
    private lazy var datas: [Int: [Any]] = {
        let dict = [
            // touch begin
            0:[
                [vc: OneARViewController(),
                 navTitle: "点击屏幕touchesBegan 添加飞机 SCNScene.node self.arSCNView.scene.rootNode.addChildNode(node)"],
                
                [vc: TwoARViewController(),
                 navTitle: "检测平面ARPlaneAnchor添加SCNPlane, 1s后添加飞机SCNScene.node tap截图arSCNView.snapshot(), long录制RPScreenRecorder"],
                
                [vc: ThreeARViewController(),
                 navTitle: "检测平面ARPlaneAnchor添加SCNBox, 点击屏幕touchesBegan 添加飞机 SCNScene.node + 跟随相机移动 ARSessionDelegate.didUpdate position=frame.camera.transform.columns.3"],
                
                [vc: FourARViewController(),
                 navTitle: "点击屏幕touchesBegan 添加飞机 SCNScene.node, 添加旋转动画CABasicAnimation 类似地球公转"],
            ],
            // gesture
            1:[
                [vc: FiveARViewController(),
                 navTitle: "检测平面ARPlaneAnchor添加SCNBox, 1s后添加飞机SCNScene.node 点击屏幕 tap 获取 ARHitTestResult 使用 hitResult.worldTransform.columns.3 添加 SCNNode(geometry: SCNBox()).position"],
                
                [vc: SixARViewController(),
                 navTitle: "检测平面ARPlaneAnchor设置模型simdTransform=anchor.transform, tap/pan 设置 模型simdTransform = ARHitTestResult.worldTransform"],
                
                [vc: SevenARViewController(),
                 navTitle: "pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform"],
                
                [vc: EightARViewController(),
                 navTitle: "tap/pan/pinch, tap 设置 模型 position = ARHitTestResult.worldTransform.cloumn.3,  pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform"],
                
                [vc: NineARViewController(),
                 navTitle: "基于上一个 item 摆放家具 pan选中模型进行拖拽, 否则旋转"],
            ],
            // "apple demo AudioinARKit/InteractiveContentwithARKit"
            2:[
                [vc: TenARViewController(),
                 navTitle: "基于AudioinARKit 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd, 添加 pan/pinch pan拖拽时改变模型样式material.diffuse.contents"],
                
                [vc: ElevenARViewController(),
                 navTitle: "基于上一个 item, 添加截图sceneView.snapshot(), 复位previewNode!.eulerAngles"],
                
                [vc: TwelveARViewController(),
                 navTitle: "基于上一个 item, 添加摄像ReplayKit.RPScreenRecorder"],
            ],
            
            //"location ARKitSpitfire",
            3:[
                [vc: ThirteenARViewController(),
                 navTitle: "根据 location 移动模型 + 手势 复位 截图 录制"],
                
                [vc: MoveModuleByLocationViewController(),
                 navTitle: "根据 location/SCNVector3 移动模型"],
            ],
            //"CoreML",
            4:[
                [vc: MLDemoViewController(),
                 navTitle: "Core ML + ARSCNView 图像识别"],
                
                [vc: ML_ImgViewController(),
                 navTitle: "Core ML + ImagePicker 图像识别"],
            ],
            //"保存查看 SCNScene , Findme"
            5:[
                [vc: SavemeViewController(),
                 navTitle: "保存设备的运动轨迹 运动过程中 添加 node 到 ARSCNView.scene.rootNode.childeNodes 中, 将当前 ARSCNView.scene 保存到起来( SCNScene )"],
                
                [vc: FindmeViewController(),
                 navTitle: "查看设备的运动轨迹 使用 ARSCNView.scene 加载已经保存的 SCNScene"],
                
                [vc: SavemeByLocationViewController(),
                 navTitle: "保存 find me + spitfire"],
                
                [vc: FindmeByLocationViewController(),
                 navTitle: "查看 find me + spitfire"],
            ],
            
            // ARKit+CoreLocation https://github.com/ProjectDent/ARKit-CoreLocation
            6:[
                [vc: SceneLocationViewDemoViewController(),
                 navTitle: "SceneLocationView(ARKit+CoreLocation) 根据location放置node"],
                
                [vc: ARLocationViewController(),
                 navTitle: "提取 ARKit+Location 中的 ARSCNView, 无法放置在指定location,(没有提取sceneLocationEstimates)"],
                
                [vc: ARLocationGestureViewController(),
                 navTitle: "(ARKit+CoreLocation)+gesture"],
            ],
        ]
        return dict
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "AR Demo"
        
        tabView = UITableView(frame: self.view.bounds, style: UITableViewStyle.grouped)
        tabView.delegate = self
        tabView.dataSource = self
        
        tabView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifices)
        tabView.tableFooterView = UIView()
        
        tabView.sectionHeaderHeight = UITableViewAutomaticDimension
        tabView.estimatedSectionHeaderHeight = 44.0
        
        tabView.sectionFooterHeight = 0.0
        tabView.estimatedSectionFooterHeight = 0.0
        
        tabView.rowHeight = UITableViewAutomaticDimension
        tabView.estimatedRowHeight = 44.0
        
        self.view.addSubview(tabView)
     
        if #available(iOS 11.0, *){
            
            // navigation bar 在整个APP中显示大标题
            self.navigationController?.navigationBar.prefersLargeTitles = true
            // 控制不同页面大标题的显示
            //self.navigationItem.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.always
            
            tabView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }else{
            self.automaticallyAdjustsScrollViewInsets = false
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension TabViewController: UITableViewDataSource{
    // MARK: table data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let arr: [Any] = datas[section] else{ return 0}
        return arr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifices, for: indexPath)
        cell.selectionStyle = .gray
        cell.accessoryType = .disclosureIndicator
        
        let arr: [Any] = datas[indexPath.section]!
        let data = arr[indexPath.row] as! [String: Any]
        cell.textLabel?.text = data[navTitle] as? String
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let group = groups[section]
        return group
    }
}

extension TabViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let arr: [Any] = datas[indexPath.section]!
        let data = arr[indexPath.row] as! [String: Any]
        if let v = data[vc] as? UIViewController{
            self.navigationController?.pushViewController(v, animated: true)
        }
    }
}
