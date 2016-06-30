//
//  AssignmentTableViewCell.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/26/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class AssignmentTableViewCell: UITableViewCell {
    @IBOutlet var assignmentNameLabel: UILabel!
    @IBOutlet var pointsGradeLabel: UILabel!
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
