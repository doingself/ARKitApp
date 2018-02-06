//
//  MatrixHelper.swift
//  ARDemo
//
//  Created by 623971951 on 2018/1/18.
//  Copyright © 2018年 syc. All rights reserved.
//

import UIKit
import SceneKit
import CoreLocation

extension Double {
    
    func metersToLatitude() -> Double {
        return self / (6373000.0)
    }
    
    func metersToLongitude() -> Double {
        return self / (5602900.0)
    }
    /// 弧度
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    /// 度
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

class MatrixHelper {
    
    //     column 0  column 1  column 2  column 3
    //         1        0         0       X          x         x + X*w  
    //         0        1         0       Y      x   y    =    y + Y*w  
    //         0        0         1       Z          z         z + Z*w  
    //         0        0         0       1          w            w    
    
    static func translationMatrix(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    //      column 0  column 1  column 2  column 3
    //        cosθ      0       sinθ        0    
    //         0        1        0          0     
    //       −sinθ      0       cosθ        0     
    //         0        0        0          1    
    
    static func rotateAroundY(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        var matrix : matrix_float4x4 = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    static func transformMatrix(for matrix: simd_float4x4, originLocation: CLLocation, location: CLLocation) -> simd_float4x4 {
        
        let distance = Float(location.distance(from: originLocation))
        let bearing = originLocation.bearingToLocationRadian(location)
        
        print("originLocation \t= \(originLocation)")
        LocationService.printLocationInfo(location: originLocation)
        print("currentLocation \t= \(location)")
        LocationService.printLocationInfo(location: location)
        print("distance = \(distance)")
        print("bearing = \(bearing)")
        print("bearing = \(bearing.toDegrees())")
        
        
        let position = vector_float4(0.0, 0.0, -distance, 0.0)
        let translationMatrix = MatrixHelper.translationMatrix(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = MatrixHelper.rotateAroundY(with: matrix_identity_float4x4, for: Float(bearing))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
}
