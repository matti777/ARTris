//
//  Piece.swift
//  ARTris
//
//  Created by Matti Dahlbom on 20/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import UIKit

/**
 Represents a game piece ('tetromino'). The piece consists of multiple Units, laid out in
 a Grid. There is one Grid per each of the rotations (piece orientations).
 */
class Piece {
    /// Piece ('tetromino') types.
    enum Kind {
        case square, i
    }

    /// Defines all the 4 rotations the pieces can be in
    enum Rotation: Int {
        case deg0 = 0, deg90, deg180, deg270
    }

    /// Size (side length) for all pieces
    static let size = 4

    /// All the rotations in order; traversing the array using an ascending index
    /// goes through the rotations in clockwise order.
    private static let rotations: [Rotation] = [.deg0, .deg90, .deg180, .deg270]

    /// Piece colors map
    static let colors: [Kind: UIColor] = [
        .square: UIColor(hexString: "#2DFEFE"),
        .i: UIColor(hexString: "#FD29FC"),
    ]

    /// Type of this piece
    var kind: Kind

    /// Piece as a Grid, in 0-degree rotation
    private var grid: Grid

    // Piece as a Grid, in its current rotation
    private var rotatedGrid: Grid

    /// Current rotation
    private var rotation: Rotation = .deg0

    /// Returns the number of empty rows in the bottom of the grid
    var bottomMargin: Int {
        for i in 0..<Piece.size {
            let y = (Piece.size - 1) - i
            for x in 0..<Piece.size where self[x, y] != nil {
                return i
            }
        }

        return Piece.size
    }

    // MARK: Private methods

    // All the piece shapes (in their 0-degree rotation) in parseable ascii art format
    private static let shapes: [Kind: [String]] = [
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
    private static func parseShape(kind: Kind) -> Grid {
        guard let shape = Piece.shapes[kind] else {
            assert(false, "Failed to find shape for kind \(kind)")
        }

        assert(shape.count == Piece.size, "Invalid row count for shape")
        let grid = Grid(numColumns: Piece.size, numRows: Piece.size)

        for y in 0..<Piece.size {
            assert(shape[y].count == Piece.size, "Invalid row length for shape")
            for x in 0..<shape[y].count where shape[y][x] == "X" {
                grid[x, y] = Unit()
            }
        }

        return grid
    }

    // MARK: Public methods

    /// Traverses the Piece's rotated grid, calling the callback with x, y, value when there
    /// is a non-nil value for that (x, y) location.
    func traverse(callback: (_ x: Int, _ y: Int, _ unit: Unit) -> Void) {
        rotatedGrid.traverse(callback: callback)
    }

    /// Accesses the current rotation of the Piece's Grid
    subscript(x: Int, y: Int) -> Unit? {
        return rotatedGrid[x, y]
    }

    /// Returns an ascii art describing all the rotations (grids) for this piece
    func asciiArt() -> String {
        return grid.asciiArt()
    }

    // MARK: Initializers

    /// Creates a new Piece for a given type.
    init(kind: Kind) {
        self.kind = kind

        grid = Piece.parseShape(kind: kind)
        rotatedGrid = Grid(grid: grid)
    }
}
