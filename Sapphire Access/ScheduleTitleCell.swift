//
//  ScheduleTitleCell.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 6/30/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class ScheduleTitleCell: UITableViewCell {
    
    @IBOutlet var date: UILabel!
    @IBOutlet var letterDay: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}