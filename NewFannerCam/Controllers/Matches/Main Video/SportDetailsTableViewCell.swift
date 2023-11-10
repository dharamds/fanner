//
//  SportDetailsTableViewCell.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 05/07/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//

import UIKit

class SportDetailsTableViewCell: UITableViewCell {

    var moreButtonAction: (() -> Void)?
    var editButtonAction: (() -> Void)?
    var deleteButtonAction: (() -> Void)?
    
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
    

    
    @IBOutlet weak var lblSportDuration: UILabel!
    @IBOutlet weak var MoreBtn: UIButton!
    @IBOutlet weak var lblSportName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupSubviews()
        setupConstraints()
        
//        self.btnSports.isUserInteractionEnabled = false
        let dropdownTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDropdownView))
        dropdownView.addGestureRecognizer(dropdownTapGesture)
    }
    private func setupSubviews() {
        addSubview(dropdownView)
        dropdownView.addSubview(editButton)
        dropdownView.addSubview(deleteButton)
    }
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
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
