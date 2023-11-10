//
//  AddSportMarkersVC.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 05/07/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//

import UIKit


class AddSportMarkersVC: UIViewController {

    @IBOutlet weak var tfDuration: UITextField!
    @IBOutlet weak var tfTagName: UITextField!
    
    weak var delegate: SecondViewControllerDetailsDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tfDuration.addTarget(self, action: #selector(limitTextLength), for: .editingChanged)
    }
    
    @objc func limitTextLength() {
        if let text = tfDuration.text, text.count > 3 {
            tfDuration.text = String(text.prefix(3))
        }
    }
    
    @IBAction func saveBtn(_ sender: UIButton) {
      
        // Check if the sport name is empty or contains only whitespace characters
        guard let enteredSportName = tfTagName.text?.trimmingCharacters(in: .whitespacesAndNewlines), !enteredSportName.isEmpty else {
            MessageBarService.shared.warning("Sport name is required!")
            return
        }

        // Check if the duration is empty or not a valid number
        guard let durationText = tfDuration.text?.trimmingCharacters(in: .whitespacesAndNewlines), !durationText.isEmpty, let duration = Int(durationText), duration >= 0 && duration <= 350 else {
            MessageBarService.shared.warning("Duration must be a number between 0 and 350.")
            return
        }

        // If both inputs are valid, pass the data to the delegate and dismiss the view controller
        delegate?.didFinishPassingDetailsData(enteredSportName, tagDuration: durationText)
        navigationController?.dismiss(animated: true, completion: nil)
        /*

//    }
//    @IBAction func saveAddedMarker(_ sender: UIBarButtonItem) {
        guard tfTagName.text?.count != 0 else {
            MessageBarService.shared.warning("sport name is required!")
            return
        }
        guard let enteredSport = tfTagName.text?.trimmingCharacters(in: .whitespacesAndNewlines), !enteredSport.isEmpty else {
               return
           }

        guard tfDuration.text?.count != 0 else {
            MessageBarService.shared.warning("sport name is required!")
            return
        }
        guard let enteredSport = tfDuration.text?.trimmingCharacters(in: .whitespacesAndNewlines), !enteredSport.isEmpty else {
               return
           }

        delegate?.didFinishPassingDetailsData(tfTagName.text!, tagDuration: tfDuration.text!)
//        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
         */
    }
    

}
