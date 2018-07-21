//
//  Game.swift
//  ARTris
//
//  Created by Matti Dahlbom on 21/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import Foundation

/**
 Contains the high-level game logic.
 */
class Game {
    /// Current 'falling' (interactive) piece
    private var fallingPiece: Piece?

    /// Starts a new game.
    func start() {
        fallingPiece = Piece(type: .i)
        log.debug("Piece:\n\(fallingPiece!.asciiArt())")
    }
}
