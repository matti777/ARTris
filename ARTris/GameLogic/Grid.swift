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

 Both the game board and the falling piece are represented by a Grid. The data
 is organized so that greater column number -> right, greater row number -> down.

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

    private func checkIndexRanges(x: Int, y: Int) -> Bool {
        return (y >= 0) && (y < numRows) && (x >= 0) && (x < numColumns)
    }

    // MARK: Public methods

    /**
     Traverses the entire grid, calling the callback with x, y, value when there
     is a non-nil value for that (x, y) location.

     - parameter callback: closure to be called for each non-nil unit in the grid. Whatever
     this closure returns, this method will return.
     - returns whatever the callback returned
     */
    @discardableResult
    func traverse(callback: (_ x: Int, _ y: Int, _ unit: Unit) -> Any) -> Any {
        for y in 0..<numRows {
            for x in 0..<numColumns {
                if let unit = self[x, y] {
                    return callback(x, y, unit)
                }
            }
        }

        return 0
    }

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
    subscript(x: Int, y: Int) -> Unit? {
        get {
            assert(checkIndexRanges(x: x, y: y), "Index out of range")
            return data[(y * numColumns) + x]
        }

        set {
            assert(checkIndexRanges(x: x, y: y), "Index out of range")
            data[(y * numColumns) + x] = newValue
        }
    }

    // MARK: Initializers

    /// Creates a copy of another grid
    init(grid: Grid) {
        self.numColumns = grid.numColumns
        self.numRows = grid.numRows

        self.data = [Unit?](repeating: nil, count: numRows * numColumns)
        for (i, value) in grid.data.enumerated() {
            self.data[i] = value
        }
    }

    /// Creates an empty grid
    init(numColumns: Int, numRows: Int) {
        self.numColumns = numColumns
        self.numRows = numRows

        self.data = [Unit?](repeating: nil, count: numRows * numColumns)
    }
}
