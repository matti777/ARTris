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

    // AR view configuration
    private var arConfig: ARWorldTrackingConfiguration!

    /// Current game
    private var game: Game!

    /// Tap gesture recognizer
    private var tapRecognizer: UITapGestureRecognizer!

    // MARK: Private methods

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
    }

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

        //TODO do we need to do something to our plane?
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

        // Create a tap gesture recognizer
        tapRecognizer = UITapGestureRecognizer(callback: { [weak self] in
            if let strongSelf = self {
                strongSelf.handleTap(location: strongSelf.tapRecognizer.location(in: strongSelf.sceneView))
            }
        })
        sceneView.addGestureRecognizer(tapRecognizer)

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
