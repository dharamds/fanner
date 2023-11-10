//
//  CollectiveMarkersTableViewCell.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 28/06/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//
import UIKit

class CollectiveMarkersTableViewCell: UITableViewCell {
    @IBOutlet weak var lblCollectiveMarkers: UILabel!
    var moreButtonAction: (() -> Void)?
    var editButtonAction: (() -> Void)?
    var deleteButtonAction: (() -> Void)?

 
    @IBOutlet weak var btnSports: UIButton!
    private let dropdownView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let editButton: UIButton = {
        let button = UIButton()
        button.setTitle("Edit", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle("Delete", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var dropdownViewHeightConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews()
        setupConstraints()
        
        self.btnSports.isUserInteractionEnabled = false
        let dropdownTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDropdownView))
        dropdownView.addGestureRecognizer(dropdownTapGesture)
    }
    
    private func setupSubviews() {
        addSubview(dropdownView)
        dropdownView.addSubview(editButton)
        dropdownView.addSubview(deleteButton)
    }
    
//    override func layoutSubviews() {
//           super.layoutSubviews()
//           
//           // Adjust the position of the accessory type
//           let accessoryMargin: CGFloat = 90
//           
//           if let accessoryView = self.accessoryView {
//               var accessoryFrame = accessoryView.frame
//               accessoryFrame.origin.x = self.contentView.frame.width - accessoryFrame.width - accessoryMargin
//               accessoryFrame.origin.y = (self.contentView.frame.height - accessoryFrame.height) / 2
//               accessoryView.frame = accessoryFrame
//           }
//       }
    private func setupConstraints() {
        dropdownViewHeightConstraint = dropdownView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            dropdownView.topAnchor.constraint(equalTo: topAnchor),
            dropdownView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dropdownView.widthAnchor.constraint(equalToConstant: 120),
            dropdownViewHeightConstraint!,
            
            editButton.topAnchor.constraint(equalTo: dropdownView.topAnchor),
            editButton.leadingAnchor.constraint(equalTo: dropdownView.leadingAnchor),
            editButton.widthAnchor.constraint(equalTo: dropdownView.widthAnchor, multiplier: 0.5),
            editButton.heightAnchor.constraint(equalToConstant: 40),
            
            deleteButton.topAnchor.constraint(equalTo: dropdownView.topAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: editButton.trailingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: dropdownView.trailingAnchor),
            deleteButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    @objc private func toggleDropdownView() {
        dropdownView.isHidden.toggle()
        dropdownViewHeightConstraint?.constant = dropdownView.isHidden ? 0 : 40
    }

    @IBAction func onSportBtnClick(_ sender: UIButton) {
    }
    
    
    @IBAction func onMoreBtn(_ sender: UIButton) {
        moreButtonAction?()
    }
  
    @objc func editButtonTapped() {
        editButtonAction?()// Call the edit button action closure
       }
    @objc func deleteButtonTapped() {
           deleteButtonAction?() // Call the delete button action closure
       }
    
    func showDropdownView() {
        dropdownView.isHidden = false
        dropdownViewHeightConstraint?.constant = 80
    }
    
    func hideDropdownView() {
        dropdownView.isHidden = true
        dropdownViewHeightConstraint?.constant = 0
    }
}
