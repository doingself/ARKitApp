//
//  RootViewController.swift
//  DrawerDemo
//
//  Created by 623971951 on 2018/2/7.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit

protocol RootViewControllerDelegate {
    func refreshModel()
    func selectModelByPop(index: Int)
}
class RootViewController: UIViewController {

    var delegate: RootViewControllerDelegate?
    static let shared: RootViewController? = UIApplication.shared.keyWindow?.rootViewController as? RootViewController
    let maxWidth: CGFloat = UIScreen.main.bounds.size.width / 4 * 3
    lazy var selectModel: [ScnModel] = [ScnModel]()
    
    private lazy var coverView: UIView = {
        let v = UIView(frame: self.view.bounds)
        v.backgroundColor = UIColor.clear
        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.coverTap(sender:))))
        v.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.coverPan(sender:))))
        return v
    }()
    
    private var mainViewController: UIViewController!
    private var leftViewController: UIViewController!
    
    init(main: UIViewController, left: UIViewController) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.mainViewController = main
        self.leftViewController = left
        
        // 注意顺序
        self.view.addSubview(self.leftViewController.view)
        self.view.addSubview(self.mainViewController.view)
        
        self.addChildViewController(self.leftViewController)
        self.addChildViewController(self.mainViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.leftViewController.view.transform = CGAffineTransform(translationX: -self.maxWidth, y: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func coverTap(sender: Any?){
        closeLeft()
    }
    @objc func coverPan(sender: Any?){
        guard let pan = sender as? UIPanGestureRecognizer else { return }
        
        let offsetX = pan.translation(in: pan.view).x
        
        if offsetX > 0 {return}
        
        if pan.state == UIGestureRecognizerState.changed && offsetX >= -maxWidth {
            
            let distace = maxWidth + offsetX
            
            mainViewController.view.transform = CGAffineTransform(translationX: distace, y: 0)
            leftViewController.view.transform = CGAffineTransform(translationX: offsetX, y: 0)
            
        } else if pan.state == UIGestureRecognizerState.ended || pan.state == UIGestureRecognizerState.cancelled || pan.state == UIGestureRecognizerState.failed {
            
            if offsetX > -UIScreen.main.bounds.size.width * 0.5 {
                
                openLeft()
                
            } else {
                
                closeLeft()
            }
            
        }
    }
    func openLeft(){
        self.mainViewController.view.addSubview(self.coverView)
        
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
            self.coverView.backgroundColor = UIColor(white: 0.7, alpha: 0.5)
            self.leftViewController.view.transform = CGAffineTransform.identity
            self.mainViewController.view.transform = CGAffineTransform(translationX: self.maxWidth, y: 0)
        }) { (finished: Bool) in
            
        }
    }
    func closeLeft(){
        
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: {
            self.leftViewController.view.transform = CGAffineTransform(translationX: -self.maxWidth, y: 0)
            self.mainViewController.view.transform = CGAffineTransform.identity
            self.coverView.backgroundColor = UIColor.clear
        }) { (finished: Bool) in
            self.coverView.removeFromSuperview()
        }
    }
    func addModelAndCloseLeft(model: ScnModel){
        var has = false
        for m in selectModel {
            if m.scnName == model.scnName{
                has = true
                break
            }
        }
        if has == false{
            // 避免重复添加同一个模型
            self.selectModel.append(model)
            self.closeLeft()
            delegate?.refreshModel()
        }
    }
    func selectModelByPop(index: Int){
        delegate?.selectModelByPop(index: index)
    }
}
