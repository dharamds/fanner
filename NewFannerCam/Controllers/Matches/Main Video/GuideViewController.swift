//
//  GuideViewController.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 13/12/22.
//  Copyright © 2022 fannercam3. All rights reserved.
//

import UIKit

class GuideViewController: UIViewController {

    @IBOutlet weak var btnClose: UIButton!
    //    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    
    
     @IBOutlet weak var Streamimage2: UIImageView!
     
     @IBOutlet weak var Streamimage1: UIImageView!
   
    init() {
        super.init(nibName: "GuideViewController", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnClose.setTitle("", for: .normal)
             let tapGestureRecognizer1 = UITapGestureRecognizer(target: self, action: #selector(imageTapped1(tapGestureRecognizer:)))
             Streamimage1.isUserInteractionEnabled = true
             Streamimage1.addGestureRecognizer(tapGestureRecognizer1)
             
             let tapGestureRecognizer2 = UITapGestureRecognizer(target: self, action: #selector(imageTapped2(tapGestureRecognizer:)))
             Streamimage2.isUserInteractionEnabled = true
             Streamimage2.addGestureRecognizer(tapGestureRecognizer2)
             // Do any additional setup after loading the view.
        
    }

    @IBAction func closeBtn(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        
    }
    func appear(sender: OverLayerView) {
        sender.present(self, animated: false) {
            self.show()
        }
    }
    
    private func show() {
        UIView.animate(withDuration: 1, delay: 0.2) {
//            self.backView.alpha = 1
            self.contentView.alpha = 1
        }
    }
    

     
     @IBAction func youtubeLinkBtn(_ sender: Any) {
         if let url = URL(string: "https://studio.youtube.com/") {
             UIApplication.shared.open(url)
         }
     }
     @objc func imageTapped1(tapGestureRecognizer: UITapGestureRecognizer) {
  
         let newImageView1 = UIImageView(image: Streamimage1.image)
         newImageView1.frame = UIScreen.main.bounds
         newImageView1.backgroundColor = .black
         newImageView1.contentMode = .scaleAspectFit
         newImageView1.isUserInteractionEnabled = true
         let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
         newImageView1.addGestureRecognizer(tap)
         self.view.addSubview(newImageView1)
         self.navigationController?.isNavigationBarHidden = true
         self.tabBarController?.tabBar.isHidden = true
          
     }
     
     @objc func imageTapped2(tapGestureRecognizer: UITapGestureRecognizer) {
         let newImageView2 = UIImageView(image: Streamimage2.image)
         newImageView2.frame = UIScreen.main.bounds
         newImageView2.backgroundColor = .black
         newImageView2.contentMode = .scaleAspectFit
         newImageView2.isUserInteractionEnabled = true
         let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
         newImageView2.addGestureRecognizer(tap)
         self.view.addSubview(newImageView2)
         self.navigationController?.isNavigationBarHidden = true
         self.tabBarController?.tabBar.isHidden = true
     }
     
     @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
         self.navigationController?.isNavigationBarHidden = false
         self.tabBarController?.tabBar.isHidden = false
         sender.view?.removeFromSuperview()
     }



}
