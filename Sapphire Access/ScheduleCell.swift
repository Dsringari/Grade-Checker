//
//  ScheduleCell.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 6/29/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class ScheduleCell: UITableViewCell {
    @IBOutlet var colorTab: UIView!
    @IBOutlet var period: UILabel!
    @IBOutlet var name: UILabel!
    @IBOutlet var teacher: UILabel!
    @IBOutlet var room: UILabel!
    @IBOutlet var time: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
