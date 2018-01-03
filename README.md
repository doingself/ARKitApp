# ARDemo

+ 点击屏幕添加飞机 (touchesBegan)
+ 检测平面, 添加飞机 (ARSCNViewDelegate)
+ 飞机跟随相机移动 (ARSessionDelegate)
+ 飞机绕相机旋转, 类似地球公转 (CABasicAnimation)


VR(虚拟现实) 是做梦, AR(增强现实) 是见鬼; VR是说谎, AR是吹牛.

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


+ ARWorldTrackingSessionConfiguration 提供 6DOF 追踪 (平移 * 3 + 旋转 * 3)。
 自由度(DOF,Degree Of Freedom)表示描述系统状态的独立参数的个数。
+ ARFrame 中包含有世界追踪过程获取的所有信息
	+ camera: 含有摄像机的位置、旋转以及拍照参数等信息
	+ ahchors: 代表了追踪的点或面
 		+ transform 是一个 4x4 的矩阵，矩阵中包含了 anchor 偏移、旋转和缩放信息等位置信息。(一个平面的坐标信息为 ARPlaneAnchor.transform.columns.3.x/y/z)
+ ARCamera 
	+ transform: 表示摄像头相对于起始时的位置和旋转信息
+ ARSCNView 帮我们做了如下几件事情：
	+ 将摄像机捕捉到的真实世界的视频作为背景。
	+ 处理光照估计信息，不断更新画面的光照强度。
	+ 将 SCNNode 与 ARAnchor 绑定，也就是说当添加一个 SCNNode 时，ARSCNView 会同时添加一个 ARAnchor 到 ARKit 中。
	+ 不断更新 SceneKit 中的相机位置和角度。
	+ 将 SceneKit 中的坐标系结合到 AR world 的坐标系中，不断渲染 SceneKit 场景到真实世界的画面中。




#### 参考

+ https://github.com/GeekLiB/AR-Source
+ [坤小 ARKit 系列](http://blog.csdn.net/u013263917/article/details/72903174)
+ https://www.jianshu.com/p/7faa4a3af589
+ https://www.jianshu.com/p/16b11e50396c
