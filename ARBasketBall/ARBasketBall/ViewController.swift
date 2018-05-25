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
    
    var hasPlacedObject = false

    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    var ball: SCNNode!
    var hoop: SCNNode!
    var targetCreationTime:TimeInterval = 0
    var firstPlaneNode: SCNNode?
    
    var score = 0
    
    var isHit = false
    
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
        
        setupBall()
        setupHoop()
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
        
        let tapGesture = UITapGestureRecognizer()
        
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.scene.physicsWorld.contactDelegate = self
        
        tapGesture.addTarget(self, action: #selector(didTap(recognizer:)))
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        title = String(score)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetTracking()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Creates a new AR configuration to run on the `session`.
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func setupBall() {
        let scene = SCNScene(named: "Models.scnassets/basketball/basketball.scn")!
        ball = scene.rootNode.childNode(withName: "Ball", recursively: true)
        ball.simdScale = float3(0.01, 0.01, 0.01)
        ball.simdPosition = float3(0, 0, -0.5)
        ball.physicsBody = .dynamic()
        ball.physicsBody?.categoryBitMask = CollisionMask.ball.rawValue
        ball.physicsBody?.collisionBitMask = CollisionMask.board.rawValue | CollisionMask.ring.rawValue
        ball.physicsBody?.contactTestBitMask = CollisionMask.net.rawValue
    }
    
    private func setupHoop() {
        let scene = SCNScene(named: "Models.scnassets/basketball_hoop/basketball_hoop.scn")!
        hoop = scene.rootNode.childNode(withName: "Hoop", recursively: true)
        hoop.simdScale = float3(0.0005, 0.0005, 0.0005)
        let ring = hoop?.childNode(withName: "Ring", recursively: true)
        let ringShape = SCNPhysicsShape(geometry: (ring?.geometry)!, options: [.type: SCNPhysicsShape.ShapeType.concavePolyhedron, .scale: SCNVector3(x: 0.1, y: 0.1, z: 0.1)])
        
        ring?.physicsBody? = SCNPhysicsBody(type: .kinematic, shape: ringShape)
        ring?.physicsBody?.categoryBitMask = CollisionMask.ring.rawValue
        
        let net = hoop?.childNode(withName: "Net", recursively: true)
        net?.physicsBody? = SCNPhysicsBody.kinematic()
        net?.physicsBody?.categoryBitMask = CollisionMask.net.rawValue
        net?.physicsBody?.collisionBitMask = 0
        net?.physicsBody?.contactTestBitMask = CollisionMask.ball.rawValue
        
        let board = hoop?.childNode(withName: "Board", recursively: true)
        board?.physicsBody? = SCNPhysicsBody.kinematic()
        board?.physicsBody?.categoryBitMask = CollisionMask.board.rawValue
    }
    
    @objc func didTap(recognizer:UITapGestureRecognizer) {
        guard let currentTransform = session.currentFrame?.camera.transform else { return }
        
        var translation = matrix_identity_float4x4
        
        //Change The X Value
        translation.columns.3.x = 0
        
        //Change The Y Value
        translation.columns.3.y = 0
        
        //Change The Z Value
        translation.columns.3.z = -2
        
        ball.simdTransform = matrix_multiply(matrix_multiply(currentTransform, translation), ball.simdTransform)
        sceneView.scene.rootNode.addChildNode(ball)
        
        let relatedForce = simd_mul(currentTransform, float4(-7, 0, -15, 0))
        
        ball.physicsBody?.applyForce(SCNVector3(relatedForce.x , relatedForce.y, relatedForce.z), asImpulse: true)
    }
}


extension ViewController:ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        if firstPlaneNode == nil && planeAnchor.alignment == .vertical {
            firstPlaneNode = SCNNode()
            firstPlaneNode?.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
            
            // `SCNPlane` is vertically oriented in its local coordinate space, so
            // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
            firstPlaneNode?.eulerAngles.x = -.pi / 2
            
            // Add the plane visualization to the ARKit-managed node so that it tracks
            // changes in the plane anchor as plane estimation continues.
            node.addChildNode(firstPlaneNode!)
            firstPlaneNode?.addChildNode(hoop)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if ball.parent != nil && ball.presentation.simdWorldPosition.y < -2 {
            ball.removeFromParentNode()
            if isHit {
                score += 1
                DispatchQueue.main.async {
                    self.title = String(self.score)
                }
                isHit = false
            }
            setupBall()
        }
    }
}

extension ViewController:ARSessionDelegate {
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay.
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        print("Session interruption ended")
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        print("Session failed: \(error.localizedDescription)")
        resetTracking()
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("Adding anchor")
    }
}

extension ViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        let nodes = [contact.nodeA, contact.nodeB]
        guard let net = hoop.childNode(withName: "Net", recursively: true) else {
            return
        }
        if nodes.contains(ball) && nodes.contains(net) {
            isHit = true
        }
    }
}

