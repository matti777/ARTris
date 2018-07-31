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

     - parameter other: the other grid
     - parameter location: this grid's coordinates on the other grid
     - returns true if there is a conflict
     */
    func conflicts(other: Grid, location: GridCoordinates) -> Bool {
        return other.traverse { x, y, _ in
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

    /// Constructs an empty board
    init() {
        super.init(numColumns: 10, numRows: 20) // standard tetris board
    }
}
