//
//  MLDemoViewController.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/18.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit

// ML是Machine Learning的缩写，也就是‘机器学习’，这正是现在很火的一个技术，它也是人工智能最核心的内容。
import CoreML

// 这个库是一个高性能的图片分析库，他能识别在图片和视频中的人脸、特征、场景分类等
import Vision

import SceneKit

import ARKit

class MLDemoViewController: UIViewController {
    
    // SCENE
    private var sceneView: ARSCNView!
    private let bubbleDepth: Float = 0.01 // the 'depth' of 3D text
    private var latestPrediction: String = "......" // a variable containing the latest CoreML prediction
    
    // COREML
    private var visionRequests = [VNRequest]()
    private let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    private var debugTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "Core ML + ARSCNView 图像识别"
        self.view.backgroundColor = UIColor.white
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(sender:)))
        
        // ar scn view
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.isUserInteractionEnabled = true
        sceneView.addGestureRecognizer(tap)
        
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        debugTextView = UITextView(frame: self.view.bounds)
        debugTextView.frame.size.height = 200
        debugTextView.isEditable = false
        debugTextView.alpha = 0.5
        self.view.addSubview(debugTextView)
        
        /*
         去苹果官方下载一个已经训练好的模型 下载地址 https://developer.apple.com/machine-learning/
         下载完会得到一个 *.mlmodel 文件, 拖入工程
         */
        //let mlmodel = MobileNet()
        let mlmodel = Inceptionv3()
        let coremlmodel = try! VNCoreMLModel(for: mlmodel.model)
        let coremlrequest = VNCoreMLRequest(model: coremlmodel, completionHandler: classificationCompleteHandler)
        coremlrequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
        
        visionRequests = [coremlrequest]
        
        loopCoreMLUpdate()
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
    // MARK: gesture
    @objc func tapGesture(sender: UIGestureRecognizer){
        let point: CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        let arHitTestResults: [ARHitTestResult] = sceneView.hitTest(point, types: ARHitTestResult.ResultType.featurePoint)
        if let hit = arHitTestResults.first{
            let transform: matrix_float4x4 = hit.worldTransform
            let wordCoord: SCNVector3 = SCNVector3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
            
            let node: SCNNode = createNewBubbleParentNode(latestPrediction)
            sceneView.scene.rootNode.addChildNode(node)
            node.position = wordCoord
        }
    }
    
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    // MARK: - CoreML Vision Handling
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
        
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...1] // top 2 results
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        
        DispatchQueue.main.async {
            // Print Classifications
            print(classifications)
            
            // Display Debug Text on screen
            let debugText:String = classifications
            self.debugTextView.text = debugText
            
            // Store the latest prediction
            var objectName:String = "......"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            self.latestPrediction = objectName
            
        }
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
        
        ///////////////////////////
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
        
        ///////////////////////////
        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
}
extension MLDemoViewController: ARSCNViewDelegate{
    // MARK: SCN Scene Renderer Delegate 代理
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // update at time
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

