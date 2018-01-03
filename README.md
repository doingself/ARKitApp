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

### Hit Test Result

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


#### 参考

+ https://github.com/GeekLiB/AR-Source
+ [坤小 ARKit 系列](http://blog.csdn.net/u013263917/article/details/72903174)
+ https://www.jianshu.com/p/7faa4a3af589
+ https://www.jianshu.com/p/16b11e50396c
+ 关于模型设置 https://www.jianshu.com/p/6a761a834ab9
