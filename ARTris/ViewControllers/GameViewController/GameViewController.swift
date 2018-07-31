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

    /// Defines hit test category for the detected horizontal planes
    private let horizontalPlaneCategoryMask: Int = (1 << 30)

    /// Defines hit test category for the infinite pan plane
    private let infinitePlaneCategoryMask: Int = (1 << 31)

    // AR view configuration
    private var arConfig: ARWorldTrackingConfiguration!

    /// Current game
    private var game: Game!

    /// Game board node
    private var boardNode: BoardNode!

    /// List of all the horizontal planes added to the scene
    private var horizontalPlanes: [SCNNode] = []

    /// Pan gesture recognizer; used for selecting game location on the
    /// `panPlane`
    private var panRecognizer: UIPanGestureRecognizer!

    /// The horizontal plane being currently panned. The `targetPlane` moves
    /// along this plane.
//    private var panPlane: SCNNode?

    /// Infinite sized plane for panning when selecting the game board location.
    /// The `targetPlane` moves along this plane.
    private var infinitePanPlane: SCNNode?

    /// The location selector 'target' plane
    private var targetPlane: SCNNode?

    /// Latest target plane position world coordinates. Nil if not in a proper location.
//    private var targetPlaneWorldCoordinates: SCNVector3?

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

    /// Performs a hit test from given gesture recognizer location, optionally limiting the
    /// test to a given hittable bitmask
    private func hitTest(recognizer: UIGestureRecognizer, hitBitMask: Int? = nil) -> SCNHitTestResult? {
        let location = recognizer.location(in: sceneView)
        var options: [SCNHitTestOption: Any]? = nil
        if let hitBitMask = hitBitMask {
            options = [SCNHitTestOption.categoryBitMask: hitBitMask]
        }
        let hitResults = sceneView.hitTest(location, options: options)

        return hitResults.first
    }

    private func updateTargetPlane(coordinates: SCNVector3) {
        guard let targetPlane = targetPlane, let targetPlaneGeometry = targetPlane.geometry as? SCNPlane, let panPlaneGeometry = targetPlane.parent?.geometry as? SCNPlane else {
            log.error("** Invalid target / pan plane **")
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
        } else {
            targetPlaneGeometry.materials = [targetMaterial]
        }
    }

    /// Place the game board onto the selected plane / location and start the game.
    /// Also register the gesture recognizers required to control the game.
    private func startGame(worldCoordinates: SCNVector3, unitSize: CGFloat, pointOfView: SCNNode) {
        boardNode = BoardNode(board: game.board, unitSize: unitSize)
        boardNode.position = worldCoordinates

        // Turn the board so that it faces the camera - just dont rotate it
        // in the Y direction so that it will stand straight
        let lookAtPoint = SCNVector3(x: pointOfView.worldPosition.x, y: boardNode.worldPosition.y, z: pointOfView.worldPosition.z)
        boardNode.look(at: lookAtPoint, up: boardNode.worldUp, localFront: SCNVector3(x: 0, y: 0, z: 1))

        sceneView.scene.rootNode.addChildNode(boardNode)
        game.start()

        // Stop recognizing panning as now the game is on
        self.sceneView.removeGestureRecognizer(self.panRecognizer)
        self.panRecognizer = nil

    }

    private func panBegan(recognizer: UIGestureRecognizer) {
        assert(targetPlane == nil, "targetPlane must not exist at this point")
        assert(infinitePanPlane == nil, "infinitePanPlane must not be set at this point")

        guard let hitResult = hitTest(recognizer: recognizer, hitBitMask: horizontalPlaneCategoryMask) else {
            // Didn't hit a horizontal plane
            log.debug("Didn't hit a horizontal plane")
            recognizer.cancel()
            return
        }

        // Create an infinite sized plane for handling panning
        let infinitePanPlaneGeometry = SCNPlane(width: 10000, height: 10000)
        infinitePanPlaneGeometry.materials = [createMaterial(UIColor(hexString: "#00000000"))]
        infinitePanPlane = SCNNode(geometry: infinitePanPlaneGeometry)
        infinitePanPlane!.categoryBitMask |= infinitePlaneCategoryMask
        hitResult.node.addChildNode(infinitePanPlane!)

        // Create a reasonably sized planar texture for showing the placement 'target'
        let targetPlaneGeometry = SCNPlane(width: 0, height: 0)
        targetPlaneGeometry.materials = [targetMaterial]
        targetPlane = SCNNode(geometry: targetPlaneGeometry)
        targetPlane?.renderingOrder = 1
        hitResult.node.addChildNode(targetPlane!)

        updateTargetPlane(coordinates: hitResult.localCoordinates)
    }

    private func panChanged(recognizer: UIGestureRecognizer) {
        assert(targetPlane != nil, "Target plane must exist at this point")
        assert(infinitePanPlane != nil, "infinitePanPlane must be set at this point")

        guard let hitResult = hitTest(recognizer: recognizer, hitBitMask: infinitePlaneCategoryMask) else {
            log.debug("panChanged: Didn't hit infinity pan plane?")
            return
        }

        updateTargetPlane(coordinates: hitResult.localCoordinates)
    }

    /// Handles ending of the pan gesture; if the pan location is within legal
    /// bounds for the horizontal plane, place the game board there and start the game
    private func panEnded(recognizer: UIGestureRecognizer) {
        if let targetPlane = targetPlane, let targetPlaneGeometry = targetPlane.geometry as? SCNPlane, let hitResult = hitTest(recognizer: recognizer, hitBitMask: infinitePlaneCategoryMask), let pov = sceneView.pointOfView {

            startGame(worldCoordinates: hitResult.worldCoordinates, unitSize: targetPlaneGeometry.width / CGFloat(game.board.numColumns), pointOfView: pov)
        }

        targetPlane?.removeFromParentNode()
        targetPlane = nil
        log.debug("targetPlane removed")

        infinitePanPlane?.removeFromParentNode()
        infinitePanPlane = nil
        log.debug("infinitePanPlane removed")
    }

    /// Adds a new unit cube to the scene.
    func handleAddGeometry(color: UIColor, boardCoordinates: GridCoordinates) -> AnyObject {
        log.debug("Adding unit to boardCoordinates: \(boardCoordinates)")
        let unitNode = UnitNode(size: boardNode.unitSize, color: color)
        unitNode.position = boardNode.translateCoordinates(gridCoordinates: boardCoordinates)
        boardNode.addChildNode(unitNode)

        return unitNode
    }

    /// Moves the given unit node into new position, possibly with animation.
    func handleMoveGeometry(unitNode: UnitNode, boardCoordinates: GridCoordinates) {
        log.debug("moving geometry")
        //TODO support animation
        unitNode.position = boardNode.translateCoordinates(gridCoordinates: boardCoordinates)
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

        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        planeGeometry.materials.first?.diffuse.contents = UIImage(named: "honeycomb_texture")
        planeGeometry.materials.first?.transparent.contents = UIColor(white: 0.0, alpha: 0.8)

        let plane = SCNNode(geometry: planeGeometry)
        plane.categoryBitMask |= horizontalPlaneCategoryMask

        plane.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        plane.eulerAngles.x = -.pi / 2

        node.addChildNode(plane)

        horizontalPlanes.append(plane)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {
            return
        }

        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)

        planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        log.debug("*** Removed horizontal plane, parent node: \(node) ***")

        if let targetPlane = targetPlane, let horizontalPlane = targetPlane.parent, let child = node.childNodes.first, horizontalPlane == child {
            log.debug("*** Panning horizontal plane was removed ***")

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

        game = Game(addGeometryCallback: { [weak self] color, boardCoordinates -> AnyObject in
            return self!.handleAddGeometry(color: color, boardCoordinates: boardCoordinates)
            }, moveGeometryCallback: { [weak self] object, boardCoordinates -> Void in
                if let strongSelf = self, let unitNode = object as? UnitNode {
                    strongSelf.handleMoveGeometry(unitNode: unitNode, boardCoordinates: boardCoordinates)
                }
        })

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

        // Enable debug visualization helpers
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]

        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true

        // Create a session configuration
        arConfig = ARWorldTrackingConfiguration()
        arConfig.isLightEstimationEnabled = true
        arConfig.planeDetection = .horizontal

        // Initialize our scene
        sceneView.scene = SCNScene()
    }
}
