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
    /// Defines all the 4 rotations the pieces can be in
    enum Rotation: Int {
        case deg0 = 0, deg90, deg180, deg270
    }

    /// All the rotations in order; traversing the array using an ascending index
    /// goes through the rotations in clockwise order.
    private static let rotations: [Rotation] = [.deg0, .deg90, .deg180, .deg270]

    /// Piece as a Grid, in 0-degree rotation
    private var grid: Grid

    // Piece as a Grid, in its current rotation
    private var rotatedGrid: Grid

    /// Current rotation
    private var rotation: Rotation = .deg0

    /// Returns an ascii art describing all the rotations (grids) for this piece
    func asciiArt() -> String {
        return grid.asciiArt()
    }

    // All the piece shapes (in their 0-degree rotation) in parseable ascii art format
    private static let shapes: [PieceType: [String]] = [
        .square: ["....",
                  ".XX.",
                  ".XX.",
                  "...."],
        .i: [".X..",
             ".X..",
             ".X..",
             ".X.."]
    ]

    /// Creates a new Grid for a given piece type.
    static func parseShape(type: PieceType) -> Grid {
        guard let shape = Piece.shapes[type] else {
            assert(false, "Failed to find shape for type \(type)")
        }

        assert(shape.count == 4, "Invalid row count for shape")
        let grid = Grid(numColumns: 4, numRows: 4)

        for y in 0..<4 {
            assert(shape[y].count == 4, "Invalid row length for shape")
            for x in 0..<shape[y].count where shape[y][x] == "X" {
                grid[x, y] = Unit(type: type)
            }
        }

        return grid
    }

    /// Creates a new Piece for a given type.
    init(type: PieceType) {
        grid = Piece.parseShape(type: type)
        rotatedGrid = Grid(grid: grid)
    }
}
