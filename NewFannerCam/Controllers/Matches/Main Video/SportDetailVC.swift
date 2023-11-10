//
//  SportDetailVC.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 05/07/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//

import UIKit


protocol SecondViewControllerDetailsDelegate: AnyObject {
    func didFinishPassingDetailsData(_ tagName: String ,  tagDuration: String)
}


class SportDetailVC: UIViewController  , SecondViewControllerDetailsDelegate {
    @IBOutlet weak var mTableView: UITableView!
    var openCellIndexPath: IndexPath?
    var selectedSport : String!
    var edited : Bool = false
    @IBOutlet weak var addSportsMarkers: UIBarButtonItem!
    //AddSportsMarkerEnter

    var sportDetailsMarkers: [String: [Marker]] = [
        "Soccer": [
            Marker("1", "GOL", .collectiveSport, 15),
            Marker("2", "OCCASIONE", .collectiveSport, 15),
            Marker("3", "ESPULSIONE", .collectiveSport, 15),
            Marker("4", "FALLO DA RIGORE", .collectiveSport, 15),
            Marker("5", "RIGORE SEGNATO", .collectiveSport, 10),
            Marker("6", "RIGORE SBAGLIATO", .collectiveSport, 10),
            Marker("7", "FINE GARA", .collectiveSport, 10),
            Marker("8", "INTERVISTA", .collectiveSport, 60),
        ],
        "Futsal": [
            Marker("1", "GOL", .collectiveSport, 16),
            Marker("2", "OCCASIONE", .collectiveSport, 12),
            Marker("3", "OCCASIONE DA PIAZZATO", .collectiveSport, 7),
            Marker("4", "GOL DA PIAZZATO", .collectiveSport, 10),
            Marker("5", "FALLO DA RIGORE", .collectiveSport, 7),
            Marker("6", "RIGORE SBAGLIATO", .collectiveSport, 7),
            Marker("7", "ESPULSIONE", .collectiveSport, 15),
            Marker("8", "FINE GARA", .collectiveSport, 10),
            Marker("9", "INTERVISTA", .collectiveSport, 60),
        ],
        "Basket": [
            Marker("1", "CANESTRO DA 3", .collectiveSport, 10),
            Marker("2", "CANESTRO", .collectiveSport, 10),
            Marker("3", "TIRO LIBERO", .collectiveSport, 4),
            Marker("4", "SCHIACCIATA", .collectiveSport, 10),
            Marker("5", "FINE GARA", .collectiveSport, 10),
            Marker("6", "INTERVISTA", .collectiveSport, 60),
        ],
        "Pallanuoto": [
            Marker("1", "GOL", .collectiveSport, 10),
            Marker("2", "OCCASIONE", .collectiveSport, 10),
            Marker("3", "GOL RIGORE", .collectiveSport, 5),
            Marker("4", "RIGORE PARATO", .collectiveSport, 5),
            Marker("5", "FINE GARA", .collectiveSport, 10),
        ],
        "Rugby": [
            Marker("1", "MATA DA MISCHIA", .collectiveSport, 12),
            Marker("2", "META", .collectiveSport, 15),
            Marker("3", "PIAZZATO", .collectiveSport, 6),
            Marker("4", "PLACCAGGIO", .collectiveSport, 8),
            Marker("5", "SALUTO", .collectiveSport, 8),
            Marker("6", "FINE GARA", .collectiveSport, 10),
            Marker("7", "INTERVISTA", .collectiveSport, 60)
        ]
    ]

