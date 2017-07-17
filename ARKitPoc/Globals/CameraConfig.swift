//
//  CameraConfig.swift
//  ARKitPoc
//
//  Created by AppFoundry on 19/06/2017.
//  Copyright © 2017 AppFoundry. All rights reserved.
//

import Foundation
import ARKit

class CameraConfig {
    
    struct CameraCoordinates {
        var x = Float()
        var y = Float()
        var z = Float()
    }
    
    func configureDisplay(sceneView: ARSCNView) {
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
    }
    
    // to position the object in the camera's coordinate
    func getCameraCoordinates(sceneView: ARSCNView) -> CameraCoordinates {
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        sceneView.scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3Make(0, 0, 0)
        
        var coordinates = CameraCoordinates()
        coordinates.x = cameraNode.position.x
        coordinates.y = cameraNode.position.y
        coordinates.z = cameraNode.position.z
        
        return coordinates
    }
}
