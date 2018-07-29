//
//  Shapes.swift
//  ARTris
//
//  Created by Matti Dahlbom on 20/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import Foundation

/**
 Represents the different game piece shapes. All the game shapes are 4x4 Grids.
 */
class Shape {
    /// All the shapes and all their rotations
    private static let matrices: [PieceType: [[String]]] = [
        .square: [ // 'square' piece
            ["....",
             ".XX.",
             ".XX.",
             "...."]
        ],
        .i: [ // 'I' piece
            [".X..",
             ".X..",
             ".X..",
             ".X.."],
            ["....",
             "XXXX",
             "....",
             "...."]
        ]
    ]

    /// Creates a new Grid for a given piece type.
    static func createGrids(type: PieceType) -> [Grid] {
        guard let matrices = Shape.matrices[type] else {
            assert(false, "Failed to find shape for type \(type)")
        }

        let grids = (0..<numRotations).map { rotation -> Grid in
            let index = rotation % matrices.count
            let m = matrices[index]
            assert(m.count == 4, "Invalid row count for shape")
            let grid = Grid(numColumns: 4, numRows: 4)

            for y in 0..<4 {
                let s = m[y]
                assert(s.count == 4, "Invalid row length for shape")
                for x in 0..<s.count where s[x] == "X" {
                    grid[x, y] = Unit(type: type)
                }
            }

            return grid
        }

        return grids
    }
}
