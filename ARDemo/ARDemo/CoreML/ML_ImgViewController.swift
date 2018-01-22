//
//  ML_ImgViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/19.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import Vision
import VideoToolbox

class ML_ImgViewController: UIViewController {

    private var imgView: UIImageView!
    private var txtView: UITextView!
    
    private lazy var model = Inceptionv3()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = "Core ML + image"
        self.view.backgroundColor = UIColor.white
        
        imgView = UIImageView(frame: self.view.bounds)
        imgView.frame.size.height = self.view.bounds.size.height/2
        imgView.contentMode = .scaleAspectFit
        imgView.isUserInteractionEnabled = true
        imgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction(sender:))))
        imgView.layer.borderWidth = 1
        self.view.addSubview(imgView)
        
        txtView = UITextView(frame: imgView.bounds)
        txtView.frame.origin.y = imgView.frame.size.height
        txtView.isEditable = false
        txtView.text = "....."
        self.view.addSubview(txtView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func tapAction(sender: Any?){
        //判断是否支持要使用的图片库
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            //初始化图片控制器
            let picker = UIImagePickerController()
            //设置代理
            picker.delegate = self
            //指定图片控制器类型
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            //设置是否允许编辑
            picker.allowsEditing = true
            //弹出控制器，显示界面
            self.present(picker, animated: true, completion: {() -> Void in
                
            })
        }else{
            print("读取相册错误")
        }
    }
    private func refresh(){
        guard let img = self.imgView.image else{ return }
        //predictUsingVision(image: img)
        predictUsingCoreML(image: img)
    }
    private func predictUsingCoreML(image: UIImage) {
        guard let pixelBuffer = image.pixelBuffer(width: 224, height: 224) else{
            return
        }
        let input = Inceptionv3Input(image: pixelBuffer)
        let prediction = try? model.prediction(input: input)
        let top5 = top(5, prediction!.classLabelProbs)
        show(results: top5)
        
        // This is just to test that the CVPixelBuffer conversion works OK.
        // It should have resized the image to a square 224x224 pixels.
        var imoog: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, nil, &imoog)
        self.imgView.image = UIImage(cgImage: imoog!)
        
    }
    private func predictUsingVision(image: UIImage) {
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            fatalError("Someone did a baddie")
        }
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                
                // The observations appear to be sorted by confidence already, so we
                // take the top 5 and map them to an array of (String, Double) tuples.
                let top5 = observations.prefix(through: 4)
                    .map { ($0.identifier, Double($0.confidence)) }
                self.show(results: top5)
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        try? handler.perform([request])
    }
    typealias Prediction = (String, Double)
    func show(results: [Prediction]) {
        var s: [String] = []
        for (i, pred) in results.enumerated() {
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
        }
        txtView.text = s.joined(separator: "\n\n")
    }
    
    func top(_ k: Int, _ prob: [String: Double]) -> [Prediction] {
        precondition(k <= prob.count)
        return Array(prob.map { x in (x.key, x.value) }
            .sorted(by: { a, b -> Bool in a.1 > b.1 })
            .prefix(through: k - 1))
    }
}
extension ML_ImgViewController: UINavigationControllerDelegate{
    // MARK: 选择照片代理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        print("didFinishPickingMediaWithInfo \(info)")
        
        if picker.sourceType == UIImagePickerControllerSourceType.camera{
            // 拍照
        }else{
            // 选择
            //获取选择的原图
            let originImg = info[UIImagePickerControllerOriginalImage] as? UIImage
            self.imgView.image = originImg
            self.refresh()
        }
        //图片控制器退出
        picker.dismiss(animated: true, completion: {() -> Void in
        })
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("取消")
        picker.dismiss(animated: true, completion: nil)
    }
}
extension ML_ImgViewController: UIImagePickerControllerDelegate{
    
}
