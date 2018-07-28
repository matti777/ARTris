//
//  ViewController.swift
//  ARTris
//
//  Created by Matti Dahlbom on 20/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

import QvikSwift
import Toast_Swift

/** Displays the game board / AR view. */
class GameViewController: UIViewController, ARSCNViewDelegate {
    /// Our scene view
    @IBOutlet private var sceneView: ARSCNView!

    /// Close button
    @IBOutlet private var closeButton: UIButton!

    /// Defines category for objects that should be part of hit tests
    private let hittableCategoryMask: Int = (1 << 31)

    // AR view configuration
    private var arConfig: ARWorldTrackingConfiguration!

    /// Current game
    private var game: Game!

    /// Pan gesture recognizer; used for selecting game location on the
    /// `panPlane`
    private var panRecognizer: UIPanGestureRecognizer!

    /// The horizontal plane being currently panned. The `targetPlane` moves
    /// along this plane.
    private var panPlane: SCNNode?

    /// The location selector 'target' plane
    private var targetPlane: SCNNode?

    /// Green target texture
    private var targetTexture: UIImage!

    // MARK: Private methods
/*
    private func handleTap(location: CGPoint) {
        //TODO state handling: if game not started, try to pick a plane. if game started, drop falling piece.

        log.debug("Picking plane..")

        let hitResults = sceneView.hitTest(location, options: nil)
        guard let firstResult = hitResults.first else {
            log.debug("No hits.")
            return
        }

        let node = firstResult.node
        log.debug("Hit node: \(node)")

        // Add 'target' texture as a plane
        //TODO figure out a size from the clicked horizontal plane dimensions
        let plane = SCNPlane(width: 0.5, height: 0.5)

        //plane.materials.first?.diffuse.contents = UIColor(hexString: "#0000EE99")
        plane.materials.first?.diffuse.contents = targetTexture

        let planeNode = SCNNode(geometry: plane)
        planeNode.position = node.position
        planeNode.eulerAngles = node.eulerAngles

        node.addChildNode(planeNode)
    }
*/
    private func hitTest(recognizer: UIGestureRecognizer) -> (SCNNode?, SCNVector3?) {
        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [SCNHitTestOption.categoryBitMask: hittableCategoryMask])

        //TODO make sure the hit test result is a horizontal plane!
        guard let firstResult = hitResults.first else {
            log.debug("No hits.")
            return (nil, nil)
        }

        let node = firstResult.node
        log.debug("Hit node: \(node)")

        let coordinates = firstResult.localCoordinates
        log.debug("Local coordinates: \(coordinates)")

