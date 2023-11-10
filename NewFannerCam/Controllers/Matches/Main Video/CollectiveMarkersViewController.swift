//
//  CollectiveMarkersViewController.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 28/06/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//

import UIKit

protocol SecondViewControllerDelegate: AnyObject {
    func didFinishPassingData(_ data: String)
}

class CollectiveMarkersViewController: UIViewController, SecondViewControllerDelegate {
    

    var typeCollection : Bool = false
    var editedIndexPath: IndexPath?
    var editedMarker: Marker?
   
    var indexSportMarkers: IndexPath?
    var selectedIndexPath: IndexPath?
    var openCellIndexPath: IndexPath?
    var selectedSport: String!
   
    @IBOutlet weak var addCMBtn: UIBarButtonItem!
    
    @IBOutlet weak var mTableViewList: UITableView!
//    @IBOutlet weak var lblCollectiveMarkers: UILabel!
    
    var sportName: String?
    
    
    var settingTxtsWithLogin = [
        ["Soccer", "Futsal", "Basket" , "Pallanuoto" , "Rugby"]
    ]

 

    var sportMarkers: [Marker] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = " Collective Markers"
        
//         Fetch the sport markers data
        let sportType = MarkerType.collectiveSport.rawValue
        print(sportType)

        if let fetchedMarkers = DataManager.shared.fetchSportMarkers(forSportType: sportType) {
            sportMarkers = fetchedMarkers
            print(sportMarkers)
//            UserDefaults.standard.removeObject(forKey: sportType)
//            sportMarkers = fetchedMarkers

//            print(sportMarkers)
        } else {
            let defaultMarkers =  ["Soccer", "Futsal", "Basket" , "Pallanuoto" , "Rugby"]

            // Create new markers using default values
            var sportMarkers: [Marker] = []
            for (index, name) in defaultMarkers.enumerated() {
                let newMarker = Marker("\(index)", name, .collectiveSport, 0)
                sportMarkers.append(newMarker)
            }

            // Save the default sport markers data
            DataManager.shared.saveSportMarkers(sportMarkers, forSportType: sportType)

            // Update the local array used for displaying the table view
            self.sportMarkers = sportMarkers
        }
        mTableViewList.reloadData()




        // Retrieve the saved selected row index
         if let savedRow = UserDefaults.standard.value(forKey: "SelectedRowIndex") as? Int {
             let savedIndexPath = IndexPath(row: savedRow, section: 0)
             selectedIndexPath = savedIndexPath
         } else {
             // Select the first row by default
             selectedIndexPath = IndexPath(row: 0, section: 0)
         }
         
         // Select the saved row
//         if let indexPath = selectedIndexPath {
//             mTableViewList.selectRow(at: indexPath, animated: false, scrollPosition: .none)
//             tableView(mTableViewList, didSelectRowAt: indexPath)
//         }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.Segue.SettingsCollectiveMarkersDetailSegue {
                 let nvc = segue.destination as! UINavigationController
                 let vc = nvc.children[0] as! AddSportVC
                 vc.delegate = self
             }
        
