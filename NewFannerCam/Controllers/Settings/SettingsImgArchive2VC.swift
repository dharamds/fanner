//
//  SettingsImgArchiveVC.swift
//  NewFannerCam
//
//  Created by Jin on 12/30/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import CryptoKit
import AVKit

//enum SettingsImgArchiveVCMode {
//    case edit
//    case show
//    case appLib
//}

private let actionCellID = "SettingsImgArchiveActionCell"
private let imgCellID2 = "SettingsImgArchiveImgCell2"
private let imgCellIDVideo2 = "SettingsImgArchiveImgCellVideo2"


protocol SettingsImgArchiveVCDelegate2: AnyObject {
    func didSelect(image img: UIImage)
}

class SettingsImgArchive2VC: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    
    var fileEx : String = ".png"
    var videourl : URL!
    
    @IBOutlet weak var editBtn: UIButton!
    
    weak var delegate : SettingsImgArchiveVCDelegate2?
    
    var viewMode = SettingsImgArchiveVCMode.show
    
//MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        layout.itemSize = CGSize(width: view.bounds.width/4, height: view.bounds.width/4)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = layout
        editBtn.isHidden = viewMode == .appLib
    }
    
//MARK: - main functions
    func switchAction() {
        switch viewMode {
        case .show:
            viewMode = .edit
            editBtn.setTitle("Cancel", for: .normal)
            break
        case .edit:
            viewMode = .show
            editBtn.setTitle("Edit", for: .normal)
            break
        default:
            break
        }
        collectionView.reloadData()
    }
    
    func delete(all: Bool, index: Int?) {
        guard DataManager.shared.imgArchives2.count > 0 else { return }
        
        var message : String!
        if all {
            message = "Are you sure to delete all images?"
        } else {
            message = "Are you sure to delete the selected image?"
        }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (yesAction) in
            if all {
                DataManager.shared.updateImgArchives2(ImgArchive(), 0, .delete, true)
            } else {
                DataManager.shared.updateImgArchives2(DataManager.shared.imgArchives2[index!], index!, .delete)
            }
            self.collectionView.reloadData()
        }
        alert.addAction(yesAction)
        present(alert, animated: true, completion: nil)
    }

//MARK: - IBAction functions
    @IBAction func onBackBtn(_ sender: Any) {
        if viewMode == .appLib {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func onEditBtn(_ sender: Any) {
        switchAction()
    }
    
// MARK: - UICollectionViewDataSource & Delegate
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewMode == .appLib ? DataManager.shared.imgArchives2.count : DataManager.shared.imgArchives2.count + 1
    }
    
    
    func imageFromVideo(url: URL, at time: TimeInterval) -> UIImage? {
        let asset = AVURLAsset(url: url)

        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

        let cmTime = CMTime(seconds: time, preferredTimescale: 60)
        let thumbnailImageRef: CGImage
        do {
            thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }

        return UIImage(cgImage: thumbnailImageRef)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewMode != .appLib, indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: actionCellID, for: indexPath) as! SettingImgActionCell
            cell.initialization1(self, viewMode)
            return cell
        } else {

            if self.fileEx == ".mov" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellIDVideo2, for: indexPath) as! SettingImgCellVideo2
                let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                cell.playImg.isHidden = false
                let extensionCheck = DataManager.shared.imgArchives2[index].filePath().pathExtension

                if extensionCheck == "png" {
                   
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell
                    let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                    cell.initialization1(self, viewMode, DataManager.shared.imgArchives2[index])
                    cell.playImg.isHidden = true
                    return cell
                } else if extensionCheck == "gif" {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell
                    let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                    cell.initialization1(self, viewMode, DataManager.shared.imgArchives2[index])
                    cell.playImg.isHidden = true
                    return cell
                }
                else {
                    cell.playImg.isHidden = false
                    cell.deleteBtn.isHidden = true
//                    cell.imgView.image = UIImage(named: "Video.png")
                    let vidURl = DataManager.shared.imgArchives2[index].filePath()
                    DispatchQueue.global(qos: .background).async {
                        let image = self.imageFromVideo(url: vidURl, at: 0)

                        DispatchQueue.main.async {
                            cell.imgView.image = image
                        }
                    }
                    cell.initialization1(self, viewMode, DataManager.shared.imgArchives2[index])

                }

                return cell
                
            }else {
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell
                let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                let extensionCheck = DataManager.shared.imgArchives2[index].filePath().pathExtension

                if extensionCheck == "png" {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell
                    let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                    cell.initialization1(self, viewMode, DataManager.shared.imgArchives2[index])
                    cell.playImg.isHidden = true
                    return cell
                } else if extensionCheck == "gif" {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell
                    let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                    cell.initialization1(self, viewMode, DataManager.shared.imgArchives2[index])
                    cell.playImg.isHidden = true
                    return cell
                }
                else {
                    cell.playImg.isHidden = false
                    cell.deleteBtn.isHidden = true
//                    cell.imgView.image = UIImage(named: "Video.png")
                    let vidURl = DataManager.shared.imgArchives2[index].filePath()
                    DispatchQueue.global(qos: .background).async {
                        let image = self.imageFromVideo(url: vidURl, at: 0)

                        DispatchQueue.main.async {
                            cell.imgView.image = image
                        }
                    }
                    cell.initialization1(self, viewMode, DataManager.shared.imgArchives2[index])
                    return cell
                }
                
            }
            
            return UICollectionViewCell()
        }
    }


    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        if viewMode == .appLib , indexPath.item == 0 {
            delegate?.didSelect(image: UIImage(contentsOfFile: DataManager.shared.imgArchives2[indexPath.item].filePath().path) ?? UIImage())
            dismiss(animated: true, completion: nil)
        }
    }
}

