//
//  ViewController.swift
//  ARBasketBall
//
//  Created by Shawn Hung on 2018/5/24.
//  Copyright © 2018 Shawn Hung. All rights reserved.
//

import UIKit
import ARKit

enum CollisionMask: Int {
    case ball = 1
    case board = 2
    case net = 4
    case ring = 8
}

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var focusSquare = FocusSquare()
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)

    let virtualObjects = VirtualObject.availableObjects
    
    var hasPlacedObject = false

    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "idv.shawn.ARBasketBall.serialSceneKitQueue")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Private methods
    
    private func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    /// Creates a new AR configuration to run on the `session`.
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func updateFocusSquare() {
        
        // Perform hit testing only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let result = self.sceneView.smartHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
            }
            
            let ball = virtualObjects[0]
            if !self.hasPlacedObject && !virtualObjectLoader.isLoading {
                virtualObjectLoader.loadVirtualObject(ball, loadedHandler: { [unowned self] loadedObject in
                    
                    DispatchQueue.main.async {
                        if self.placeVirtualObject(loadedObject) {
                            self.hasPlacedObject = true
                        }
                    }
                })
            }
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
        }
    }
    
    private func placeVirtualObject(_ virtualObject: VirtualObject) -> Bool {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquareAlignment = focusSquare.recentFocusSquareAlignments.last,
            focusSquare.state != .initializing else {
                NSLog("CANNOT PLACE OBJECT\nTry moving left or right.")
                return false
        }
        
        // The focus square transform may contain a scale component, so reset scale to 1
        let focusSquareScaleInverse = 1.0 / focusSquare.simdScale.x
        let scaleMatrix = float4x4(uniformScale: focusSquareScaleInverse)
        let focusSquareTransformWithoutScale = focusSquare.simdWorldTransform * scaleMatrix
        
        virtualObjectInteraction.selectedObject = virtualObject
        virtualObject.setTransform(focusSquareTransformWithoutScale,
                                   relativeTo: cameraTransform,
                                   smoothMovement: false,
                                   alignment: focusSquareAlignment,
                                   allowAnimation: false)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
            self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
        
        return true
    }
}

extension ViewController:ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        updateQueue.async {
            for object in self.virtualObjectLoader.loadedObjects {
                object.adjustOntoPlaneAnchor(planeAnchor, using: node)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        updateQueue.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                for object in self.virtualObjectLoader.loadedObjects {
                    object.adjustOntoPlaneAnchor(planeAnchor, using: node)
                }
            } else {
                if let objectAtAnchor = self.virtualObjectLoader.loadedObjects.first(where: { $0.anchor == anchor }) {
                    objectAtAnchor.simdPosition = anchor.transform.translation
                    objectAtAnchor.anchor = anchor
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.virtualObjectInteraction.updateObjectToCurrentTrackingPosition()
            self.updateFocusSquare()
        }
        
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = sceneView.scene.lightingEnvironment
        if let lightEstimate = session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
    }
}

extension ViewController:ARSessionDelegate {
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        NSLog("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        NSLog("Session interruption ended")
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        NSLog("Session failed: \(error.localizedDescription)")
        resetTracking()
    }
}

