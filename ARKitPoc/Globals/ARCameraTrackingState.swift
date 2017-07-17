//
//  ARCameraTrackingState.swift
//  ARKitPoc
//
//  Created by AppFoundry on 13/06/2017.
//  Copyright © 2017 AppFoundry. All rights reserved.
//

import Foundation
import ARKit



extension ARCamera.TrackingState {
    var state: String {
        switch self {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "Tracking is limited due to an excessive motion of the camera.."
            case .insufficientFeatures:
                return "Tracking is limited due to a lack of features visible to the camera.. "
            }
        case .normal:
            return "Tracking is normal.."
        case .notAvailable:
            return "Track is not available.."
        }
    }
}


