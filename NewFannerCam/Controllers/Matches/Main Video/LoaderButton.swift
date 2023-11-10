//
//  LoaderButton.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 15/06/23.
//  Copyright © 2023 fannercam3. All rights reserved.
//

import Foundation


import UIKit

class LoadingButton: UIButton {
    private var originalButtonText: String?
    private var activityIndicator: UIActivityIndicatorView!

    func showLoading() {
        originalButtonText = self.titleLabel?.text
        self.setTitle("", for: .normal)

        if activityIndicator == nil {
            activityIndicator = createActivityIndicator()
        }

        showSpinning()
    }

    func hideLoading() {
        self.setTitle(originalButtonText, for: .normal)
        activityIndicator.stopAnimating()
    }

    private func createActivityIndicator() -> UIActivityIndicatorView {
//        let activityIndicator = UIActivityIndicatorView()
//        activityIndicator.hidesWhenStopped = true
//        activityIndicator.color = .gray
//        activityIndicator.tr
//        return activityIndicator
   
        let activityIndicator = UIActivityIndicatorView(style: .white)
    
            activityIndicator.hidesWhenStopped = true
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.color = .darkGray
            activityIndicator.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Increase the scale factor as desired
            return activityIndicator
    }

    private func showSpinning() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activityIndicator)
//        centerActivityIndicatorInButto
        activityIndicator.startAnimating()
    }

     func centerActivityIndicatorInButton(xConstant: Int , yConstant: Int) {
        let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal,
                                                   toItem: activityIndicator, attribute: .centerX,
                                                   multiplier: 1, constant: CGFloat(xConstant))
        self.addConstraint(xCenterConstraint)

        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal,
                                                   toItem: activityIndicator, attribute: .centerY,
                                                   multiplier: 1, constant: CGFloat(yConstant))
        self.addConstraint(yCenterConstraint)

    }
}
