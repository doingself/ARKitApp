//
//  TabViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/27.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit

class TabViewController: UIViewController {
    
    private var tabView: UITableView!
    private let cellIdentifices = "cell"
    private lazy var datas: [String] = {
        let arr = [
            "点击屏幕添加飞机 touchesBegan",
            "检测平面,添加飞机 tap拍照, long录制",
            "物体跟随相机移动",
            "类似地球公转",
            
            "检测平面,添加飞机 点击屏幕添加3D 模型  gesture",
            "手势 tap/pan 拖拽模型 HitTestResult",
            "手势 pan拖拽/pinch缩放 SCNBox ARCamera",
            
            "手势 tap/pan/pinch",
            "摆放家具",
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
        case 0:
            v = OneARViewController()
        case 1:
            v = TwoARViewController()
        case 2:
            v = ThreeARViewController()
        case 3:
            v = FourARViewController()
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
        default:
            break
        }
        if v != nil{
            self.navigationController?.pushViewController(v!, animated: true)
        }
        
    }
}
