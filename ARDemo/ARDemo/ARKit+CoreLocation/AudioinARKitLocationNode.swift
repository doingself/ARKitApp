//
//  AudioinARKitLocationNode.swift
//  ARDemo
//
//  Created by 623971951 on 2018/2/5.
//  Copyright © 2018年 syc. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import SceneKit

/// PreviewNode + LocationNode
class AudioinARKitLocationNode: LocationNode {
    
    // Saved positions that help smooth the movement of the preview
    var lastPositionOnPlane: float3?
    var lastPosition: float3?
    
    // Use average of recent positions to avoid jitter.
    private var recentPreviewNodePositions: [float3] = []
    
    // MARK: - Initialization
    init(location: CLLocation?, node: SCNNode) {
        
        super.init(location: location)
        
        addChildNode(node)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Appearence
    func update(for position: float3, planeAnchor: ARPlaneAnchor?, camera: ARCamera?) {
        lastPosition = position
        if planeAnchor != nil {
            lastPositionOnPlane = position
        }
        updateTransform(for: position, camera: camera)
    }
    
    // MARK: - Private
    private func updateTransform(for position: float3, camera: ARCamera?) {
        // Add to the list of recent positions.
        recentPreviewNodePositions.append(position)
        
        // Remove anything older than the last 8 positions.
        recentPreviewNodePositions.keepLast(8)
        
        // Move to average of recent positions to avoid jitter.
        if let average = recentPreviewNodePositions.average {
            simdPosition = average
        }
    }
}
