//
//  Board.swift
//  ARTris
//
//  Created by Matti Dahlbom on 28/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import Foundation

/**
 Represents the game board; contains logic dealing with how the pieces move
 on the board.
 */
class Board: Grid {
    /**
     Checks if another grid (a game piece) conflicts (both grids have a unit in the corresponding
     location) with the board. This method is used as brute-force collision detection
     between the active falling piece and the board.

     - parameter grid: the other grid
     - parameter location: the grid's coordinates on this board
     - returns true if there is a conflict
     */
    func conflicts(grid: Grid, location: GridCoordinates) -> Bool {
        return grid.traverse { x, y, _ in
            // Translate the other grid's (x, y) into this Board's coordinate space
            let pos = (x: x + location.x, y: y + location.y)

            // If the piece is over the top of the board, that is always fine
            if pos.y < 0 {
                return false
            }

            // Going over the left/right edges and the bottom is considered a
            // conflict; however, the piece grid being over the board's top is fine
            if (pos.x < 0) || (pos.x >= numColumns) || (pos.y >= numRows) {
                return true
            }

            if self[pos.x, pos.y] != nil {
                return true
            }

            return false
        }
    }

    /**
     Calculates the 'drop distance' ie. the amount of rows this piece can fall downwards
     without conflicting with (= hitting) another piece or the board bottom.

     - parameter grid: the other grid
     - parameter location: the grid's coordinates on this board
     - returns number of rows the grid can drop down
     */
    func dropDistance(grid: Grid, location: GridCoordinates) -> Int {
        var maxDistance = numRows + 1

        // Scan every column..
        for x in 0..<grid.numColumns {
            let boardX = location.x + x

            // We don't need to look at grid columns outside the board edges
            if (boardX < 0) || (boardX >= numColumns) {
                continue
            }

            // Traverse the grid's column bottom to up and find number of empty units at the bottom
            var gridEmptyUnits = 0
            for y in (0..<grid.numRows).reversed() {
                if grid[x, y] != nil {
                    break
                }
                gridEmptyUnits += 1
            }

            // If the whole grid column is empty, theres no collision there
            if gridEmptyUnits == grid.numRows {
                continue
            }

            // Traverse the corresponding column of the board and find the number of empty units from the top
            var boardEmptyUnits = 0
            for y in 0..<numRows {
                if self[boardX, y] != nil {
                    break
                }
                boardEmptyUnits += 1
            }

            let d = boardEmptyUnits - (location.y + grid.numRows) + gridEmptyUnits
            maxDistance = min(maxDistance, d)
        }

        return maxDistance
    }

    /// Constructs an empty board
    init() {
        super.init(numColumns: 10, numRows: 17) // slightly lower than standard tetris board
    }
}
