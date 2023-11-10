//
//  SettingImgCellVideo.swift
//  NewFannerCam
//
//  Created by Aniket Bokre on 29/09/22.
//  Copyright © 2022 fannercam3. All rights reserved.
//

import UIKit


protocol SettingImgCellDelegateVid: AnyObject {
    func didClickDeletedVid(_ cell: SettingImgCellVideo)
}

class SettingImgCellVideo: UICollectionViewCell {
    @IBOutlet weak var imgView          : UIImageView!
    @IBOutlet weak var deleteBtn       : UIButton!
    @IBOutlet weak var playImg          : UIImageView!
    weak var delegateVideo : SettingImgCellDelegateVid?
    
    
    func initialization(_ target: SettingsImgArchiveVC, _ mode: SettingsImgArchiveVCMode, _ mediaItem: ImgArchive) {
        delegateVideo = target  as! SettingImgCellDelegateVid
        deleteBtn.isHidden = mode != .edit
        
        if mediaItem.fileName.contains(".gif") {
            let data = FileManager.default.contents(atPath: mediaItem.filePath().path)
            
            imgView.image = UIImage.gifImageWithData(data!)
        } else {
            imgView.image = UIImage(contentsOfFile: mediaItem.filePath().path)
        }
        
        
    }
    
    func initialization1(_ target: SettingsImgArchive2VC, _ mode: SettingsImgArchiveVCMode, _ mediaItem: ImgArchive) {
        delegateVideo = target as! SettingImgCellDelegateVid
        deleteBtn.isHidden = mode != .edit
        if mediaItem.fileName.contains(".gif") {
            let data = FileManager.default.contents(atPath: mediaItem.filePath().path)
            
            imgView.image = UIImage.gifImageWithData(data!)
        } else {
            imgView.image = UIImage(contentsOfFile: mediaItem.filePath().path)
        }
    }
    
    @IBAction func onDeleteBtn(_ sender: UIButton) {
        delegateVideo?.didClickDeletedVid(self)
    }
    
}

