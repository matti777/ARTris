//
//  PieceTessts.swift
//  ARTrisTests
//
//  Created by Matti Dahlbom on 31/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import XCTest

//@testable import ARTris

class PieceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLoading() {
        let expected = [".#..",
                        ".#..",
                        ".#..",
                        ".#.."]

        let piece = Piece(kind: .i)
        let ascii = piece.asciiArt()
        XCTAssert(ascii == expected.joined(separator: "\n"))
    }

    func testLRotation() {
        let expected0 = [".#..",
                         ".#..",
                         ".##.",
                         "...."]
        let expected90 = ["....",
                          ".###",
                          ".#..",
                          "...."]
        let expected180 = ["....",
                           ".##.",
                           "..#.",
                           "..#."]
        let expected270 = ["....",
                           "..#.",
                           "###.",
                           "...."]
        let piece = Piece(kind: .l)
        let rotated1 = piece.rotated(rotation: .deg0)
        print("\(rotated1.asciiArt())\n")
        XCTAssert(rotated1.asciiArt() == expected0.joined(separator: "\n"))
        let rotated2 = piece.rotated(rotation: .deg90)
        print("\(rotated2.asciiArt())\n")
        XCTAssert(rotated2.asciiArt() == expected90.joined(separator: "\n"))
        let rotated3 = piece.rotated(rotation: .deg180)
        print("\(rotated3.asciiArt())\n")
        XCTAssert(rotated3.asciiArt() == expected180.joined(separator: "\n"))
        let rotated4 = piece.rotated(rotation: .deg270)
        print("\(rotated4.asciiArt())\n")
        XCTAssert(rotated4.asciiArt() == expected270.joined(separator: "\n"))
    }

    func testSRotation() {
        let expected0 = ["....",
                         ".##.",
                         "##..",
                         "...."]
        let expected90 = [".#..",
                          ".##.",
                          "..#.",
                          "...."]
        let expected180 = ["....",
                           "..##",
                           ".##.",
                           "...."]
        let expected270 = ["....",
                           ".#..",
                           ".##.",
                           "..#."]
        let piece = Piece(kind: .s)
        let rotated1 = piece.rotated(rotation: .deg0)
        print("\(rotated1.asciiArt())\n")
        XCTAssert(rotated1.asciiArt() == expected0.joined(separator: "\n"))
        let rotated2 = piece.rotated(rotation: .deg90)
        print("\(rotated2.asciiArt())\n")
        XCTAssert(rotated2.asciiArt() == expected90.joined(separator: "\n"))
        let rotated3 = piece.rotated(rotation: .deg180)
        print("\(rotated3.asciiArt())\n")
        XCTAssert(rotated3.asciiArt() == expected180.joined(separator: "\n"))
        let rotated4 = piece.rotated(rotation: .deg270)
        print("\(rotated4.asciiArt())\n")
        XCTAssert(rotated4.asciiArt() == expected270.joined(separator: "\n"))
    }
}
