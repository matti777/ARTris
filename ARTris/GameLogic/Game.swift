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
    enum Rotate: Int {
        case clockwise = 1, counterclockwise = -1
    }

    /// Score values for rows collapsed
    private let rowCollapseScores = [0, 10, 25, 40, 55]

    /// Game board
    private(set) var board = Board()

    /// Game tick timer; at each tick, the current 'falling' piece drops down one row
    private var timer: Timer?

    /// Current 'falling' (interactive) piece
    private var piece: Piece!

    /// Current game score
    private var score: Int = 0

    /// Number of pieces created
    private var piecesCreated: Int = 0

    /// Location (on the Board) of the falling piece
    private var pieceCoordinates: GridCoordinates!

    /// Callback for adding new unit node geometry
    var addGeometryCallback: ((UIColor, GridCoordinates) -> AnyObject)!

    /// Callback for moving existing geometry to new position
    var moveGeometryCallback: ((_ object: AnyObject, _ coordinates: GridCoordinates, _ animate: Bool) -> Void)!

    // Callback for removing collapsed geometry
    var removeGeometryCallback: ((_ object: AnyObject) -> Void)!

    /// Callback for score updated
    var scoreUpdatedCallback: ((_ newScore: Int) -> Void)!

    /// Callback for Game Over
    var gameOverCallback: (() -> Void)!

    // MARK: Private methods

    /// Invalidates any existing timer and starts a new one.
    private func resetTimer() {
        if let timer = timer {
            timer.invalidate()
        }

        // Calculate timer duration from the number of pieces created; each
        // makes the timer faster by an amount, up to a capped limit
        let cap = 200
        let capped = min(cap, piecesCreated)
        let interval = 0.5 - (Double(capped) * (0.4 / Double(cap)))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] timer in
            self?.timerTick()
        }
    }

    // MARK: Public methods

    /**
     Traverses the current piece and provides also the translated board coordinates.

     See also: `Grid.traverse()`
     */
    private func traversePiece(callback: (_ x: Int, _ y: Int, _ boardX: Int, _ boardY: Int, _ unit: Unit) -> Void) {
        piece.traverse { x, y, unit in
            callback(x, y, pieceCoordinates.x + x, pieceCoordinates.y + y, unit)
        }
    }

    /// Allocates a new random falling piece and positions it on the top of the board
    private func newFallingPiece() {
        // Pick a random piece kind (tetromino type)
        let kind = Piece.kinds[Int.random(UInt32(Piece.kinds.count))]
        piece = Piece(kind: kind)

        // Pick a random rotation for the piece
        let rotationIndex = Int.random(UInt32(Piece.rotations.count))
        let rotatedGrid = piece.rotated(rotation: Piece.Rotation(rawValue: rotationIndex)!)
        piece.setRotation(rotationIndex: rotationIndex, rotatedGrid: rotatedGrid)

        // Place the piece in the middle of the board in x-direction, and just above the top
        pieceCoordinates = (x: (board.numColumns - Piece.size) / 2, y: -(Piece.size - piece.margins.bottom))

        // Send a 'add geometry' callback for each unit of the new piece, by translating
        // their coordinates into the Board coordinate space
        traversePiece { x, y, boardX, boardY, unit in
            unit.object = self.addGeometryCallback(Piece.colors[piece.kind]!, (x: boardX, y: boardY))
        }

        piecesCreated += 1
    }

    /**
     Checks if the piece could be moved by the given (x, y) deltas

     - parameter x: amount to move along the x axis
     - parameter y: amount to move along the y axis
     - returns true if the move is ok
     */
    private func canMoveBy(x: Int, y: Int) -> Bool {
        let newPosition = (x: pieceCoordinates.x + x, y: pieceCoordinates.y + y)
        return !board.conflicts(grid: piece.grid, location: newPosition)
    }

    /// Handles piece 'landing' ie. coming to rest. Returns true if this caused a game
    /// over.
    @discardableResult
    private func pieceLanded() -> Bool {
        // Check for 'game over'; that is, if the piece landed even partly over the top of the board
        if (pieceCoordinates.y + piece.margins.top) < 0 {
            timer?.invalidate()
            gameOverCallback()
            return true
        }

        // The piece has 'landed' ie. it will become static part of the board.
        traversePiece { x, y, boardX, boardY, unit in
            assert(board[boardX, boardY] == nil, "There should not be a unit there")
            board[boardX, boardY] = unit
        }

        // Trigger new falling piece allocation
        newFallingPiece()

        // Check for full rows and collapse them
        let rowsCollapsed = board.collapseFullRows(removeUnitCallback: { unit in
            removeGeometryCallback(unit.object)
        }, moveUnitCallback: { unit, coordinates in
            moveGeometryCallback(unit.object, coordinates, true)
        })

        assert(rowsCollapsed >= 0 && rowsCollapsed <= 4, "Incorrect value")

        // Increase score
        score += 1 + rowCollapseScores[rowsCollapsed]
        scoreUpdatedCallback(score)
        return false
    }

    /// Advances the falling of the current piece; checks if the piece has come to a
    /// stop and if so, either decides its game over (piece lands partly or entirely
    /// Outside the Board) or that the piece becodes static part of the board and a new
    /// falling piece should be allocated.
    private func timerTick() {
        // Check if we can move one row down
        if !canMoveBy(x: 0, y: 1) {
            if pieceLanded() {
                // Game over - do not reset timer
                return
            }
        } else {
            pieceCoordinates.y += 1

            // Trigger piece movement in the visuals
            traversePiece { x, y, boardX, boardY, unit in
                moveGeometryCallback(unit.object, (x: boardX, y: boardY), false)
            }
        }

        resetTimer()
    }

    // MARK: Public methods

    /// (Attempts to) moves the piece left or right, from user interaction.
    func movePiece(direction: Move) {
        if canMoveBy(x: direction.rawValue, y: 0) {
            pieceCoordinates.x += direction.rawValue

            // Trigger piece movement in the visuals
            traversePiece { x, y, boardX, boardY, unit in
                moveGeometryCallback(unit.object, (x: boardX, y: boardY), false)
            }
        }
    }

    /// (Attempts to) rotate the piece, from user interaction.
    func rotatePiece(direction: Rotate) {
        var newRotationIndex = (piece.rotationIndex + direction.rawValue) % Piece.rotations.count
        if newRotationIndex < 0 {
            newRotationIndex = Piece.rotations.count - 1
        }
        let rotatedGrid = piece.rotated(rotation: Piece.Rotation(rawValue: newRotationIndex)!)

        if board.conflicts(grid: rotatedGrid, location: pieceCoordinates) {
            return
        }

        piece.setRotation(rotationIndex: newRotationIndex, rotatedGrid: rotatedGrid)

        // Move the visual pieces according to the new rotation
        traversePiece { x, y, boardX, boardY, unit in
            moveGeometryCallback(unit.object, (x: boardX, y: boardY), false)
        }
    }

    /// Drop the piece down until it lands and stops.
    func dropPiece() {
        let dropDistance = board.dropDistance(grid: piece.grid, location: pieceCoordinates)
        pieceCoordinates.y += dropDistance

        // Trigger piece movement in the visuals
        traversePiece { x, y, boardX, boardY, unit in
            moveGeometryCallback(unit.object, (x: boardX, y: boardY), true)
        }

        pieceLanded()
    }

    /// Starts a new game.
    func start() {
        score = 0
        piecesCreated = 0
        scoreUpdatedCallback(score)

        // Allocate the first falling piece
        newFallingPiece()

        // Start the game tick timer
        resetTimer()
    }
}
