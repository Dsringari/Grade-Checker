//
//  TouchIDSelectionCell.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/27/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class TouchIDSelectionCell: UITableViewCell {
    @IBOutlet var touchIDSwitch: UISwitch!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
