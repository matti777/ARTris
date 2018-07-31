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
    /// Types of piece movement by user interaction
    enum Move: Int {
        case left = -1, right = 1
    }

    /// Types of piece rotation by user interaction
    enum Rotate {
        case clockwise, counterclockwise
    }

    /// Game board
    private(set) var board = Board()

    /// Game tick timer; at each tick, the current 'falling' piece drops down one row
    private var timer: Timer!

    /// Current 'falling' (interactive) piece
    private var piece: Piece!

    /// Location (on the Board) of the falling piece
    private var pieceCoordinates: GridCoordinates!

    /// Callback for adding new unit node geometry
    var addGeometryCallback: ((UIColor, GridCoordinates) -> AnyObject)!

    /// Callback for moving existing geometry to new position
    var moveGeometryCallback: ((AnyObject, GridCoordinates) -> Void)!

    /// Callback for Game Over
    var gameOverCallback: (() -> Void)!

    // MARK: Private methods

    /**
     Traverses the current piece and provides also the translated board coordinates.

     See also: `Grid.traverse()`
     */
    func traversePiece(callback: (_ x: Int, _ y: Int, _ boardX: Int, _ boardY: Int, _ unit: Unit) -> Void) {
        piece.traverse { x, y, unit in
            callback(x, y, pieceCoordinates.x + x, pieceCoordinates.y + y, unit)
        }
    }

    /// Allocates a new random falling piece and positions it on the top of the board
    func newFallingPiece() {
        // Pick a random piece kind (tetromino type)
        let kind = Piece.kinds[Int.random(UInt32(Piece.kinds.count))]
        piece = Piece(kind: kind)
        log.debug("New falling piece:\n\(piece!.asciiArt())")

        // Place the piece in the middle of the board in x-direction, and just above the top
        pieceCoordinates = (x: (board.numColumns - Piece.size) / 2, y: -(Piece.size - piece.margins.bottom))

        // Send a 'add geometry' callback for each unit of the new piece, by translating
        // their coordinates into the Board coordinate space
        traversePiece { x, y, boardX, boardY, unit in
            unit.object = self.addGeometryCallback(Piece.colors[piece.kind]!, (x: boardX, y: boardY))
        }
    }

    /**
     Checks if the piece could be moved by the given (x, y) deltas

     - parameter x: amount to move along the x axis
     - parameter y: amount to move along the y axis
     - returns true if the move is ok
    */
    func canMoveBy(x: Int, y: Int) -> Bool {
        let newPosition = (x: pieceCoordinates.x + x, y: pieceCoordinates.y + y)
        return !board.conflicts(other: piece.grid, location: newPosition)
    }

    /// Advances the falling of the current piece; checks if the piece has come to a
    /// stop and if so, either decides its game over (piece lands partly or entirely
    /// Outside the Board) or that the piece becodes static part of the board and a new
    /// falling piece should be allocated.
    func timerTick() {
        // Check if we can move one row down
        if !canMoveBy(x: 0, y: 1) {
            // Check for 'game over'; that is, if the piece landed even partly over the top of the board
            if (pieceCoordinates.y + piece.margins.top) < 0 {
                log.debug("** GAME OVER **")
                timer.invalidate()
                timer = nil
                gameOverCallback()
                return
            }

            // The piece has 'landed' ie. it will become static part of the board.
            traversePiece { x, y, boardX, boardY, unit in
                assert(board[boardX, boardY] == nil, "There should not be a unit there")
                board[boardX, boardY] = unit
            }
            log.debug("Piece has landed.")

            // Trigger new falling piece allocation
            newFallingPiece()

            //TODO check for collapsing rows
        } else {
            pieceCoordinates.y += 1
            log.debug("Piece fall advanced to \(pieceCoordinates)")

            // Trigger piece movement in the visuals
            traversePiece { x, y, boardX, boardY, unit in
                moveGeometryCallback(unit.object, (x: boardX, y: boardY))
            }
        }
    }

    // MARK: Public methods

    /// (Attempts to) moves the piece left or right, from user interaction.
    func movePiece(direction: Move) {
        log.debug("Move piece: \(direction)")

        if canMoveBy(x: direction.rawValue, y: 0) {
            pieceCoordinates.x += direction.rawValue
            log.debug("Piece moved to \(pieceCoordinates)")

            // Trigger piece movement in the visuals
            traversePiece { x, y, boardX, boardY, unit in
                moveGeometryCallback(unit.object, (x: boardX, y: boardY))
            }
        }
    }

    /// (Attempts to) rotate the piece, from user interaction.
    func rotatePiece(direction: Rotate) {
        log.debug("Rotate piece: \(direction)")


        //TODO
    }

    /// Drop the piece down until it lands and stops.
    func dropPiece() {
        log.debug("Drop piece")
        //TODO
    }

    /// Starts a new game.
    func start() {
        // Allocate the first falling piece
        newFallingPiece()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            self?.timerTick()
        }
    }

    // MARK: Initializers

    /// Creates a new game
    init() {
    }
}
