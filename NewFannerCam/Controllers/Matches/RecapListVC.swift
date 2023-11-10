//
//  RecapListVC.swift
//  NewFannerCam
//
//  Created by iMac on 30/09/20.
//  Copyright © 2020 fannercam3. All rights reserved.
//

import UIKit

class RecapListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var recapListTbl: UITableView!
    var hideWindow : Bool = false
    var arrRecap = [Recap]()
    var selectedMatch : SelectedMatch!
    var saveLiveRecapData : [String] = []
    var isLiverecap : Bool = false
    var videoQuality : Bool = false
    let defaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.selectedMatch.match.namePresentation()
        
        getRecapList()
  
        if self.appDelegate.loginWindow == nil {
            print("NIl")
//            dismiss(animated: true, completion: nil)
        }else {
            print("Not nil")
//            let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
//            navigationItem.leftBarButtonItem = backButton
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

            
            // Create a custom UIButton
            let backButton = UIButton(type: .custom)

            // Set the image for the button
            let backImage = UIImage(named: "ic_arrow_left_white") // Replace "backButtonImage" with the actual image name
            backButton.setBackgroundImage(backImage, for: .normal)

            // Set the frame size for the button

            // Add an action to the button
            backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

            // Create a UIBarButtonItem with the custom UIButton
            let customBackButton = UIBarButtonItem(customView: backButton)

            // Set the UIBarButtonItem as the navigation item's leftBarButtonItem
            navigationItem.leftBarButtonItem = customBackButton

        }
      
    }

    @objc func backButtonTapped() {
        // Dismiss the view controller
//        dismiss(animated: true, completion: nil)
        
        // Do any additional setup after loading the view.
        if self.appDelegate.loginWindow == nil {
            print("NIl")
//            dismiss(animated: true, completion: nil)
        }else {
            print("Not nil")
            self.appDelegate.loginWindow.isHidden = true
            self.appDelegate.secondWindow?.isHidden = false
            
        }
    }
    
    func getRecapList()
    {
        let strUrl: String = getServerBaseUrl() + getRecapListURL() + "\(customerId)"
        let postParam = [:] as [String : Any]
        let oWebManager: AlamofireManager = AlamofireManager()
        oWebManager.requestPost(strUrl, parameters: postParam) { (jsonResult) in
            if let error = jsonResult["error"] as? String
            {
                print(error)
                return
            }else{
                
                
                if let entities = jsonResult["entities"] as? [NSDictionary] {
                    for objEntity in entities {
                        var objRecap = Recap()
                        objRecap.recapId = objEntity["recapId"] as? Int
                        objRecap.recapTitle = objEntity["recapTitle"] as? String
                        self.arrRecap.append(objRecap)
                    }
                    self.getLiveRecapList()
                    
                    self.defaults.set(true, forKey: "isEmptyRecapList")

                    // Synchronize the UserDefaults to save the changes immediately (optional)
                    self.defaults.synchronize()
                    
                } else {
                    print("No 'entities' array found in the JSON response.")
                    // Handle this situation as needed.
                    // Get a reference to the UserDefaults standard instance
                   
                    //Recapcaplist = Nil
//                    // Set a Boolean value
//                    self.defaults.set(false, forKey: "isEmptyRecapList")
//
//                    // Synchronize the UserDefaults to save the changes immediately (optional)
//                    self.defaults.synchronize()
//
//                    self.alertView()
                }
                
                //old code
//                let entities = jsonResult["entities"] as! [NSDictionary]
//
//                for objEntity in entities {
//                    var objRecap = Recap()
//                    objRecap.recapId = objEntity["recapId"] as? Int
//                    objRecap.recapTitle = objEntity["recapTitle"] as? String
//
//                    self.arrRecap.append(objRecap)
//                }
//
//                self.getLiveRecapList()
                
            }
        }
    }
  
    //Recapcaplist = Nil
