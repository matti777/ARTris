//
//  Grid.swift
//  ARTris
//
//  Created by Matti Dahlbom on 20/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import Foundation

/**
 A Grid stores game pice Units to form a falling piece or parts of already
 fallen pieces ('static units').

 Both the game board and the falling piece are represented by a Grid.

 Grid contains collision detection logic.
 */
class Grid {
    /// Number of columns in the grid (width in Units)
    private(set) var numColumns: Int

    /// Number of rows in the grid (height in Units)
    private(set) var numRows: Int

    /// Grid data. A nil Unit in a location (x, y) means no Unit.
    /// Unit offset = y * numColumns + x
    var data: [Unit?]

    // MARK: Private methods

    private func checkIndexRanges(column: Int, row: Int) -> Bool {
        return (row >= 0) && (row < numRows) && (column >= 0) && (column < numColumns)
    }

    // MARK: Public methods

    /// Returns an ascii art describing the grid.
    func asciiArt() -> String {
        var s = ""

        for y in 0..<numRows {
            for x in 0..<numColumns {
                let value = (data[y * numColumns + x] != nil) ? "#" : "."
                s = "\(s)\(value)"
            }

            s = "\(s)\n"
        }

        return s
    }

    // MARK: Operator overloads

    /// Accesses the Grid data
    subscript(column: Int, row: Int) -> Unit? {
        get {
            assert(checkIndexRanges(column: column, row: row), "Index out of range")
            return data[(row * numColumns) + column]
        }

        set {
            assert(checkIndexRanges(column: column, row: row), "Index out of range")
            data[(row * numColumns) + column] = newValue
        }
    }

    // MARK: Initializers

    /// Creates an empty grid
    init(numColumns: Int, numRows: Int) {
        self.numColumns = numColumns
        self.numRows = numRows

        self.data = [Unit?](repeating: nil, count: numRows * numColumns)
    }
}
