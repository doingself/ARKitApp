/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This file includes some extensions to various classes. These are used primarily for sampling the average color from the image so that the chameleon's camouflage can be adjusted to appear more realistic.
 */

import Foundation
import SceneKit
import ARKit
import CoreLocation

// MARK: arkit spitfire
extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> Double {
        
        let lat1 = self.coordinate.latitude.toRadians()
        let lon1 = self.coordinate.longitude.toRadians()
        
        let lat2 = destinationLocation.coordinate.latitude.toRadians()
        let lon2 = destinationLocation.coordinate.longitude.toRadians()
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        return radiansBearing
    }
}
extension SCNVector3 {
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}
extension Double {
    
    func metersToLatitude() -> Double {
        return self / (6373000.0)
    }
    
    func metersToLongitude() -> Double {
        return self / (5602900.0)
    }
    
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

// MARK: apple cup

extension ARSCNView {
	func averageColorFromEnvironment(at screenPos: SCNVector3) -> SCNVector3 {
		var colorVector = SCNVector3()
		
		// Take screenshot of the scene, without the content
		scene.rootNode.isHidden = true
		let screenshot: UIImage = snapshot()
		scene.rootNode.isHidden = false
		// Use a patch from the specified screen position
		let scale = UIScreen.main.scale
		let patchSize: CGFloat = 100 * scale
		let screenPoint = CGPoint(x: (CGFloat(screenPos.x) - patchSize / 2) * scale,
		                          y: (CGFloat(screenPos.y) - patchSize / 2) * scale)
		let cropRect = CGRect(origin: screenPoint, size: CGSize(width: patchSize, height: patchSize))
		if let croppedCGImage = screenshot.cgImage?.cropping(to: cropRect) {
			let image = UIImage(cgImage: croppedCGImage)
			if let avgColor = image.averageColor() {
				colorVector = SCNVector3(avgColor.red, avgColor.green, avgColor.blue)
			}
		}
		return colorVector
	}
}

extension SCNAnimation {
	static func fromFile(named name: String, inDirectory: String ) -> SCNAnimation? {
		let animScene = SCNScene(named: name, inDirectory: inDirectory)
		var animation: SCNAnimation?
		animScene?.rootNode.enumerateChildNodes({ (child, stop) in
			if !child.animationKeys.isEmpty {
				let player = child.animationPlayer(forKey: child.animationKeys[0])
				animation = player?.animation
				stop.initialize(to: true)
			}
		})
		
		animation?.keyPath = name
		
		return animation
	}
}

extension UIImage {
	func averageColor() -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
		if let cgImage = self.cgImage, let averageFilter = CIFilter(name: "CIAreaAverage") {
			let ciImage = CIImage(cgImage: cgImage)
			let extent = ciImage.extent
			let ciExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
			averageFilter.setValue(ciImage, forKey: kCIInputImageKey)
			averageFilter.setValue(ciExtent, forKey: kCIInputExtentKey)
			if let outputImage = averageFilter.outputImage {
				let context = CIContext(options: nil)
				var bitmap = [UInt8](repeating: 0, count: 4)
				context.render(outputImage,
				               toBitmap: &bitmap,
				               rowBytes: 4,
				               bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
				               format: kCIFormatRGBA8,
				               colorSpace: CGColorSpaceCreateDeviceRGB())
				
				return (red: CGFloat(bitmap[0]) / 255.0,
				        green: CGFloat(bitmap[1]) / 255.0,
				        blue: CGFloat(bitmap[2]) / 255.0)
			}
		}
		return nil
	}
}

// MARK: - Collection extensions

extension Array where Iterator.Element == float3 {
    var average: float3? {
        guard !self.isEmpty else {
            return nil
        }
        
        let sum = self.reduce(float3(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

// MARK: - float4x4 extensions

extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
