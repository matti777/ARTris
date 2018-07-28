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

    /// Constructs an empty board
    init() {
        super.init(numColumns: 10, numRows: 20) // standard tetris board
    }
}