//MARK: - SettingsImgActionCellDelegate
extension SettingsImgArchive2VC: SettingsImgActionCellDelegate {
    func actionCell(didClickedAction mode: SettingsImgArchiveVCMode) {
        if viewMode == .show {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType =  UIImagePickerController.SourceType.photoLibrary
            picker.mediaTypes = [kUTTypeImage as String ,  kUTTypeMovie as String]
            present(picker, animated: true, completion:nil )
        } else {
            delete(all: true, index: nil)
        }
    }
}

//MARK: - SettingImgCellDelegate
extension SettingsImgArchive2VC: SettingImgCellDelegate {
    func didClickDelete(_ cell: SettingImgCell) {
        let index = self.collectionView.indexPath(for: cell as! UICollectionViewCell)!
        delete(all: false, index: index.item - 1)
    }

}

extension SettingsImgArchive2VC: SettingImgCellDelegateVid2 {
    func didClickDeletedVid2(_ cell: SettingImgCellVideo2) {
        let index = self.collectionView.indexPath(for: cell)!
        delete(all: false, index: index.item - 1)
    }

}

//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension SettingsImgArchive2VC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let imageUrl = info[UIImagePickerController.InfoKey.referenceURL] as? URL {

                let asset = PHAsset.fetchAssets(withALAssetURLs: [imageUrl], options: nil)
                if let image = asset.firstObject {
                    
                    var imageRequestOptions: PHImageRequestOptions {
                           let options = PHImageRequestOptions()
                           options.version = .current
                           options.resizeMode = .exact
                           options.deliveryMode = .highQualityFormat
                           options.isNetworkAccessAllowed = true
                           options.isSynchronous = true
                           return options
                       }
                    PHImageManager.default().requestImageData(for: image, options: imageRequestOptions) { (imageData, _, _, _) in
                        if let currentImageData = imageData {
                            let isImageAnimated = isAnimatedImage(currentImageData)
                            
                            if isImageAnimated == true {

                                    var newImg = ImgArchive()
                                    newImg.fileName = newImg.fileName.replacingOccurrences(of: ".png", with: ".gif")
                                    ImageProcess.saveGif(imgFile: currentImageData, to: newImg.filePath()) { (isSucceed, resultDes) in
                                        if isSucceed {
                                            DataManager.shared.updateImgArchives2(newImg, 0, .new)
                                            DispatchQueue.main.async {
                                                self.collectionView.reloadData()
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                MessageBarService.shared.error(resultDes)
                                            }
                                        }
                                    }
                                
                            } else {
                                if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                                    let newImg = ImgArchive()
                                    self.fileEx = ".png"
                                    ImageProcess.save(imgFile: photoTaken, to: newImg.filePath()) { (isSucceed, resultDes) in
                                        if isSucceed {
                                            DataManager.shared.updateImgArchives2(newImg, 0, .new)
                                            DispatchQueue.main.async {
                                                self.collectionView.reloadData()
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                MessageBarService.shared.error(resultDes)
                                            }
                                        }
                                    }

                                }
                                
                                else  if let mediaUrl =  info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                                    print(mediaUrl)
                                    self.videourl = mediaUrl
                                    var newImg = ImgArchive()
                                    newImg.fileName = newImg.fileName.replacingOccurrences(of: ".png", with: ".mov")
                                    self.fileEx = ".mov"
                                    print(newImg.fileName)
                                    ImageProcess.saveVideo(imgFile: mediaUrl, to: newImg.filePath()) { (isSucceed, resultDes) in
                                        if isSucceed {
                                            DataManager.shared.updateImgArchives2(newImg, 0, .new)
                                            DispatchQueue.main.async {
                                                self.collectionView.reloadData()
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                MessageBarService.shared.error(resultDes)
                                            }
                                        }
                                    }
                                }
                            }
                            print("isAnimated: \(isImageAnimated)")
                        }
                        
                    }
                }


            }
        
        
//        if let photoTaken = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
//            let newImg = ImgArchive()
//            ImageProcess.save(imgFile: photoTaken, to: newImg.filePath()) { (isSucceed, resultDes) in
//                if isSucceed {
//                    DataManager.shared.updateImgArchives2(newImg, 0, .new)
//                    DispatchQueue.main.async {
//                        self.collectionView.reloadData()
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        MessageBarService.shared.error(resultDes)
//                    }
//                }
//            }
//        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}

func isAnimatedImage(_ imageData: Data) -> Bool {
    if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
        let count = CGImageSourceGetCount(source)
        return count > 1
    }
    return false
}
