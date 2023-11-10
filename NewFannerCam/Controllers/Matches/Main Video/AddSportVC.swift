//
//  AddSportVC.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 28/06/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//

import UIKit

class AddSportVC: UIViewController {

    @IBOutlet weak var tfSportName: UITextField!
      var enteredSport: String?
    weak var delegate: SecondViewControllerDelegate?
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        // Do any additional setup after loading the view.
    }
    

    @IBAction func saveBtnAdd(_ sender: UIButton) {

        guard tfSportName.text?.count != 0 else {
            MessageBarService.shared.warning("sport name is required!")
            return
        }
        guard let enteredSport = tfSportName.text?.trimmingCharacters(in: .whitespacesAndNewlines), !enteredSport.isEmpty else {
               return
           }
        delegate?.didFinishPassingData(tfSportName.text!)
//        navigationController?.popViewController(animated: true)
        navigationController?.dismiss(animated: true, completion: nil)
    
    }
    
    @IBAction func backBtnClick(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)

    }
}