//    func alertView() {
//        appDelegate.secondWindow?.isHidden = true
//        let alert = UIAlertController(title: "Alert", message: "Server error", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//            switch action.style{
//                case .default:
//                print("default")
////                self.appDelegate.secondWindow?.isHidden = false
//                self.navigationController?.popViewController(animated: true)
//                case .cancel:
//                print("cancel")
//                case .destructive:
//                print("destructive")
//            }
//        }))
//        self.present(alert, animated: true, completion: nil)
//    }
    
    func getLiveRecapList()
    {
        let strUrl: String = getServerBaseUrl() + getLiveRecapListURL() + "\(customerId)"
        let oWebManager: AlamofireManager = AlamofireManager()
        oWebManager.requestGet(strUrl) { (jsonResult) in
            if let error = jsonResult["error"] as? String
            {
                print(error)
                return
            }else{
                
                let entities = jsonResult["entities"] as! [NSDictionary]
                
                for objEntity in entities {
                    var objRecap = Recap()
                    objRecap.recapId = objEntity["recapId"] as? Int
                    objRecap.recapTitle = objEntity["recapTitle"] as? String
                    
                    self.arrRecap.append(objRecap)
                }
                
                self.recapListTbl.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrRecap.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecapListCell", for: indexPath) as! RecapListCell
        cell.recapClipLbl.text = arrRecap[indexPath.row].recapTitle
                
        let recapId = UserDefaults.standard.integer(forKey: selectedMatch.match.id)
        if arrRecap[indexPath.row].recapId == recapId
        {
            cell.accessoryType = .checkmark
            cell.tintColor = UIColor.white
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
        print(self.arrRecap)
        // Deselect the selected row if needed
        
        let recapId = arrRecap[indexPath.row].recapId
        print(recapId)
        let match_id = self.selectedMatch.match.id
        
        UserDefaults.standard.setValue(recapId, forKey: match_id)
        UserDefaults.standard.synchronize()
        
        navigationController?.popViewController(animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
  
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        alert.modalPresentationStyle = .popover
        let popover = alertController.popoverPresentationController
        popover?.sourceView = tableView.cellForRow(at: indexPath)
        popover?.sourceRect = tableView.rectForRow(at: indexPath)
        popover?.delegate = self
        
        
        
        let highAction = UIAlertAction(title: ActionTitle.standarQuality.rawValue, style: .default) { (highAction) in
            
//            self.createClipsForLiverecap(true, generator)
                    
           
            self.isLiverecap = true
            self.videoQuality = true
            
            self.saveLiveRecapData = ["\(self.isLiverecap)" , "\(self.videoQuality)", "\(recapId!)" , ]
            self.defaults.set(self.saveLiveRecapData, forKey: "Liverecap")
            
       

            if self.hideWindow == false {

                self.appDelegate.loginWindow.isHidden = true
                self.appDelegate.secondWindow?.isHidden = false
            } else {
//                self.appDelegate.loginWindow.isHidden = true
                self.appDelegate.secondWindow?.isHidden = true
            }
           
        }
        let meAction = UIAlertAction(title: ActionTitle.webQuality.rawValue, style: .default) { (meAction) in
    

            self.isLiverecap = true
            self.videoQuality = false
            
            self.saveLiveRecapData = ["\(self.isLiverecap)" , "\(self.videoQuality)", "\(recapId!)" ]
            self.defaults.set(self.saveLiveRecapData, forKey: "Liverecap")
         

            if self.hideWindow == false {

                self.appDelegate.loginWindow.isHidden = true
                self.appDelegate.secondWindow?.isHidden = false
            }
            
    
        }
        alertController.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
        alertController.addAction(highAction)
        alertController.addAction(meAction)
//             if let presenter = alert.popoverPresentationController {
//                 presenter.sourceView = sender
//                 presenter.sourceRect = sender.bounds
//             }
//        self.present(alert, animated: true, completion: nil)
        present(alertController, animated: true, completion: nil)
        
    }
    
//    {
//
//
//        let recapId = arrRecap[indexPath.row].recapId
//        let match_id = self.selectedMatch.match.id
//
//        UserDefaults.standard.setValue(recapId, forKey: match_id)
//        UserDefaults.standard.synchronize()
//
//        if hideWindow == false {
//
//            self.appDelegate.loginWindow.isHidden = true
//            self.appDelegate.secondWindow?.isHidden = false
//        }
//
//        navigationController?.popViewController(animated: true)
//    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
        label.textAlignment = .center
        label.text = "Choose recap"
        label.textColor = UIColor.white
        view.addSubview(label)
        return view
    }
    
    @IBAction func onBackBtn(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }    
}
