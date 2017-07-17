//
//  ViewController.swift
//  ARKitPoc
//
//  Created by AppFoundry on 08/06/2017.
//  Copyright © 2017 AppFoundry. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Foundation



class ViewController: UIViewController, ARSCNViewDelegate {
    
    
    @IBOutlet var sceneView: ARSCNView!
    
    let session = ARSession()
    
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var add: UIButton! {
        didSet {
            add.setBackgroundImage(UIImage(named: "add"), for: .normal)
        }
    }
    
    let cameraConfig = CameraConfig()
    var virtualObject = VirtualObject()
    var ambientLightNode: SCNNode!
    var isAnimating = false
    let sessionConfiguration = ARWorldTrackingSessionConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Create a new scene
        setupScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSessionConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupScene() {
        
        //set the view's delegate to tell our sceneView that this class is its delegate
        sceneView.delegate = self
        
        //set the session
        sceneView.session = session
        
        //Enables multisample antialiasing with four samples per screen pixel.
        //Renders each pixel multiple times and combines the results
        sceneView.antialiasingMode = .multisampling4X
        
        // disable lights updating.
        sceneView.automaticallyUpdatesLighting = false
        
        // disable the default lightling in order to update the lights depending on the object's position
        sceneView.autoenablesDefaultLighting = false
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        
        cameraConfig.configureDisplay(sceneView: sceneView)
    }
    
    
    func setSessionConfiguration() {
        
        // check if the device support the ar world
        if ARWorldTrackingSessionConfiguration.isSupported {
            
            // Run the view's session
            sceneView.session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
            sessionConfiguration.isLightEstimationEnabled = true
            
        } else {
            
            // if the world tracking is not supported
            let sessionConfiguration = ARSessionConfiguration()
            sceneView.session.run(sessionConfiguration, options: [.resetTracking, .removeExistingAnchors])
            sessionConfiguration.isLightEstimationEnabled = true
        }
    }
    
    @IBAction func loadObject(_ sender: Any) {
        if !virtualObject.isPlaced {
            addObject()
        }
    }
    
    
    func addObject() {
        
        virtualObject = VirtualObject(name: "starwarsTieFighter.dae")
        virtualObject.loadModel()
        
        let cameraCoord = CameraConfig()
        let coord = cameraCoord.getCameraCoordinates(sceneView: sceneView)
        
        virtualObject.position = SCNVector3(coord.x, coord.y, coord.z)
        sceneView.scene.rootNode.addChildNode(virtualObject)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // to detect planes
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the node using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        //node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        // remove existing plane nodes
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate
        
        // If light estimation is enabled, update the intensity of the model's lights
        if lightEstimate != nil &&  sessionConfiguration.isLightEstimationEnabled {
            let intensity = (lightEstimate?.ambientIntensity)! / 40
            self.sceneView.scene.lightingEnvironment.intensity = intensity
        } else {
            self.sceneView.scene.lightingEnvironment.intensity = 25
        }
    }
    
    
    // session config
    func session(_ session: ARSession, didFailWithError error: Error) {
        showSessionStateMessage(message: "Session failed with error \(error)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        showSessionStateMessage(message: "Session was interrupted")
        virtualObject.unLoadModel(child: virtualObject)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        message.text = camera.trackingState.state
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            self.message.isHidden = true
        }
    }
    
    // touch gesture config
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if touches.count == 1 {
            
            if let touch = touches.first {
                let location = touch.location(in: sceneView)
                let hitList = sceneView.hitTest(location, options: nil)
                
                // use th first result which is the closest intersection to the camera
                if let hitObject = hitList.first {
                    let node = hitObject.node
                    
                    if node.name == "tieFighter" {
                        if !isAnimating {
                            startAnimation(node: node.parent!)
                            isAnimating = true
                        } else {
                            stopAnimation(node: node.parent!)
                            isAnimating = false
                        }
                    }
                }
            }
        } else if touches.count == 2 {
            if let touch = touches.first {
                let location = touch.location(in: sceneView)
                
                let hitList = sceneView.hitTest(location, options: nil)
                
                if let hitObject = hitList.first {
                    let node = hitObject.node
                    
                    if node.name == "tieFighter" {
                        virtualObject.unLoadModel(child: node.parent!)
                    }
                }
            }
        } else if touches.count == 3 {
            if let touch = touches.first {
                placeNewObject(touch: touch)
            }
        }
    }
    
    
    func startAnimation(node: SCNNode) {
        let rotate = SCNAction.rotateBy(x: 0, y: 3, z: 0, duration: 1)
        rotate.timingMode = .easeIn
        
        let rotationSequence = SCNAction.sequence([rotate])
        let rotationLoop = SCNAction.repeatForever(rotationSequence)
        node.runAction(rotationLoop)
        
        moveOn(node: node)
    }
    
    func moveOn(node: SCNNode) {
        
        let moveTo = SCNAction.move(to: SCNVector3Make(0.5, 0.0, 0.0), duration: 3)
        moveTo.timingMode = .easeIn
        
        let moveBack = SCNAction.move(to: SCNVector3Make(0.0, 0.0, 0.5), duration: 3)
        moveBack.timingMode = .easeOut
        
        let moveSequence = SCNAction.sequence([moveTo, moveBack])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        node.runAction(moveLoop)
    }
    
    func stopAnimation(node: SCNNode) {
        node.removeAllActions()
    }
    
    
    func placeNewObject(touch: UITouch) {
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint] )
        if let anchor = results.first {
            let hitPointTransform = SCNMatrix4FromMat4(anchor.worldTransform)
            let hitPointPosition = SCNVector3Make(hitPointTransform.m41, hitPointTransform.m42, hitPointTransform.m43)
            let node = virtualObject.clone()
            node.position = hitPointPosition
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func showSessionStateMessage(message sessionState: String) {
        let alert = UIAlertController(title: "Session State", message: sessionState, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}


