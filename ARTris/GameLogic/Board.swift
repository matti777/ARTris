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
     Collapses all full rows (with no empty units).

     - returns number of rows collapsed
     */
    func collapseFullRows(removeUnitCallback: (Unit) -> Void, moveUnitCallback: (Unit, GridCoordinates) -> Void) -> Int {
        var unitsToRemove = [Unit]()
        var unitsToMove = [Unit: GridCoordinates]()
        var rowsCollapsed = 0

        func move(unit: Unit) {
            guard let coordinates = unitsToMove[unit] else {
                fatalError("Unit not found")
            }

            unitsToMove[unit] = (x: coordinates.x, y: coordinates.y + 1)
        }

        func willMove(unit: Unit, coordinates: GridCoordinates) {
            assert(unitsToMove[unit] == nil, "Must not have an unit already")

            unitsToMove[unit] = coordinates
        }

        func collapse(aboveRow: Int) {
            log.debug("collapsing aboveRow: \(aboveRow)")
            for y in (0..<aboveRow).reversed() {
                log.debug("dropping row \(y) on step down")
                for x in 0..<numColumns {
                    // Move the unit value at this location (x, y) one row down
                    // and clear the value ar this location
                    self[x, y + 1] = self[x, y]
                    self[x, y] = nil
                }
            }
        }

        // Scan all rows starting from the top of the board
        for y in 0..<numRows {
            var rowUnits = [Unit?](repeating: nil, count: numColumns)

            // Record the row contents into a auxiliary array - nil's also
            var units = 0
            for x in 0..<numColumns {
                if let unit = self[x, y] {
                    rowUnits[x] = unit
                    units += 1
                }
            }

            if units == numColumns {
                // This was a full row, it will be collapsed and everything above
                // it will be dropped down one line
                unitsToRemove.append(contentsOf: rowUnits.compactMap { $0 })
                unitsToMove.keys.forEach { move(unit: $0) }
                rowsCollapsed += 1

                // Move the board contents above this line down by 1
                collapse(aboveRow: y)
            } else {
                // This is not a full row; instead, it will get moved down by
                // any collapsing row beneath it
                for x in 0..<numColumns {
                    if let unit = rowUnits[x] {
                        willMove(unit: unit, coordinates: (x: x, y: y))
                    }
                }
            }
        }

        if !unitsToRemove.isEmpty {
            unitsToRemove.forEach { removeUnitCallback($0) }
            unitsToMove.forEach { moveUnitCallback($0.0, $0.1) }
        }

        return rowsCollapsed
    }

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
