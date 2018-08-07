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
    private let strokeTextAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.strokeColor: UIColor.white,
        NSAttributedStringKey.foregroundColor: UIColor.red,
        NSAttributedStringKey.strokeWidth: -30.0]

    /// Updates the score
    func update(score: Int) {
        titleLabel.attributedText = NSAttributedString(string: "\(score)", attributes: strokeTextAttributes)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.attributedText = NSAttributedString(string: "Score:", attributes: strokeTextAttributes)
        update(score: 0)
    }
}