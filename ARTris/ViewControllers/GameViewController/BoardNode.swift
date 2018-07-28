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
    private var width: CGFloat
    private var height: CGFloat
    private var depth: CGFloat

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

        let floorMaterial = SCNMaterial()
        floorMaterial.diffuse.contents = UIColor(hexString: "#FF0000FF")
        floorMaterial.isDoubleSided = true

        // Add 'floor'
        let floorGeometry = SCNPlane(width: width, height: depth)
        floorGeometry.materials = [floorMaterial]
        let floor = SCNNode(geometry: floorGeometry)
        floor.eulerAngles.x = -.pi / 2
        addChildNode(floor)

        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = UIColor(hexString: "#0000FFFF")
        wallMaterial.isDoubleSided = true

        // Add 'left wall'
        let wallGeometry = SCNPlane(width: height, height: depth)
        wallGeometry.materials = [wallMaterial]
        let leftWall = SCNNode(geometry: wallGeometry)
        leftWall.eulerAngles.x = -.pi / 2
        leftWall.eulerAngles.z = .pi / 2
        addChildNode(leftWall)

        //TODO others
    }

    /// Not implemented
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
