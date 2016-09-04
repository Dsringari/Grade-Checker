//
//  SubjectTableViewCell.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/21/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class SubjectTableViewCell: UITableViewCell {
    @IBOutlet var subjectNameLabel: UILabel!
    @IBOutlet var percentGradeLabel: UILabel!
    @IBOutlet var lastUpdatedLabel: UILabel!
    @IBOutlet var badge: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
