//
//  SceneKitUtils.swift
//  ARTris
//
//  Created by Matti Dahlbom on 29/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import SceneKit

/// Creates a colored SCNMaterial.
func createMaterial(_ color: UIColor) -> SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.isDoubleSided = true

    return material
}
