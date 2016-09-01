//
//  ProfileStudentCell.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/1/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class ProfileStudentCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var gradeLabel: UILabel!
    @IBOutlet var schoolLabel: UILabel!
    @IBOutlet var picture: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
