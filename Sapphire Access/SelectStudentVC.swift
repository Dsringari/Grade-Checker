//
//  SelectStudentVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/12/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import MagicalRecord
import LocalAuthentication

class SelectStudentVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet var tableView: UITableView!
	var touchIDSwitch: UISwitch!
	var students: [Student]!
	var selectedIndex: Int?
    var hasTouchID = false

    @IBOutlet var continueButton: UIButton!
	override func viewDidLoad() {
		super.viewDidLoad()

        hasTouchID = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

		students = Student.mr_findAll() as! [Student]

		if (students.count == 1) {
			selectedIndex = 0
		}

		students.sort(by: { (s1, s2) -> Bool in

			if let g1 = s1.grade, let g2 = s2.grade {
				return g1 > g2
			} else if (s1.grade == nil) {
				return true
			} else {
				return false
			}

		})

		if let name = UserDefaults.standard.string(forKey: "selectedStudent") {
			if let student = students.filter({ $0.name == name }).first {
				selectedIndex = students.index(of: student)
			}
		}

		tableView.delegate = self
		tableView.dataSource = self

        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        } else {
            // Fallback on earlier versions
        }
        willDisableContinueButton()
	}

    @IBAction func saveSettingsAndContinue(_ sender: AnyObject) {
        let settings = UserDefaults.standard

        if let index = selectedIndex {
            let student = students[index]
            settings.set(student.name, forKey: "selectedStudent")
        } else {
            User.mr_deleteAll(matching: NSPredicate(value: true))
            NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
        }

        if touchIDSwitch.isOn {
            let context = LAContext()
            context.localizedFallbackTitle = "" // Removes Enter Password Button
            self.continueButton.isEnabled = false
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Touch ID to Verify", reply: { (success: Bool, error: Error?) in
                DispatchQueue.main.async(execute: {
                    self.continueButton.isEnabled = true
                    if (success) {
                        settings.set(true, forKey: "useTouchID")
                        self.performSegue(withIdentifier: "firstTimeHome", sender: nil)
                    } else if let error = error as NSError? {
                        settings.set(false, forKey: "useTouchID")
                        self.touchIDSwitch.setOn(false, animated: true)
                        if error.code == LAError.Code.authenticationFailed.rawValue {
                            let failed = UIAlertController(title: "Failed to Verify", message: "Your fingerprint did not match.", preferredStyle: .alert)
                            let Ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                            failed.addAction(Ok)
                            self.present(failed, animated: true, completion: nil)
                        }
                    }
                })
            })
        } else {
            settings.set(false, forKey: "useTouchID")
            self.performSegue(withIdentifier: "firstTimeHome", sender: nil)
        }

    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 22
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 22))
		headerView.backgroundColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)

		let label = UILabel(frame: CGRect(x: 15, y: 0, width: self.view.frame.size.width - 15, height: 22))
		label.textColor = UIColor.white
		label.font = UIFont.systemFont(ofSize: 13)
		label.autoresizingMask = .flexibleWidth

		if section == 0 {
			label.text = "SELECT A STUDENT"
		} else {
			label.text = "TOUCH ID"
		}

		headerView.addSubview(label)
		return headerView
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if section == 0 {
			return UITableViewAutomaticDimension + 75
		}
		return 22
	}

	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		if section == 0 {
			let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 100))
			footerView.backgroundColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)

			let label = UILabel(frame: CGRect(x: 30, y: 0, width: self.view.frame.size.width - 30, height: 40))
			label.textColor = UIColor.white
			label.font = UIFont.systemFont(ofSize: 13)
			label.numberOfLines = 0
			label.text = "Select a student to view their grades. You can switch between them at anytime in the student tab."

			footerView.addSubview(label)
			return footerView
		}

		let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 22))
		footerView.backgroundColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)

		let label = UILabel(frame: CGRect(x: 30, y: 0, width: self.view.frame.size.width - 30, height: 22))
		label.textColor = UIColor.white
		label.font = UIFont.systemFont(ofSize: 13)
		label.autoresizingMask = .flexibleWidth
		label.text = "Touch ID may be used for a more secure login."

		footerView.addSubview(label)
		return footerView

	}

	func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
		if let footerView = view as? UITableViewHeaderFooterView {
			footerView.tintColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)
			footerView.textLabel?.textColor = UIColor.white
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return students.count
        }

		return 1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = UITableViewCell(style: .default, reuseIdentifier: "selectStudentCell")
			cell.textLabel?.text = students[indexPath.row].name

			if (indexPath.row == selectedIndex) {
				cell.accessoryType = .checkmark
			} else {
				cell.accessoryType = .none
			}
			cell.removeMargins()
			return cell
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "touchIDCell", for: indexPath) as! TouchIDSelectionCell
        cell.isUserInteractionEnabled = hasTouchID
        cell.textLabel?.isEnabled = hasTouchID
        cell.touchIDSwitch.isEnabled = hasTouchID
        cell.touchIDSwitch.isOn = hasTouchID
		cell.selectionStyle = .none
		touchIDSwitch = cell.touchIDSwitch
		return cell

	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if (indexPath.section == 0) {
			if let index = selectedIndex {
				tableView.cellForRow(at: IndexPath(row: index, section: 0))?.accessoryType = .none
			}
			tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
			selectedIndex = indexPath.row
		}

		tableView.deselectRow(at: indexPath, animated: true)
        willDisableContinueButton()
	}

    func willDisableContinueButton() {
        if (selectedIndex == nil) {
            continueButton.isEnabled = false
        } else {
            continueButton.isEnabled = true
        }
    }

	/*
	 // MARK: - Navigation

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	 // Get the new view controller using segue.destinationViewController.
	 // Pass the selected object to the new view controller.
	 }
	 */

}
