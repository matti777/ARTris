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

// swiftlint:disable type_body_length

/** Displays the game board / AR view. */
class GameViewController: UIViewController, ARSCNViewDelegate {
    /// Our scene view
    @IBOutlet private var sceneView: ARSCNView!

    /// Close button
    @IBOutlet private var closeButton: UIButton!

    /// Dimmer view
    @IBOutlet private var dimmerView: UIView!

    /// Game over text
    @IBOutlet private var infoLabel: UILabel!

    /// Our help text
    private let helpText = "Point the camera at horizontal surfaces. When a grid pattern appears, use your finger to place the game board."

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

    /// Infinite sized plane for panning when selecting the game board location.
    /// The `targetPlane` moves along this plane.
    private var infinitePanPlane: SCNNode?

    /// The location selector 'target' plane
    private var targetPlane: SCNNode?

    /// Green target targetPlane material
    private var targetMaterial = SCNMaterial()

    /// Red "not allowed here" targetPlane material
    private var notAllowedMaterial = SCNMaterial()

    /// UIView used to render scoreboard textures
    private var scoreView: ScoreView!

    // MARK: Private methods

    private func loadResources() {
        targetMaterial.diffuse.contents = UIImage(named: "target_texture")
        targetMaterial.readsFromDepthBuffer = false
        targetMaterial.writesToDepthBuffer = false

        notAllowedMaterial.diffuse.contents = UIImage(named: "notallowed_texture")
        notAllowedMaterial.readsFromDepthBuffer = false
        notAllowedMaterial.writesToDepthBuffer = false

        scoreView = Bundle.main.loadNibNamed("ScoreView", owner: nil, options: nil)?.first as? ScoreView
        scoreView.frame.size = CGSize(width: 512, height: 512)
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

    /// Shows the help text
    private func showHelpText() {
        let strokeTextAttributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.strokeColor: UIColor.black,
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.strokeWidth: -2.0]
        infoLabel.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 42)!
        infoLabel.attributedText = NSAttributedString(string: helpText, attributes: strokeTextAttributes)

        dimmerView.alpha = 0.5
        dimmerView.isHidden = false
        infoLabel.alpha = 1.0

        let ditchHelpText: (UIGestureRecognizer) -> Void = { [weak self] recognizer in
            self?.dimmerView.removeGestureRecognizer(recognizer)

            UIView.animate(withDuration: 0.4, animations: {
                self?.dimmerView.alpha = 0
                self?.infoLabel.alpha = 0
            }, completion: { completed in
                self?.dimmerView.isHidden = true
            })
        }

        // Install a tap recognizer to get rid of the help text
        let tapRecognizer = UITapGestureRecognizer { recognizer in
            ditchHelpText(recognizer)
        }
        dimmerView.addGestureRecognizer(tapRecognizer)