    /*
     var sportDetailsMarkers: [String: [Marker]] = [
         "Soccer": [
             Marker("1", "GOL", .collectiveSport, 16),
             Marker("2", "OCCASIONE", .collectiveSport, 12),
             Marker("4", "OCCASIONE DA PIAZZATO", .collectiveSport, 7),
             Marker("5", "GOL DA PIAZZATO", .collectiveSport, 10),
             Marker("6", "FALLO DA RIGORE", .collectiveSport, 7),
             Marker("7", "RIGORE SBAGLIATO", .collectiveSport, 7),
             Marker("8", "ESPULSIONE", .collectiveSport, 15),
             Marker("9", "FINE GARA", .collectiveSport, 10),
             Marker("10", "INTERVISTA", .collectiveSport, 60),
         ],
         "Futsal": [
             Marker("1", "GOL", .collectiveSport, 16),
             Marker("2", "OCCASIONE", .collectiveSport, 12),
             Marker("4", "OCCASIONE DA PIAZZATO", .collectiveSport, 7),
             Marker("5", "GOL DA PIAZZATO", .collectiveSport, 10),
             Marker("6", "FALLO DA RIGORE", .collectiveSport, 7),
             Marker("7", "RIGORE SBAGLIATO", .collectiveSport, 7),
             Marker("8", "ESPULSIONE", .collectiveSport, 15),
             Marker("9", "FINE GARA", .collectiveSport, 10),
             Marker("10", "INTERVISTA", .collectiveSport, 60),
         ],
         "Basket": [
             Marker("1", "CANESTRO DA 3", .collectiveSport, 10),
             Marker("2", "CANESTRO", .collectiveSport, 10),
             Marker("3", "TIRO LIBERO", .collectiveSport, 4),
             Marker("4", "SCHIACCIATA", .collectiveSport, 10),
             Marker("5", "FINE GARA", .collectiveSport, 10),
             Marker("6", "INTERVISTA", .collectiveSport, 60),
         ],
         "Pallanuoto": [
             Marker("1", "GOL", .collectiveSport, 10),
             Marker("2", "OCCASIONE", .collectiveSport, 10),
             Marker("3", "GOL RIGORE", .collectiveSport, 5),
             Marker("4", "RIGORE PARATO", .collectiveSport, 5),
             Marker("5", "FINE GARA", .collectiveSport, 10),
         ],
         "Rugby": [
             Marker("1", "MATA DA MISCHIA", .collectiveSport, 12),
             Marker("2", "META", .collectiveSport, 15),
             Marker("3", "PIAZZATO", .collectiveSport, 6),
             Marker("4", "PLACCAGGIO", .collectiveSport, 8),
             Marker("5", "SALUTO", .collectiveSport, 8),
             Marker("6", "FINE GARA", .collectiveSport, 10),
             Marker("7", "INTERVISTA", .collectiveSport, 60)
         ]
     ]
     */
    var settingsMarkerscollectiveSport = [
            Marker("15", "SOCCER", .collectiveSport, 10),
            Marker("15", "FUTSAL", .collectiveSport, 10),
            Marker("15", "BASKET", .collectiveSport, 10),
            Marker("15", "PALLANUOTO", .collectiveSport, 10),
            Marker("15", "RUGBY", .collectiveSport, 10),
    ]

    
    let defaults = UserDefaults.standard
    var sportsMarker = [Marker]()
    var sportsMarkerNew = [Marker]()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        defaults.set(selectedSport, forKey: "selectedSport")
        defaults.synchronize()

        self.navigationItem.title = " Collective > \(selectedSport!)"
        loadSportsMarkers()
    }

    func loadSportsMarkers() {
        if let markersData = defaults.data(forKey: selectedSport),
           let markers = try? JSONDecoder().decode([Marker].self, from: markersData) {
            sportsMarker = markers
        } else {
            if let markers = sportDetailsMarkers[selectedSport] {
                sportsMarker = markers
            }
        }
    }

    @IBAction func addMarkers(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Constant.Segue.AddMarkerEntersegue, sender: MarkerDetailData(mode: SettingsMarkersDetailMode.new, marker: nil, index: nil))
    }

    @IBAction func backBtnClick(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.Segue.AddMarkerEntersegue {
            let nvc = segue.destination as! UINavigationController
            let vc = nvc.children[0] as! AddSportMarkersVC
            vc.delegate = self
        }
    }

    func didFinishPassingDetailsData(_ tagName: String, tagDuration: String) {
        let newMarker = Marker("0", tagName, .collectiveSport, Float64(Float(tagDuration) ?? 0.0))
        sportsMarker.append(newMarker)

        let data = try? JSONEncoder().encode(sportsMarker)
        defaults.set(data, forKey: selectedSport)
        defaults.synchronize()

        mTableView.reloadData()
    }
}




