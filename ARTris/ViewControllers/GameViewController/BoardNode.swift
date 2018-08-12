//
//  BoardNode.swift
//  ARTris
//
//  Created by Matti Dahlbom on 28/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import ARKit
import Foundation

import QvikSwift

/**
 Represents the 3D game board. It consists of 'walls'. The pieces are formed
 of UnitNode:s, added as children to the BoardNode.
 */
class BoardNode: SCNNode {
    private var board: Board

    /// Object's width (x)
    private(set) var width: CGFloat

    /// Object's height (y)
    private(set) var height: CGFloat

    /// Object's depth (z)
    private(set) var depth: CGFloat

    /// Unit side length (= dimensions for a unit cube, building blocks for game pieces)
    private(set) var unitSize: CGFloat

    /// The Scoreboard node
    private var scoreboard: SCNNode!

    // MARK: Public methods

    /// Updates the scoreboard texture from an image
    func setScoreboardTexture(texture: UIImage) {
        scoreboard.geometry?.firstMaterial?.diffuse.contents = texture
    }

    /// Translates the given unit's 2D board grid coordinates into 3D coordinates in
    /// the BoardNode's coordinate system. The returned coordinate will represent the
    /// location of the unit's origin (center point).
    func translateCoordinates(gridCoordinates: GridCoordinates) -> SCNVector3 {
        let x = CGFloat(gridCoordinates.x - (board.numColumns / 2)) * unitSize
        let y = CGFloat(-gridCoordinates.y + board.numRows - 1) * unitSize

        return SCNVector3(x: Float(x + (unitSize / 2)), y: Float(y + (unitSize / 2)), z: 0)
    }

    // MARK: Initializers

    /**
     Creates the board.

     - parameter unitSize: side length of the 'unit cube', ie dimension of a UnitNode
     */
    init(board: Board, unitSize: CGFloat) {
        self.board = board
        self.width = unitSize * CGFloat(board.numColumns)
        self.depth = unitSize
        self.height = unitSize * CGFloat(board.numRows)
        self.unitSize = unitSize

        super.init()

        // Create our shared 'wall' material
        let wallMaterial = createMaterial(UIColor(hexString: "#AAAAAABB"))

        // Add 'floor'
        let floorGeometry = SCNPlane(width: width, height: depth)
        floorGeometry.materials = [wallMaterial]
        let floor = SCNNode(geometry: floorGeometry)
        floor.eulerAngles.x = -.pi / 2
        addChildNode(floor)

        // Add 'roof'
        let roof = SCNNode(geometry: floorGeometry)
        roof.eulerAngles.x = -.pi / 2
        roof.position.y = Float(height)
        addChildNode(roof)

        // Add 'left wall'
        let wallGeometry = SCNPlane(width: height, height: depth)
        wallGeometry.materials = [wallMaterial]
        let leftWall = SCNNode(geometry: wallGeometry)
        leftWall.eulerAngles.x = -.pi / 2
        leftWall.eulerAngles.z = .pi / 2
        leftWall.position.x = Float(-width / 2)
        leftWall.position.y = Float(height / 2)
        addChildNode(leftWall)

        // Add 'right wall'
        let rightWall = SCNNode(geometry: wallGeometry)
        rightWall.eulerAngles.x = -.pi / 2
        rightWall.eulerAngles.z = .pi / 2
        rightWall.position.x = Float(width / 2)
        rightWall.position.y = Float(height / 2)
        addChildNode(rightWall)

        // Create the score board on the left side of the game board
        let scoreboardSize = width * 1.2 / 2
        let scoreBoardGeometry = SCNPlane(width: scoreboardSize, height: scoreboardSize)
        scoreBoardGeometry.firstMaterial?.diffuse.contents = UIColor(hexString: "#AAAAAA")
        scoreboard = SCNNode(geometry: scoreBoardGeometry)
        scoreboard.position.x = Float(-(scoreboardSize + width * 1.1) / 2.0)
        scoreboard.position.y = Float((scoreboardSize + height) / 2.0)
        addChildNode(scoreboard)
    }

    /// Not implemented
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
