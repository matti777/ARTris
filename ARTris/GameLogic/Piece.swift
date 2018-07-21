//
//  Piece.swift
//  ARTris
//
//  Created by Matti Dahlbom on 20/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import Foundation

/**
 Represents a game piece. The piece consists of multiple Units, laid out in
 a Grid. There is one Grid per each of the rotations (piece orientations).
 */
class Piece {
    /// Piece rotation grids.
    private var grids: [Grid]

    /// Current rotation
    private var rotation = 0

    /// Returns an ascii art describing all the rotations (grids) for this piece
    func asciiArt() -> String {
        return grids.map { "\($0.asciiArt())\n" }.joined(separator: "")
    }

    /// Creates a new Piece for a given type.
    init(type: PieceType) {
        grids = Shape.createGrids(type: type)
    }
}
