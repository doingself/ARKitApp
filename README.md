# ARDemo

VR(虚拟现实) 是做梦, AR(增强现实) 是见鬼; VR是说谎, AR是吹牛.

touch begin

+ 点击屏幕touchesBegan 添加飞机 SCNScene.node self.arSCNView.scene.rootNode.addChildNode(node)
+ 检测平面ARPlaneAnchor添加SCNPlane, 1s后添加飞机SCNScene.node tap截图arSCNView.snapshot(), long录制RPScreenRecorder
+ 检测平面ARPlaneAnchor添加SCNBox, 点击屏幕touchesBegan 添加飞机 SCNScene.node + 跟随相机移动 ARSessionDelegate.didUpdate position=frame.camera.transform.columns.3
+ 点击屏幕touchesBegan 添加飞机 SCNScene.node, 添加旋转动画CABasicAnimation 类似地球公转

gesture

+ 检测平面ARPlaneAnchor添加SCNBox, 1s后添加飞机SCNScene.node 点击屏幕 tap 获取 ARHitTestResult 使用 hitResult.worldTransform.columns.3 添加 SCNNode(geometry: SCNBox()).position
+ 检测平面ARPlaneAnchor设置模型simdTransform=anchor.transform, tap/pan 设置 模型simdTransform = ARHitTestResult.worldTransform
+ pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform
+ tap/pan/pinch, tap 设置 模型 position = ARHitTestResult.worldTransform.cloumn.3,  pan 根据arSCNView.session.currentFrame!.camera.transform.columns.3 对 node 进行拖拽position 旋转eulerAngles, pinch 缩放CGAffineTransform
+ 基于上一个 item 摆放家具 pan选中模型进行拖拽, 否则旋转