        return (node, coordinates)
    }

    private func endPan() {
        assert(targetPlane != nil, "Target plane must exist at this point")
        assert(panPlane != nil, "panPlane must be set at this point")

        targetPlane?.removeFromParentNode()
        targetPlane = nil
        panPlane = nil

        self.panRecognizer.cancel()
    }

    private func updateTargetPlane(coordinates: SCNVector3) {
        guard let targetPlane = targetPlane, let targetPlaneGeometry = targetPlane.geometry as? SCNPlane, let panPlaneGeomtery = panPlane?.geometry as? SCNPlane else {
            log.error("Invalid target / pan plane")
            return
        }

        // Figure out a side length for the target plane from the pan plane extents
        let size = max(0.5, min(panPlaneGeomtery.width, panPlaneGeomtery.height) * 0.75)
        log.debug("targetPlane size = \(size)")

        targetPlaneGeometry.width = size
        targetPlaneGeometry.height = size
        targetPlane.position = coordinates
    }

    private func panBegan(recognizer: UIGestureRecognizer) {
        log.debug("pan began")

        assert(targetPlane == nil, "targetPlane must not exist at this point")
        assert(panPlane == nil, "panPlane must not be set at this point")

        guard let (node, coordinates) = hitTest(recognizer: recognizer) as? (SCNNode, SCNVector3) else {
            // Didn't hit a horizontal plane
            recognizer.cancel()
            return
        }

        panPlane = node

        let targetPlaneGeometry = SCNPlane(width: 0, height: 0)
        targetPlaneGeometry.materials.first?.diffuse.contents = UIImage(named: "texture_target.pdf")
        targetPlane = SCNNode(geometry: targetPlaneGeometry)
        updateTargetPlane(coordinates: coordinates)

        panPlane?.addChildNode(targetPlane!)
    }

    private func panChanged(recognizer: UIGestureRecognizer) {
        log.debug("pan changed")

        assert(targetPlane != nil, "Target plane must exist at this point")
        assert(panPlane != nil, "panPlane must be set at this point")

        guard let (_, coordinates) = hitTest(recognizer: recognizer) as? (SCNNode?, SCNVector3) else {
            log.error("Failed to get local pan coordinates")
            return
        }

        updateTargetPlane(coordinates: coordinates)
    }

    private func panEnded(recognizer: UIGestureRecognizer) {
        log.debug("pan ended")

        endPan()
    }

    /*
     try:

     CGContextRef context = UIGraphicsGetCurrentContext();
 CGContextSetFillColor(context, CGColorGetComponents([UIColor colorWithRed:0.5 green:0.5 blue:0 alpha:1].CGColor)); // don't make color too saturated
 CGContextFillRect(context, rect); // draw base
 [[UIImage imageNamed:@"someImage.png"] drawInRect: rect blendMode:kCGBlendModeOverlay alpha:1.0];

     or:

     CGContextRef context = UIGraphicsGetCurrentContext();
     CGContextSaveGState(context);

     // Draw picture first
     //
     CGContextDrawImage(context, self.frame, self.image.CGImage);

     // Blend mode could be any of CGBlendMode values. Now draw filled rectangle
     // over top of image.
     //
     CGContextSetBlendMode (context, kCGBlendModeMultiply);
     CGContextSetFillColor(context, CGColorGetComponents(self.overlayColor.CGColor));
     CGContextFillRect (context, self.bounds);
     CGContextRestoreGState(context);
 */

    // MARK: IBAction handlers

    @IBAction func closeButtonPressed(sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: From ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }

        log.debug("node: \(node)")
        log.debug("planeAnchor.extent: \(planeAnchor.extent)")

        //TODO make nicer
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        //plane.materials.first?.diffuse.contents = UIColor(hexString: "#0000EE99")
        plane.materials.first?.diffuse.contents = UIImage(named: "tron_grid")

        let planeNode = SCNNode(geometry: plane)
        planeNode.categoryBitMask |= hittableCategoryMask

        //TODO make nicer
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi / 2
        log.debug("planeNode.position = \(planeNode.position)")

        node.addChildNode(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {
            return
        }

        //TODO make nicer
        log.debug("planeAnchor.extent: \(planeAnchor.extent)")
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        //TODO make nicer
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        log.debug("new planeNode.position = \(planeNode.position)")
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        log.debug("Removed node: \(node)")

        if let child = node.childNodes.first, let panPlane = panPlane, child == panPlane {
            log.debug("*** panPlane was removed ***")

            // Our panPlane was removed; cancel any pending pan operation
            endPan()
        }
    }

/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        self.view.makeToast("ARKit session error: \(error)")
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        self.view.makeToast("ARKit session interrupted")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }

    // MARK: Lifecycle etc.

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create new game
        game = Game()
        game.start()

        // Run / resumt the view's session
        sceneView.session.run(arConfig)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        closeButton.layer.cornerRadius = closeButton.width / 2.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //TODO clean up
        // Load PDF textures
//        let bundle = NSBundle(forClass: self.classForCoder)
//        let image = UIImage(named: "pic1", inBundle: bundle, compatibleWithTraitCollection: nil)
        let targetImage = UIImage(named: "texture_target.pdf")
        log.debug("targetImage: \(String(describing: targetImage))")

        // Create a tap gesture recognizer
//        tapRecognizer = UITapGestureRecognizer(callback: { [weak self] in
//            if let strongSelf = self {
//                strongSelf.handleTap(location: strongSelf.tapRecognizer.location(in: strongSelf.sceneView))
//            }
//        })
//        sceneView.addGestureRecognizer(tapRecognizer)
        panRecognizer = ImmediatePanGestureRecognizer(callback: { [weak self] recognizer in
            switch recognizer.state {
            case .possible:
                break
            case .began:
                self?.panBegan(recognizer: recognizer)
            case .changed:
                self?.panChanged(recognizer: recognizer)
            default:
                self?.panEnded(recognizer: recognizer)
            }
        })
        sceneView.addGestureRecognizer(panRecognizer)

        // Set the view's delegate
        sceneView.delegate = self

        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true

        // Enable debug visualization helpers
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Create a session configuration
        arConfig = ARWorldTrackingConfiguration()
        arConfig.isLightEstimationEnabled = true
        arConfig.planeDetection = .horizontal

        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
    }
}
