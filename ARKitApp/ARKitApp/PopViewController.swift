//
//  PopViewController.swift
//  DrawerDemo
//
//  Created by 623971951 on 2018/2/7.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit

class PopViewController: UIViewController {
    
    private var tabView: UITableView!
    var datas: [ScnModel]!
    var selectModel: String?
    private var selectModelIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        tabView = UITableView(frame: self.view.bounds)
        tabView.dataSource = self
        tabView.delegate = self
        
        tabView.estimatedRowHeight = 44.0
        tabView.rowHeight = UITableViewAutomaticDimension
        
        //tabView.register(ScnTableViewCell.self, forCellReuseIdentifier: "cell")
        tabView.register(UINib(nibName: "ScnTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        tabView.tableFooterView = UIView()
        
        self.view.addSubview(tabView)
    }
    
//    override var preferredContentSize: CGSize {
//        didSet{
//            self.tabView.frame.size = preferredContentSize
//        }
//    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.tabView.setEditing(true, animated: false)
        self.tabView.frame.size = preferredContentSize
        self.tabView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
extension PopViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ScnTableViewCell
        
        cell.selectionStyle = .gray
        cell.accessoryType = .none
        
        let model = datas[indexPath.row]
        cell.setModelByPop(model: model, size: preferredContentSize)
        if model.scnName == selectModel{
            cell.accessoryType = .checkmark
            
            selectModelIndex = indexPath.row
        }
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: cell edit
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath){
        // 删除
        self.dismiss(animated: true) {
            RootViewController.shared?.deleteModelByPop(index: indexPath.row, selectIndex: self.selectModelIndex)
        }
    }
}
extension PopViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("\(#function) = \(indexPath.row)")
        self.dismiss(animated: true) {
            RootViewController.shared?.selectModelByPop(index: indexPath.row)
        }
    }
    // MARK: cell edit
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "删除"
    }
    
}
