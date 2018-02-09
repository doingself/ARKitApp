//
//  ScnTableViewCell.swift
//  ArKitDemo
//
//  Created by 623971951 on 2018/2/8.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit

class ScnTableViewCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var heightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthLayoutConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.imgView.contentMode = .scaleAspectFit
        
        widthLayoutConstraint.constant = RootViewController.shared!.maxWidth - 10
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setModel(model: ScnModel){
        let img = model.img
        if widthLayoutConstraint.constant < img.size.width{
            let height:CGFloat = widthLayoutConstraint.constant/(img.size.height)*img.size.width
            heightLayoutConstraint.constant = max(height,50)
        }else{
            heightLayoutConstraint.constant = img.size.height
        }
        self.imgView.image = img
    }
    func setModelByPop(model: ScnModel, size: CGSize){
        let img = model.img
        widthLayoutConstraint.constant = size.width-10
        if widthLayoutConstraint.constant < img.size.width{
            let height:CGFloat = widthLayoutConstraint.constant/(img.size.height)*img.size.width
            heightLayoutConstraint.constant = max(height,50)
        }else{
            heightLayoutConstraint.constant = img.size.height
        }
        self.imgView.image = img
    }
}