extension SportDetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sportsMarker.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = mTableView.dequeueReusableCell(withIdentifier: "SportDetailsTableViewCell", for: indexPath) as! SportDetailsTableViewCell

        cell.lblSportName.text = sportsMarker[indexPath.row].name
        cell.lblSportDuration.text = "<<\(sportsMarker[indexPath.row].durationDescription())"

        // Check if this cell is the currently open cell
        if openCellIndexPath == indexPath {
            if edited == false {
                cell.showDropdownView()
            }
        } else {
            cell.hideDropdownView()
        }
                
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
        
        return cell
    }
    
    


    func handleEditButtonAction(at indexPath: IndexPath) {
        let marker = sportsMarker[indexPath.row]

        // Create the alert controller
        let alertController = UIAlertController(title: "Edit Marker", message: nil, preferredStyle: .alert)

        // Add a text field for the marker name
        alertController.addTextField { textField in
            textField.placeholder = "Enter edit marker name"
            textField.text = marker.name
        }

        // Add a second text field for additional information
        alertController.addTextField { textField in
            textField.placeholder = "Enter edit marker tag"
            textField.text = "\(marker.duration!)"
            textField.keyboardType = .numberPad
        }

        // Add a "Change" button to the alert controller
        let changeAction = UIAlertAction(title: "Change", style: .default) { [weak self] _ in
            guard let nameField = alertController.textFields?.first,
                  let additionalInfoField = alertController.textFields?.last,
                  let editedName = nameField.text,
                  let editedAdditionalInfo = additionalInfoField.text,
                  !editedName.isEmpty else {
                // Handle empty or nil text fields
                return
            }

            self?.edited = true
            // Update the marker's name and additional information
            if let cell = self?.mTableView.cellForRow(at: indexPath) as? SportDetailsTableViewCell {
                self?.updateMarkerInfo(editedName, additionalInfo: editedAdditionalInfo, at: indexPath, cell: cell)
            }
        }

        // Add a "Cancel" button to the alert controller
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        // Add the actions to the alert controller
        alertController.addAction(changeAction)
        alertController.addAction(cancelAction)

        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }

    func updateMarkerInfo(_ newName: String, additionalInfo: String, at indexPath: IndexPath, cell: SportDetailsTableViewCell) {
        sportsMarker[indexPath.row].name = newName
        sportsMarker[indexPath.row].duration = Float64(additionalInfo)
        
        saveSportsMarkers()
        mTableView.reloadRows(at: [indexPath], with: .automatic)
        cell.hideDropdownView()
        
        self.edited = false
    }


    
    func handleMoreButtonAction(at indexPath: IndexPath) {
        if openCellIndexPath == indexPath {
            // Close the currently open dropdown view
            openCellIndexPath = nil
        } else {
            // Close the previously open dropdown view, if any
            if let openCellIndexPath = openCellIndexPath,
               let openCell = mTableView.cellForRow(at: openCellIndexPath) as? CollectiveMarkersTableViewCell {
                openCell.hideDropdownView()
            }
            // Open the dropdown view for the selected cell
            openCellIndexPath = indexPath
        }
        
        // Reload the table view to reflect the changes
        mTableView.reloadData()
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

        sportsMarker.remove(at: indexPath.row)

        saveSportsMarkers()

        mTableView.reloadData()
        
//        // Check if the index is within the bounds of the sportMarkers array
//        if indexPath.row < sportMarkers.count {
//            // Remove the marker from the array
//            sportMarkers.remove(at: indexPath.row)
//
//            // Save the updated sport markers data
//            DataManager.shared.saveSportMarkers(sportMarkers, forSportType: sportType)
//
//            // Delete the row from the table view
//            mTableViewList.deleteRows(at: [indexPath], with: .automatic)
//        } else {
//            // Handle invalid index path
//        }
    }
    
    func saveSportsMarkers() {
          let data = try? JSONEncoder().encode(sportsMarker)
          defaults.set(data, forKey: selectedSport)
          defaults.synchronize()
      }
}
