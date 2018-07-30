//
//  Game.swift
//  ARTris
//
//  Created by Matti Dahlbom on 21/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import UIKit

/**
 Contains the high-level game logic.
 */
class Game {
    /// Game board
    private(set) var board = Board()

    /// Current 'falling' (interactive) piece
    private var fallingPiece: Piece?

    /// Callback for adding new unit node geometry. Must define.
    private var addGeometryCallback: (UIColor, GridCoordinates) -> AnyObject

    /// Starts a new game.
    func start() {
        fallingPiece = Piece(type: .i)
        log.debug("Piece:\n\(fallingPiece!.asciiArt())")
    }

    /// Creates a new game
    init(addGeometryCallback: @escaping ((UIColor, GridCoordinates) -> AnyObject)) {
        self.addGeometryCallback = addGeometryCallback
    }
}
