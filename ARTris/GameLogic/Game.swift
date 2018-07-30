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

    /// Game tick timer; at each tick, the current 'falling' piece drops down one row
    private var timer: Timer!

    /// Current 'falling' (interactive) piece
    private var fallingPiece: Piece!

    /// Location (on the Board) of the falling piece
    private var fallingPieceCoordinates: GridCoordinates!

    /// Callback for adding new unit node geometry. Must define.
    private var addGeometryCallback: (UIColor, GridCoordinates) -> AnyObject

    // MARK: Private methods

    func newFallingPiece() {
        //TODO random type
        fallingPiece = Piece(kind: .i)
        log.debug("Piece:\n\(fallingPiece!.asciiArt())")

        // Place the piece in the middle of the board in x-direction, and just above the top
        fallingPieceCoordinates = (x: (board.numColumns - Piece.size) / 2, y: -(Piece.size - fallingPiece.bottomMargin))

        // Send a 'add geometry' callback for each unit of the new piece, by translating
        // their coordinates into the Board coordinate space
        fallingPiece.traverse { [weak self] x, y, unit in
            let boardCoordinates = (x: x + fallingPieceCoordinates.x, y: y + fallingPieceCoordinates.y)
            unit.object = self?.addGeometryCallback(Piece.colors[fallingPiece.kind]!, boardCoordinates)
        }
    }

    // MARK: Public methods

    /// Starts a new game.
    func start() {
        // Allocate the first falling piece
        newFallingPiece()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            log.debug("tick tock")
            //TODO
        }
    }

    // MARK: Initializers

    /// Creates a new game
    init(addGeometryCallback: @escaping ((UIColor, GridCoordinates) -> AnyObject)) {
        self.addGeometryCallback = addGeometryCallback
    }
}