//        if segue.identifier == Constant.Segue.SettingsCollectionSportMarkersSegue {
//            let vc = segue.destination as! SportDetailVC
////            if let indexPath = mTableView.indexPathForSelectedRow {
////                vc.viewMode = indexPath.row.selectedType()
////                print(indexPath.row.selectedType())
////            }
//        }
        
        if segue.identifier == Constant.Segue.sportDetailSegueID {
            let vc = segue.destination as! SportDetailVC
            vc.selectedSport = selectedSport
        }
    }
    
    
    @IBAction func addCmBtnClick(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Constant.Segue.SettingsCollectiveMarkersDetailSegue, sender: MarkerDetailData(mode: SettingsMarkersDetailMode.new, marker: nil, index: nil))

    }

    @IBAction func onback(_ sender: UIBarButtonItem) {
//        navigationController?.dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
    }
    


    func didFinishPassingData(_ data: String) {
           print(data)
           
           let sportType = MarkerType.collectiveSport.rawValue
        print(sportType)
           if var sportMarkers = DataManager.shared.fetchSportMarkers(forSportType: sportType) {
               // Existing sport markers are fetched successfully
               print(sportMarkers)
               // Append new data to the sportMarkers array
               let newMarker = Marker("0", data, .collectiveSport, 0)
               sportMarkers.append(newMarker)
               
               // Save the updated sport markers data
               DataManager.shared.saveSportMarkers(sportMarkers, forSportType: sportType)
               
               print(sportMarkers)
           } else {
               // No existing sport markers data found, handle accordingly
           }

           // Fetch the sport markers data
//           let sportType = MarkerType.collectiveSport.rawValue
           if let fetchedMarkers = DataManager.shared.fetchSportMarkers(forSportType: sportType) {
               sportMarkers = fetchedMarkers
               mTableViewList.reloadData()
           }
           
           mTableViewList.reloadData()
        
       }
}



extension CollectiveMarkersViewController: UITableViewDelegate, UITableViewDataSource {
 
    
    
       func numberOfSections(in tableView: UITableView) -> Int {
           return 1
       }
       
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return sportMarkers.count
       }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectiveMarkersTableViewCell", for: indexPath) as! CollectiveMarkersTableViewCell
        let marker = sportMarkers[indexPath.row]
        cell.lblCollectiveMarkers.text = marker.name
        
        // Check if this cell is the currently open cell
        if openCellIndexPath == indexPath {
            cell.showDropdownView()
        } else {
            cell.hideDropdownView()
        }
        
        cell.btnSports.addTarget(self, action: #selector(updateButtonTapped(_:)), for: .touchUpInside)
        
        // Set the closure for the More button action
        cell.moreButtonAction = { [weak self] in
            self?.handleMoreButtonAction(at: indexPath)
        }
        // Set the closures for the Edit and Delete button actions
        cell.editButtonAction = { [weak self] in
            self?.handleEditButtonAction(at: indexPath)
            cell.hideDropdownView()
        }
        
        cell.deleteButtonAction = { [weak self] in
            self?.handleDeleteButtonAction(at: indexPath)
            cell.hideDropdownView()
        }
        
        // Check if this row is selected
        if indexPath == selectedIndexPath {
            cell.btnSports.setImage(UIImage(named: "check_blue"), for: .normal)
        } else {
            cell.btnSports.setImage(UIImage(named: "uncheck_blue"), for: .normal)
        }
        
        return cell
    }
 
    func handleEditButtonAction(at indexPath: IndexPath) {
        let marker = sportMarkers[indexPath.row]
        
        // Create the alert controller
        let alertController = UIAlertController(title: "Edit Marker", message: nil, preferredStyle: .alert)
        
        // Add a text field to the alert controller
        alertController.addTextField { textField in
            textField.placeholder = "Enter new marker name"
            textField.text = marker.name
        }
        
        // Add a "Change" button to the alert controller
        let changeAction = UIAlertAction(title: "Change", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first,
                  let editedText = textField.text,
                  !editedText.isEmpty else {
                // Handle empty or nil text field
                return
            }
            
            // Update the marker's name
            self?.updateMarkerName(editedText, at: indexPath)
        }
        
        // Add a "Cancel" button to the alert controller
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Add the actions to the alert controller
        alertController.addAction(changeAction)
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }

    func updateMarkerName(_ newName: String, at indexPath: IndexPath) {
        let sportType = MarkerType.collectiveSport.rawValue
        
        // Update the marker's name in the sportMarkers array
        sportMarkers[indexPath.row].name = newName
        
        // Save the updated sport markers data
        DataManager.shared.saveSportMarkers(sportMarkers, forSportType: sportType)
        
        // Reload the table view
        mTableViewList.reloadData()
    }


    
    func handleDeleteButtonAction(at indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Delete Marker", message: "Are you sure you want to delete this marker?", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteMarker(at: indexPath)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        present(alertController, animated: true, completion: nil)
    }


    // Helper method to delete a marker at the specified index path
    func deleteMarker(at indexPath: IndexPath) {
        let sportType = MarkerType.collectiveSport.rawValue

        // Check if the index is within the bounds of the sportMarkers array
        if indexPath.row < sportMarkers.count {
            // Remove the marker from the array
            sportMarkers.remove(at: indexPath.row)

            // Save the updated sport markers data
            DataManager.shared.saveSportMarkers(sportMarkers, forSportType: sportType)

            // Delete the row from the table view
            mTableViewList.deleteRows(at: [indexPath], with: .automatic)
        } else {
            // Handle invalid index path
        }
    }


       // MARK: - UITableViewDelegate
       
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        performSegue(withIdentifier: Constant.Segue.SettingsCollectionSportMarkersSegue, sender: nil)
        