![image](https://github.com/doingself/ARDemo/blob/master/images/image0.jpg)

apple demo

1. AudioinARKit is 茶杯 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd
2. InteractiveContentwithARKit is 变色龙 点击变色+拖拽

+ 基于AudioinARKit 始终在平面中央 SCNSceneRenderer updateAtTime, 检测到地面后固定 SCNSceneRenderer didAdd, 添加 pan/pinch pan拖拽时改变模型样式material.diffuse.contents
+ 基于上一个 item, 添加截图sceneView.snapshot(), 复位previewNode!.eulerAngles
+ 基于上一个 item, 添加摄像ReplayKit.RPScreenRecorder

ARKitSpitfire 使用 CLLocation 移动模型

+ 根据 location 移动模型

CoreML

+ Core ML + ARSCNView 图像识别
+ Core ML + ImagePicker 图像识别

[Findme](https://github.com/mmoaay/Findme)
+ 保存设备的运动轨迹 运动过程中 添加 node 到 ARSCNView.scene.rootNode.childeNodes 中, 将当前 ARSCNView.scene 保存到起来( SCNScene )
+ 查看设备的运动轨迹 使用 ARSCNView.scene 加载已经保存的 SCNScene

![image](https://github.com/doingself/ARDemo/blob/master/images/image1.jpg)

### ARKit

ARKit虽然是iOS11新出的框架，但并不是所有的iOS11系统都可以使用，而是必须要是处理器A9及以上才能够使用，苹果从iPhone6s开始使用A9处理器，也就是iPhone6及以前的机型无法使用ARKit

+ A9+
	+ iphone6s 及以后的 iPhone 
	+ iphone SE
	+ ipad pro(A9X)
	+ ipad(2017)

+ IOS11+

### 第三方, 注册账号,集成 SDK, 收费

+ Vuforia 最流行的AR应用开发引擎。
+ EasyAR EasyAR是国内最专业的AR引擎,是国内首款投入应用的AR SDK。
+ HiAR 增强现实开发平台 HiAR 是亮风台信息科技打造的新一代移动增强现实(AR)开发平台
+ 太虚AR 成都米有网络科技有限公司自主研发集成于Unity3d实现增强现实的SDK开发包,虚拟现实SDK太虚官方网站。
+ 天眼 AR包括天眼云平台和天眼AR浏览器,用户需在天眼云平台完成“AR内容”制作,然后在天眼AR浏览器查看效果。

## ARKit

ARKit 本身并不提供创建虚拟世界的引擎，而是使用其他 3D/2D 引擎进行创建虚拟世界。iOS 系统上可使用的引擎主要有：

+ Apple 3D Framework - SceneKit.
+ Apple 2D Framework - SpriteKit.
+ Apple GPU-accelerated 3D graphics Engine - Metal.
+ OpenGl
+ Unity3D
+ Unreal Engine

### SceneKit

右: x > 0 ; 上: y > 0; 前: z < 0.

可以将一个个的节点(SCNNode)添加到场景(SCNScene)中。SCNScene 中有唯一一个根节点(坐标是(x:0, y:0, z:0))，除了根节点外，所有添加到 SCNScene 中的节点都需要一个父节点。

+ 本地坐标系：以场景中的某节点(非根节点)为原点建立的三维坐标系
+ 世界坐标系：以根节点为原点创建的三维坐标系称为世界坐标系。

```
// 创建相机
let scene = SCNScene()
let cameraNode = SCNNode()
let camera = SCNCamera()
cameraNode.camera = camera
cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
scene.rootNode.addChildNode(cameraNode)
// 显示
let scnView = SCNView()
scnView.scene = scene
vc.view.addSubview(scnView)
scnView.frame = vc.view.bounds

```

### ARKit


+ ARSession 一个管理增强现实所需的设备摄像头和动作处理的共享的对象。从设备的动作感应硬件读取数据、控制设备内置摄像头和对捕捉到的摄像图像进行分析。任何一个用ARKit实现的AR场景都需要一个单独的ARSession对象。如果使用了ARSCNView或者ARSKView对象来创建了AR场景的话，一个ARSession实例已经包含在这个View之中了。如果通过别的渲染器来建立AR内容，就需要手动创建并维持一个ARSession对象。
+ ARSessionConfiguration 一个仅用来追踪设备方向的基础设置。所有的AR configuration都是用来建立现实世界和虚拟3D坐标空间的对应关系的。用三自由度（3DOF，也就是三个旋转坐标：roll（绕x轴）、pitch（绕y轴）和yaw（绕z轴））。
+ ARWorldTrackingSessionConfiguration 提供 6DOF 追踪 (平移 * 3 + 旋转 * 3)。
 自由度(DOF,Degree Of Freedom)表示描述系统状态的独立参数的个数。
+ ARAnchor 一个物体在3D空间的位置和方向
 	+ transform 是一个 4x4 的矩阵，矩阵中包含了 anchor 偏移、旋转和缩放信息等位置信息。(一个平面的坐标信息为 ARPlaneAnchor.transform.columns.3.x/y/z)
	+ ARPlaneAnchor 继承自ARAnchor，是在AR session中监测到的现实平面的位置和方向。
+ ARHitTestResult 主要用于虚拟增强现实技术（AR技术）中现实世界与3D场景中虚拟物体的交互。 比如我们在相机中移动。拖拽3D虚拟物体
+ ARFrame AR相机的位置和方向以及追踪相机的时间，还可以捕捉相机的帧图片, ARFrame用于捕捉相机的移动，其他虚拟物体用ARAnchor
+ ARCamera 表示AR session中一个被捕获的视图帧相关的相机位置和视图特征的信息
	+ transform: 表示摄像头相对于起始时的位置和旋转信息
+ ARLightEstimate——与被捕捉的视图帧相关的分析场景的灯光数据。


+ ARSceneView 一个用来展示增强相机视图和3D SceneKit内容的AR体验的页面。
	1. 将摄像机捕捉到的真实世界的视频作为背景。
	2. 处理光照估计信息，不断更新画面的光照强度。
	3. 将 SCNNode 与 ARAnchor 绑定，也就是说当添加一个 SCNNode 时，ARSCNView 会同时添加一个 ARAnchor 到 ARKit 中。
	4. 不断更新 SceneKit 中的相机位置和角度。
	5. 将 SceneKit 中的坐标系结合到 AR world 的坐标系中，不断渲染 SceneKit 场景到真实世界的画面中。

### Hit Test Result

ARHitTestResult 主要用于虚拟增强现实技术（AR技术）中现实世界与3D场景中虚拟物体的交互。 比如我们在相机中移动。拖拽3D虚拟物体

+ ARHitTestResultTypeFeaturePoint 根据距离最近的特征点检测出来的连续表面。
+ ARHitTestResultTypeEstimatedHorizontalPlane 非精准方式计算出来与重力垂直的平面。
+ ARHitTestResultTypeExistingPlane 已经检测出来的平面，检测时忽略平面本身大小，把它看做一个无穷大的平面。
+ ARHitTestResultTypeExistingPlaneUsingExtent 已经检测出来的平面，检测时考虑平面本身的大小。

### 模型

SceneKit可直接加载展示的文件格式有.dae、.scn、和.obj

从 [turbosquid](https://www.turbosquid.com/) 下载 obj 模型, 在 Xcode 编辑(修改图片颜色等), 导出 dae

主要通过调整设置SCNNode这个场景图结构元素的Material类型的几何外表着色属性。需要调整的主要就两个地方，一个是lighting Model，另一个是SCNMaterialProperty类型的属性像diffuse、emission、normal等

+ diffuse 管理物体材料的照明扩散反应。
+ ambient 一个对象，管理环境照明材料的响应。
+ specular 管理物体材料的照明反射响应。
+ normal 一个对象，定义了表面的名义定位在每个点用于照明。
+ reflective 一个对象定义的表面上的每个点的反射色。
+ emission 一个对象定义所发出的每个点上的表面的颜色。
+ transparent 确定材料中的每个点的不透明物体。
+ multiply 一个对象，规定乘以材料中的像素在其他所有的阴影是完整的颜色值。
+ ambientOcclusion 一个对象，将影响材料的环境光颜色值乘以提供。
+ selfIllumination 一个对象，提供颜色值代表表面的全局光照。
+ metalness 一个对象，提供彩色值来确定金属材料的表面看起来如何。
+ roughness 一个对象，确定表面外观平整度提供了颜色值。

lighting Model有五种样式，分别是：
+ SCNLightingModelPhong 明暗结合环境，扩散，和镜面反射特性，在高光使用Phong公式计算。
+ SCNLightingModelBlinn 明暗结合环境，扩散，和镜面反射特性，在高光使用Blinn-Phong公式计算。
+ SCNLightingModelLambert 明暗结合环境属性和扩散。
+ SCNLightingModelConstant 均匀的明暗只结合环境照明。
+ SCNLightingModelPhysicallyBased 基于物理的灯光和材质的现实抽象底纹。


## CoreML

ML是Machine Learning的简写，也就是机器学习的意思。Core ML其实就是将一些已经训练好的神经网络、支持向量机、线性分析等集成到一个框架里，供开发者来调用。苹果开发者网站上已经有几套训练好的模型可供使用，其中包含了脸部识别、图像识别、自然语言识别等。

去 [苹果官方下载](https://developer.apple.com/machine-learning/) 一个已经训练好的模型


```
import CoreML
import Vision
import SceneKit
import ARKit

// *.mlmodel
let model = Inceptionv3()
// core ml model
guard let visionModel = try? VNCoreMLModel(for: model.model) else {
    fatalError("Someone did a baddie")
}
// core ml request
let request = VNCoreMLRequest(model: visionModel) { request, error in
    if let observations = request.results as? [VNClassificationObservation] {
        
        // The observations appear to be sorted by confidence already, so we
        // take the top 5 and map them to an array of (String, Double) tuples.
        let results = observations.prefix(through: 4)
            .map { ($0.identifier, Double($0.confidence)) }

        var s: [String] = []
        for (i, pred) in results.enumerated() {
        	// 1   identifier     confidence*100 %
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
        }
        txtView.text = s.joined(separator: "\n\n")

    }
}
request.imageCropAndScaleOption = .centerCrop

// 识别图片( UIImagePickerController )
// image ---> cgImage
var image: UIImage?
// vn image request handler 
let handler = VNImageRequestHandler(cgImage: image.cgImage!)

// 识别图片( ARSCNView )
// CVPixelBuffer ---> ciImage
// ARSCNView.session.currentFrame.capturedImage
let pixbuff : CVPixelBuffer? = sceneView.session.currentFrame?.capturedImage
let ciImage = CIImage(cvPixelBuffer: pixbuff!)
// vn image request handler
let handler = VNImageRequestHandler(cgImage: image.cgImage!)

try? handler.perform([request])
```


#### 参考

博客

+ AR 开发资料汇总 https://github.com/GeekLiB/AR-Source
+ [坤小 ARKit 系列](http://blog.csdn.net/u013263917/article/details/72903174)
+ ARKit的每个类的作用和总结 https://www.jianshu.com/p/176e355555fe
+ ARKit总结 https://www.jianshu.com/p/7faa4a3af589
+ ARKit总结 https://www.jianshu.com/p/16b11e50396c
+ 关于模型设置(SceneKit) https://www.jianshu.com/p/6a761a834ab9
+ CoreML总结 https://www.jianshu.com/p/1c1d41d002f8
+ CoreML总结 https://www.jianshu.com/p/872b3fc5c0b4
+ 弧度与角度的关系 http://blog.csdn.net/diyagoanyhacker/article/details/6606147
	+ 弧度 ＝ 度 × π / 180
	+ 度 ＝ 弧度 × 180° / π
	+ 180度 ＝ π弧度
	+ 90°＝ 90 × π / 180 ＝ π/2 弧度
	+ 60°＝ 60 × π / 180 ＝ π/3 弧度


GitHub

+ 将模型移动到指定位置(定位) https://github.com/chriswebb09/ARKitSpitfire
+ CoreML https://github.com/hanleyweng/CoreML-in-ARKit
+ CoreML https://github.com/hollance/MobileNet-CoreML
+ Findme https://github.com/mmoaay/Findme


# TODO

+ ~~摆放家具, 旋转算法~~
+ ~~选中模型, 开始拖拽时改变模型样式, 结束拖拽恢复原始样式~~
+ 拖拽模型后恢复模型样式 `node.geometry?.materials` `material.diffuse.contents` 提示 `loading : <C3DImage ...>`
+ ReplayKit 录屏(iPad 无法保存)
+ 保存模型位置, 再次打开时模型在最后放置的位置
