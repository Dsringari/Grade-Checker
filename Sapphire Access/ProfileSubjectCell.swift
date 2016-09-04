//
//  ProfileSubjectCell.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 7/31/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class ProfileSubjectCell: UITableViewCell {
    @IBOutlet var name: UILabel!
    @IBOutlet var percentGrade: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
