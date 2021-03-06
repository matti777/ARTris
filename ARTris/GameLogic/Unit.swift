//
//  PieceFragment.swift
//  ARTris
//
//  Created by Matti Dahlbom on 20/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import UIKit

/**
 Represents a 1-dimensional unit ("square") of a game piece. All game pieces
 are formed by a Grid-ful of Units.

 A Unit is not aware of it's position, only of it's color and a related object.
 Its positional information is stored in a Grid.
 */
class Unit: Hashable {
    var object: AnyObject!

    static func ==(lhs: Unit, rhs: Unit) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
//    var hashValue: Int {
//        return ObjectIdentifier(self).hashValue
//    }
}
