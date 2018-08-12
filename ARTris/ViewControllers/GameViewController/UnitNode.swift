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

    private let normalTransparency = UIColor(white: 0, alpha: 0.85)
    private let fadedTransparency = UIColor(white: 0, alpha: 0.3)

    /// Defines the unit transparency; units outside the board area (top)
    /// are set to be faded, all units on the board area are set to normal
    enum Transparency {
        case normal, faded
    }

    /// Sets the unit transparency
    func setTransparency(transparency: Transparency) {
        switch transparency {
        case .normal:
            geometry?.materials.first?.transparent.contents = normalTransparency
        case .faded:
            geometry?.materials.first?.transparent.contents = fadedTransparency
        }
    }

    /// Creates a new cube with given side size and color.
    init(size: CGFloat, color: UIColor) {
        self.size = size

        super.init()

        let geometry = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        geometry.materials.first?.diffuse.contents = color
        geometry.materials.first?.transparent.contents = normalTransparency
        self.geometry = geometry
    }

    /// Not implemented
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
