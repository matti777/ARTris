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

    /**
     Creates the board.

     - parameter unitSize: side length of the 'unit cube', ie dimension of a UnitNode
     */
    init(board: Board, unitSize: CGFloat) {
        self.board = board
        self.width = unitSize * CGFloat(board.numColumns)
        self.depth = unitSize
        self.height = unitSize * CGFloat(board.numRows)

        super.init()

        // Create our shared 'wall' material
        //TODO

        // Add 'floor'
        let floorGeometry = SCNPlane(width: width, height: depth)
        floorGeometry.materials = [createMaterial(UIColor(hexString: "#FF0000FF"))]
        let floor = SCNNode(geometry: floorGeometry)
        floor.eulerAngles.x = -.pi / 2
        addChildNode(floor)

        // Add 'left wall'
        let leftWallGeometry = SCNPlane(width: height, height: depth)
        leftWallGeometry.materials = [createMaterial(UIColor(hexString: "#0000FFFF"))]
        let leftWall = SCNNode(geometry: leftWallGeometry)
        leftWall.eulerAngles.x = -.pi / 2
        leftWall.eulerAngles.z = .pi / 2
        leftWall.position.x = Float(-width / 2)
        leftWall.position.y = Float(height / 2)
        addChildNode(leftWall)

        // Add 'right wall'
        let rightWallGeometry = SCNPlane(width: height, height: depth)
        rightWallGeometry.materials = [createMaterial(UIColor(hexString: "#00FF00FF"))]
        let rightWall = SCNNode(geometry: rightWallGeometry)
        rightWall.eulerAngles.x = -.pi / 2
        rightWall.eulerAngles.z = .pi / 2
        rightWall.position.x = Float(width / 2)
        rightWall.position.y = Float(height / 2)
        addChildNode(rightWall)

        //TODO others
    }

    /// Not implemented
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
