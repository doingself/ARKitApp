//
//  LeftViewController.swift
//  DrawerDemo
//
//  Created by 623971951 on 2018/2/7.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit

class LeftViewController: UIViewController {

    private var tabView: UITableView!
    private lazy var datas: [ScnModel] = {
        let arr: [ScnModel] = [
            ScnModel(img: "cup.jpg", scn: "art.scnassets/cup/cup.scn"),
            ScnModel(img: "table_1.jpg", scn: "art.scnassets/other/table.obj"),
            ScnModel(img: "Lotus_HW1.jpg", scn: "art.scnassets/Lotus_Hot_Wheels_OBJ/Lotus_HW_OBJ.obj"),
            ScnModel(img: "TV.jpg", scn: "art.scnassets/Samsung_LED_TV/Samsung_LED_TV.obj"),
            ScnModel(img: "Sofacollection01.jpg", scn: "art.scnassets/Sofa_collection/Sofa_collection.obj"),
            ScnModel(img: "GMPlutonePrev.jpg", scn: "art.scnassets/Sofa_GM_Plutone_OBJ/Sofa_GM_Plutone_OBJ.obj"),
            ScnModel(img: "meridiani.jpg", scn: "art.scnassets/meridiani_obj/meridiani_obj.obj"),
        ]
        return arr
    }()
    
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
extension LeftViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ScnTableViewCell
        cell.setModel(model: datas[indexPath.row])
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
extension LeftViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("\(#function) = \(indexPath.row)")
        let model = datas[indexPath.row]
        RootViewController.shared!.addModelAndCloseLeft(model: model)
    }
}
