//
//  SubjectOptionCell.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 1/24/17.
//  Copyright © 2017 Dhruv Sringari. All rights reserved.
//

import UIKit

class SubjectOptionCell: UITableViewCell {

    @IBOutlet var name: UILabel!
    @IBOutlet var textField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
