//
//  UnitNode.swift
//  ARTris
//
//  Created by Matti Dahlbom on 30/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import SceneKit

/**
 Represents a Unit cube; that is, a Unit in our game logic layer - not to be
 confused with an actual "unit cube" with sides all length of = 1. The side length
 for this cube are decided by the game board size upon its placement.

 Each visual Piece are built out of these cubes.
*/
class UnitNode: SCNNode {
    /// Side length of the cube.
    private(set) var size: CGFloat

    /// Creates a new cube with given side size and color.
    init(size: CGFloat, color: UIColor) {
        self.size = size

        super.init()

        let geometry = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        geometry.materials.first?.diffuse.contents = color
        geometry.materials.first?.transparent.contents = UIColor(white: 0, alpha: 0.8)
        self.geometry = geometry
    }

    /// Not implemented
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