//        indexSportMarkers = indexPath
//        UserDefaults.standard.set(indexSportMarkers, forKey: "SelectedIndexPath")
        
//        let indexPath = IndexPath(row: 0, section: 3)
        let indexPathArray = [indexPath.section, indexPath.row]
        UserDefaults.standard.set(indexPathArray, forKey: "SelectedIndexPath")

        print(indexSportMarkers)
        if let indexPath = mTableViewList.indexPathForSelectedRow {
            let sportType = MarkerType.collectiveSport.rawValue
            var sportMarkers = DataManager.shared.fetchSportMarkers(forSportType: sportType)
            
             selectedSport = sportMarkers?[indexPath.row].name
            print(selectedSport!)

        }
        

        
        // Check if the newly selected row is within the first five rows
                // Deselect the previously selected row if it exists
                if let selectedIndexPath = selectedIndexPath {
                    tableView.deselectRow(at: selectedIndexPath, animated: true)
                    if let cell = tableView.cellForRow(at: selectedIndexPath) as? CollectiveMarkersTableViewCell {
                        cell.btnSports.setImage(UIImage(named: "uncheck_blue"), for: .normal)
                      
                    }
                }
                
                // Update the selectedIndexPath with the newly selected row
                selectedIndexPath = indexPath
                
                // Update the UI of the newly selected row
                if let cell = tableView.cellForRow(at: indexPath) as? CollectiveMarkersTableViewCell {
                    cell.btnSports.setImage(UIImage(named: "check_blue"), for: .normal)
                   
                }
                
                // Save the selected row index
                UserDefaults.standard.set(indexPath.row, forKey: "SelectedRowIndex")
        
        performSegue(withIdentifier: Constant.Segue.sportDetailSegueID, sender: nil)
    }


    @objc func updateButtonTapped(_ sender: UIButton) {
        // Handle the update button action here
        // You can access the cell and the corresponding indexPath using the button's superview hierarchy
        if let cell = sender.superview?.superview as? CollectiveMarkersTableViewCell,
           let indexPath = mTableViewList.indexPath(for: cell) {
            // Update button image for selected row
            if let selectedIndexPath = mTableViewList.indexPathForSelectedRow, selectedIndexPath == indexPath {
                cell.btnSports.setImage(UIImage(named: "check_blue"), for: .normal)
            } else {
                // Update button image for unselected rows
                cell.btnSports.setImage(UIImage(named: "uncheck_blue"), for: .normal)
            }
        }
    }
       // Handle the More button action
       
       func handleMoreButtonAction(at indexPath: IndexPath) {
           if openCellIndexPath == indexPath {
               // Close the currently open dropdown view
               openCellIndexPath = nil
           } else {
               // Close the previously open dropdown view, if any
               if let openCellIndexPath = openCellIndexPath,
                  let openCell = mTableViewList.cellForRow(at: openCellIndexPath) as? CollectiveMarkersTableViewCell {
                   openCell.hideDropdownView()
               }
               // Open the dropdown view for the selected cell
               openCellIndexPath = indexPath
           }
           
           // Reload the table view to reflect the changes
           mTableViewList.reloadData()
       }
    
    

}
