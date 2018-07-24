//
//  MenuViewController.swift
//  ARTris
//
//  Created by Matti Dahlbom on 20/07/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import UIKit

import QvikSwift

/** Displays the game main menu. */
class MenuViewController: UIViewController {
    private static let segueIdMenuToGame = "artris.MenuToGame"

    @IBOutlet private var startButton: UIButton!

    // MARK: IBAction handlers

    @IBAction func startButtonPressed(sender: UIButton) {
        log.debug("Starting a new game.")

        performSegue(withIdentifier: MenuViewController.segueIdMenuToGame, sender: nil)
    }

    // MARK: Lifecycle etc.

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        startButton.layer.cornerRadius = startButton.height / 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
