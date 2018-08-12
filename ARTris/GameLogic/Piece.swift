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
    typealias RotationFunc = (_ x: Int, _ y: Int) -> (x: Int, y: Int)

    /// Piece ('tetromino') types.
    enum Kind {
        case square, i, l, inverseL, s, inverseS
    }

    /// Defines all the 4 rotations the pieces can be in
    enum Rotation: Int {
        case deg0 = 0, deg90, deg180, deg270
    }

    /// Size (side length) for all pieces
    static let size = 4

    /// All Kinds
    static let kinds: [Kind] = [.square, .i, .l, .inverseL, .s, .inverseS]

    /// All the rotations in order; traversing the array using an ascending index
    /// goes through the rotations in clockwise order.
    static let rotations: [Rotation] = [.deg0, .deg90, .deg180, .deg270]

    /// Defines mapping between rotation constants and their respective coordinate transform functions
    private static let rotationFuncs: [Rotation: RotationFunc?] = [
        .deg0: nil,
        .deg90: { x, y in return (Piece.size - 1 - y, x) },
        .deg180: { x, y in return (Piece.size - 1 - x, Piece.size - 1 - y) },
        .deg270: { x, y in return (y, Piece.size - 1 - x) }
    ]

    /// Piece colors map
    static let colors: [Kind: UIColor] = [
        .square: UIColor(hexString: "#2DFEFE"),
        .i: UIColor(hexString: "#FD29FC"),
        .l: UIColor(hexString: "#FDA429"),
        .inverseL: UIColor(hexString: "#7F25FB"),
        .s: UIColor(hexString: "#7F25FB"),
        .inverseS: UIColor(hexString: "#7F7F17")
    ]

    /// Type of this piece
    var kind: Kind

    /// Representational grid for this piece. This is effectively the rotated grid.
    var grid: Grid {
        return rotatedGrid
    }

    /// Piece as a Grid, in 0-degree rotation
    private var originalGrid: Grid

    // Piece as a Grid, in its current rotation
    private var rotatedGrid: Grid

    /// Current rotation (index to the rotations -array)
    var rotationIndex = 0

    /// Margins of the current rotated grid
    var margins: GridMargins!

    // All the piece shapes (in their 0-degree rotation) in parseable ascii art format
    private static let shapes: [Kind: [String]] = [
        .square: ["....",
                  ".XX.",
                  ".XX.",
                  "...."],
        .i: [".X..",
             ".X..",
             ".X..",
             ".X.."],
        .l: [".X..",
             ".X..",
             ".XX.",
             "...."],
        .inverseL: ["..X.",
                    "..X.",
                    ".XX.",
                    "...."],
        .s: ["....",
             ".XX.",
             "XX..",
             "...."],
        .inverseS: ["....",
                    ".XX.",
                    "..XX",
                    "...."]
    ]

    /// Creates a new Grid for a given piece type.
    private static func parseShape(kind: Kind) -> Grid {
        guard let shape = Piece.shapes[kind] else {
            fatalError("Failed to find shape for kind \(kind)")
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

    /// Sets the current rotation of the piece
    func setRotation(rotationIndex: Int, rotatedGrid: Grid) {
        assert((rotationIndex >= 0) && (rotationIndex < Piece.rotations.count), "Bad rotationIndex")

        self.rotationIndex = rotationIndex
        self.rotatedGrid = rotatedGrid
        self.margins = rotatedGrid.margins()
    }

    /// Gets a piece grid rotated by the specified rotation
    func rotated(rotation: Rotation) -> Grid {
        let rotatedGrid = Grid(numColumns: originalGrid.numColumns, numRows: originalGrid.numRows)
        guard let rotateFunc = Piece.rotationFuncs[rotation] as? RotationFunc else {
            // For .deg0 this is identity function; just return the original grid
            return originalGrid
        }

        originalGrid.traverse { x, y, unit -> Void in
            let (rx, ry) = rotateFunc(x, y)
            rotatedGrid[rx, ry] = unit
        }

        return rotatedGrid
    }

    /// Traverses the Piece's rotated grid, calling the callback with x, y, value when there
    /// is a non-nil value for that (x, y) location.
    func traverse(callback: (_ x: Int, _ y: Int, _ unit: Unit) -> Void) {
        rotatedGrid.traverse(callback: callback)
    }

    /// Accesses the current rotation of the Piece's Grid
    subscript(x: Int, y: Int) -> Unit? {
        return grid[x, y]
    }

    /// Returns an ascii art describing all the rotations (grids) for this piece
    func asciiArt() -> String {
        return grid.asciiArt()
    }

    // MARK: Initializers

    /// Creates a new Piece for a given type.
    init(kind: Kind) {
        self.kind = kind

        originalGrid = Piece.parseShape(kind: kind)
        rotatedGrid = Grid(grid: originalGrid)

        setRotation(rotationIndex: rotationIndex, rotatedGrid: rotatedGrid)
    }
}
