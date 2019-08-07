//
//  ScoreView.swift
//  ARTris
//
//  Created by Matti Dahlbom on 07/08/2018.
//  Copyright © 2018 Matti Dahlbom. All rights reserved.
//

import UIKit

/**
 This view is used to render the scoreboard texture.
 */
class ScoreView: UIView {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var scoreLabel: UILabel!

    /// Our text attributes
    private let strokeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.white,
        NSAttributedString.Key.foregroundColor: UIColor.red,
        NSAttributedString.Key.strokeWidth: -2.0]

    /// Updates the score
    func update(score: Int) {
        scoreLabel.attributedText = NSAttributedString(string: "\(score)", attributes: strokeTextAttributes)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.attributedText = NSAttributedString(string: "Score:", attributes: strokeTextAttributes)
        update(score: 0)
    }
}
