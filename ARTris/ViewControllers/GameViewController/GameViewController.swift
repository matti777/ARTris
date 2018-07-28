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
    private var game = Game()

    /// Pan gesture recognizer; used for selecting game location on the
    /// `panPlane`
    private var panRecognizer: UIPanGestureRecognizer!

    /// The horizontal plane being currently panned. The `targetPlane` moves
    /// along this plane.
    private var panPlane: SCNNode?

    /// The location selector 'target' plane
    private var targetPlane: SCNNode?

    /// Latest target plane coordinates. Nil if not in a proper location.
    private var targetPlaneCoordinates: SCNVector3?

    /// Green target targetPlane material
    private var targetMaterial = SCNMaterial()

    /// Red "not allowed here" targetPlane material
    private var notAllowedMaterial = SCNMaterial()

    // MARK: Private methods

    private func loadResources() {
        targetMaterial.diffuse.contents = UIImage(named: "target_texture")
        targetMaterial.readsFromDepthBuffer = false
        targetMaterial.writesToDepthBuffer = false

        notAllowedMaterial.diffuse.contents = UIImage(named: "notallowed_texture")
        notAllowedMaterial.readsFromDepthBuffer = false
        notAllowedMaterial.writesToDepthBuffer = false
    }

    private func hitTest(recognizer: UIGestureRecognizer) -> (SCNNode?, SCNVector3?) {
        let location = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: [SCNHitTestOption.categoryBitMask: hittableCategoryMask])

        //TODO make sure the hit test result is a horizontal plane!
        //TODO hit-test against the infinite plane!
        guard let firstResult = hitResults.first else {
            log.debug("No hits.")
            return (nil, nil)
        }

        let node = firstResult.node
        let coordinates = firstResult.localCoordinates

        return (node, coordinates)
    }

    private func updateTargetPlane(coordinates: SCNVector3) {
        guard let targetPlane = targetPlane, let targetPlaneGeometry = targetPlane.geometry as? SCNPlane, let panPlaneGeometry = panPlane?.geometry as? SCNPlane else {
            log.error("Invalid target / pan plane")
            return
        }

        // Figure out a side length for the target plane from the pan plane extents
        let size = max(0.5, min(panPlaneGeometry.width, panPlaneGeometry.height) * 0.75)

        targetPlaneGeometry.width = size
        targetPlaneGeometry.height = size
        targetPlane.position = coordinates

        if (abs(coordinates.x) > abs(Float(panPlaneGeometry.width / 2) * 0.8)) ||
            (abs(coordinates.y) > abs(Float(panPlaneGeometry.height / 2) * 0.8)) {
            targetPlaneGeometry.materials = [notAllowedMaterial]
            targetPlaneCoordinates = nil
        } else {
            targetPlaneGeometry.materials = [targetMaterial]
            targetPlaneCoordinates = coordinates
        }
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
        targetPlaneGeometry.materials = [targetMaterial]
        targetPlane = SCNNode(geometry: targetPlaneGeometry)
        targetPlane?.renderingOrder = 1
        updateTargetPlane(coordinates: coordinates)

        panPlane?.addChildNode(targetPlane!)
    }

    private func panChanged(recognizer: UIGestureRecognizer) {
        assert(targetPlane != nil, "Target plane must exist at this point")
        assert(panPlane != nil, "panPlane must be set at this point")

        guard let (node, coordinates) = hitTest(recognizer: recognizer) as? (SCNNode?, SCNVector3) else {
            //TODO we need to add an infinite sized plane to handle the panning; do this when pan starts
            log.error("Failed to get local pan coordinates")
            return
        }

        // Check that it is the same plane that we started the pan on
        if node != panPlane {
            log.error("*** Hit another plane, aborting ***")
            recognizer.cancel()
            return
        }

        updateTargetPlane(coordinates: coordinates)
    }

    private func panEnded(recognizer: UIGestureRecognizer) {
        if let targetPlaneCoordinates = targetPlaneCoordinates, let panPlane = panPlane, let targetPlane = targetPlane, let targetPlaneGeometry = targetPlane.geometry as? SCNPlane {
            log.debug("Placing game board")
            let boardNode = BoardNode(board: game.board, unitSize: targetPlaneGeometry.width / CGFloat(game.board.numColumns))
            boardNode.position = targetPlaneCoordinates
            //TODO add the BoardNode under the local root (using panPlane's worldtransform) instead of under panPlane
            panPlane.addChildNode(boardNode)
        }

        targetPlane?.removeFromParentNode()
        targetPlane = nil
        targetPlaneCoordinates = nil
        panPlane = nil
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

        //TODO make nicer
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        //plane.materials.first?.diffuse.contents = UIColor(hexString: "#0000EE99")
        plane.materials.first?.diffuse.contents = UIImage(named: "honeycomb_texture")

        let planeNode = SCNNode(geometry: plane)
        planeNode.categoryBitMask |= hittableCategoryMask

        //TODO make nicer
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        planeNode.eulerAngles.x = -.pi / 2

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
        log.debug("** Removed node: \(node) **")

        if let child = node.childNodes.first, let panPlane = panPlane, child == panPlane {
            log.debug("*** panPlane was removed ***")

            // Our panPlane was removed; cancel any pending pan operation
            self.panRecognizer.cancel()
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

        // Load our resources
        loadResources()

        // Install a pan recognizer to handle positioning the game board
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
