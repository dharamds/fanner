//
//  SettingImgCell2.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 03/10/22.
//  Copyright © 2022 fannercam3. All rights reserved.
//

import UIKit

protocol SettingImgCellDelegate2: AnyObject {
    func didClickDelete2(_ cell: SettingImgCell2)
}

class SettingImgCell2: UICollectionViewCell {
    
    @IBOutlet weak var imgView          : UIImageView!
    @IBOutlet weak var deleteBtn        : UIButton!
    
    @IBOutlet weak var playImg: UIImageView!
    weak var delegate                   : SettingImgCellDelegate2?
    
    
    func initialization(_ target: SettingsImgArchiveVC, _ mode: SettingsImgArchiveVCMode, _ mediaItem: ImgArchive) {
        delegate = target as? SettingImgCellDelegate2
        deleteBtn.isHidden = mode != .edit
        if mediaItem.fileName.contains(".mov") {
            let data = FileManager.default.contents(atPath: mediaItem.filePath().path)
            
            imgView.image = UIImage.gifImageWithData(data!)
        } else {
            imgView.image = UIImage(contentsOfFile: mediaItem.filePath().path)
        }
    }
    
    func initialization1(_ target: SettingsImgArchive2VC, _ mode: SettingsImgArchiveVCMode, _ mediaItem: ImgArchive) {
        delegate = target as! SettingImgCellDelegate2
        deleteBtn.isHidden = mode != .edit
        if mediaItem.fileName.contains(".mov") {
            let data = FileManager.default.contents(atPath: mediaItem.filePath().path)
            
            imgView.image = UIImage.gifImageWithData(data!)
        } else {
            imgView.image = UIImage(contentsOfFile: mediaItem.filePath().path)
        }
    }
    
    @IBAction func onDeleteBtn(_ sender: UIButton) {
        delegate?.didClickDelete2(self)
    }
    
}