        // Create a timer to get rid of the help text
        runOnMainThreadAfter(delay: 5.0) {
            ditchHelpText(tapRecognizer)
        }
    }

    /// Shows the "Game Over" text
    private func showGameOverText() {
        let strokeTextAttributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.strokeColor: UIColor.black,
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.strokeWidth: -2.0]
        infoLabel.font = UIFont(name: "HelveticaNeue-CondensedBold", size: 96)!
        infoLabel.attributedText = NSAttributedString(string: "Game Over", attributes: strokeTextAttributes)

        dimmerView.isHidden = false

        UIView.animate(withDuration: 0.4) {
            self.infoLabel.alpha = 1.0
            self.dimmerView.alpha = 0.5
        }

        // Fade out the game over text after a while so the player can inspect the game field
        runOnMainThreadAfter(delay: 3.0) {
            UIView.animate(withDuration: 0.4, animations: {
                self.infoLabel.alpha = 0.0
                self.dimmerView.alpha = 0.0
            }, completion: { completed in
                self.dimmerView.isHidden = true
            })
        }
    }

    /// Updates the scoreboard texture
    private func updateScoreBoard(score: Int) {
        scoreView.update(score: score)
        boardNode.setScoreboardTexture(texture: scoreView.snapshot())
    }

    /// Sets up the Game object and its callbacks
    private func createGame() {
        game = Game()
        game.addGeometryCallback = { [weak self] color, boardCoordinates -> AnyObject in
            return self!.handleAddGeometry(color: color, boardCoordinates: boardCoordinates)
        }
        game.moveGeometryCallback = { [weak self] object, boardCoordinates, animate -> Void in
            if let strongSelf = self, let unitNode = object as? UnitNode {
                strongSelf.handleMoveGeometry(unitNode: unitNode, boardCoordinates: boardCoordinates, animate: animate)
            }
        }
        game.removeGeometryCallback = { [weak self] object in
            if let strongSelf = self, let unitNode = object as? UnitNode {
                strongSelf.handleRemoveGeometry(unitNode: unitNode)
            }
        }
        game.scoreUpdatedCallback = { [weak self] newScore in
            self?.updateScoreBoard(score: newScore)
        }
        game.gameOverCallback = { [weak self] in
            self?.showGameOverText()
        }
    }

    /// Place the game board onto the selected plane / location and start the game.
    /// Also register the gesture recognizers required to control the game.
    private func startGame(worldCoordinates: SCNVector3, unitSize: CGFloat, pointOfView: SCNNode) {
        // Stop recognizing anchors & remove existing anchors
        arConfig.planeDetection = []
        sceneView.session.run(arConfig, options: [.removeExistingAnchors])

        // Remove all the found horizontal planes
        horizontalPlanes.forEach { $0.removeFromParentNode() }

        // Create the game board into the selected location
        boardNode = BoardNode(board: game.board, unitSize: unitSize)
        boardNode.position = worldCoordinates

        // Turn the board so that it faces the camera - just dont rotate it
        // in the X direction so that it will stand straight up and not get tilted
        let lookAtPoint = SCNVector3(x: pointOfView.worldPosition.x, y: boardNode.worldPosition.y, z: pointOfView.worldPosition.z)
        boardNode.look(at: lookAtPoint, up: boardNode.worldUp, localFront: SCNVector3(x: 0, y: 0, z: 1))
        sceneView.scene.rootNode.addChildNode(boardNode)

        // Stop recognizing panning as now the game will be on
        self.sceneView.removeGestureRecognizer(self.panRecognizer)
        self.panRecognizer = nil

        let swipeHandler: (UIGestureRecognizer) -> Void = { [weak self] recognizer in
            guard let recognizer = recognizer as? UISwipeGestureRecognizer else {
                return
            }

            switch recognizer.direction {
            case .left:
                self?.game.movePiece(direction: .left)
            case .right:
                self?.game.movePiece(direction: .right)
            case .up:
                self?.game.rotatePiece(direction: .counterclockwise)
            case .down:
                self?.game.rotatePiece(direction: .clockwise)
            default:
                break
            }
        }

        // Start recognizing swipes left and right to move the piece
        let swipeLeftRecognizer = UISwipeGestureRecognizer(callback: swipeHandler)
        swipeLeftRecognizer.direction = .left
        sceneView.addGestureRecognizer(swipeLeftRecognizer)
        let swipeRightRecognizer = UISwipeGestureRecognizer(callback: swipeHandler)
        swipeRightRecognizer.direction = .right
        sceneView.addGestureRecognizer(swipeRightRecognizer)

        // Start recognizing swipes up and down to rotate the piece
        let swipeUpRecognizer = UISwipeGestureRecognizer(callback: swipeHandler)
        swipeUpRecognizer.direction = .up
        sceneView.addGestureRecognizer(swipeUpRecognizer)
        let swipeDownRecognizer = UISwipeGestureRecognizer(callback: swipeHandler)
        swipeDownRecognizer.direction = .down
        sceneView.addGestureRecognizer(swipeDownRecognizer)

        // Start recognizing double taps to drop the piece
        let tapRecognizer = UITapGestureRecognizer(callback: { [weak self] recognizer in
            self?.game.dropPiece()
        })
        tapRecognizer.numberOfTapsRequired = 2
        sceneView.addGestureRecognizer(tapRecognizer)

        // Start the game!
        game.start()
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

            if !targetPlaneGeometry.materials.contains(notAllowedMaterial) {
                // Calculate board size from target plane geometry size
                let unitSize = (targetPlaneGeometry.width / CGFloat(game.board.numColumns)) * 0.5
                startGame(worldCoordinates: hitResult.worldCoordinates, unitSize: unitSize, pointOfView: pov)
            }
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
        let unitNode = UnitNode(size: boardNode.unitSize, color: color)
        unitNode.position = boardNode.translateCoordinates(gridCoordinates: boardCoordinates)
        boardNode.addChildNode(unitNode)

        if boardCoordinates.y < 0 {
            unitNode.setTransparency(transparency: .faded)
        } else {
            unitNode.setTransparency(transparency: .normal)
        }

        return unitNode
    }

    /// Moves the given unit node into new position, possibly with animation.
    func handleMoveGeometry(unitNode: UnitNode, boardCoordinates: GridCoordinates, animate: Bool) {
        unitNode.position = boardNode.translateCoordinates(gridCoordinates: boardCoordinates)

        if boardCoordinates.y < 0 {
            unitNode.setTransparency(transparency: .faded)
        } else {
            unitNode.setTransparency(transparency: .normal)
        }
    }

    /// Removes the given unit node geometry, animating its alpha to 0
    func handleRemoveGeometry(unitNode: UnitNode) {
        unitNode.removeFromParentNode()
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

        showHelpText()
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

    deinit {
        log.debug("GameViewController deallocated.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.text = nil

        // Animate all geometry manipulations
        SCNTransaction.animationDuration = 0.3

        // Set up the Game engine
        createGame()

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
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // Create a session configuration
        arConfig = ARWorldTrackingConfiguration()
        arConfig.isLightEstimationEnabled = true
        arConfig.planeDetection = .horizontal

        // Initialize our scene
        sceneView.scene = SCNScene()
    }
}
