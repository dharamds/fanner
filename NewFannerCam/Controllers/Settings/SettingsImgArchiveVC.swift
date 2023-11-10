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
import CoreServices

enum SettingsImgArchiveVCMode {
   case edit
   case show
   case appLib
}

private let actionCellID = "SettingsImgArchiveActionCell"
private let imgCellID2 = "SettingArchiveImgCell2"
private let imgCellIDVideo2 = "SettingArchiveImgCellVideo"

protocol SettingsImgArchiveVCDelegate: AnyObject {
   func didSelect(image img: UIImage)
}

class SettingsImgArchiveVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var fileEx : String = ".png"
    var videourl : URL!
   @IBOutlet weak var editBtn: UIButton!
   
   weak var delegate : SettingsImgArchiveVCDelegate?
   
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
       
       
//       collectionView.register(SettingImgCellVideo.self, forCellWithReuseIdentifier: imgCellID1)

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
       guard DataManager.shared.imgArchives.count > 0 else { return }
       
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
               DataManager.shared.updateImgArchives(ImgArchive(), 0, .delete, true)
           } else {
               DataManager.shared.updateImgArchives(DataManager.shared.imgArchives[index!], index!, .delete)
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
       return viewMode == .appLib ? DataManager.shared.imgArchives.count : DataManager.shared.imgArchives.count + 1
   }

   override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       if viewMode != .appLib, indexPath.row == 0 {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: actionCellID, for: indexPath) as! SettingImgActionCell
           cell.initialization(self, viewMode)
           return cell
       }else {
           if self.fileEx == ".mov" {
               let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellIDVideo2, for: indexPath) as! SettingImgCellVideo
               let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
               cell.playImg.isHidden = true
               let extensionCheck = DataManager.shared.imgArchives[index].filePath().pathExtension

               
               if extensionCheck == "png" {
                   
                   let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell2
                   let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                   cell.initialization(self, viewMode, DataManager.shared.imgArchives[index])
                   cell.playImg.isHidden = true

                   return cell
                   
               }else  if extensionCheck == "gif" {
                   
                   let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell2
                   let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                   cell.initialization(self, viewMode, DataManager.shared.imgArchives[index])
                   cell.playImg.isHidden = true

                   return cell
                   
               }
               else {
                   cell.playImg.isHidden = false
                   cell.deleteBtn.isHidden = true
                   let vidURl = DataManager.shared.imgArchives[index].filePath()
                   DispatchQueue.global(qos: .background).async {
                       let image = self.imageFromVideo(url: vidURl, at: 0)

                       DispatchQueue.main.async {
                           cell.imgView.image = image
                       }
                   }
                   cell.initialization(self, viewMode, DataManager.shared.imgArchives[index])

               }

               return cell
               
           }else {
               let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell2
               let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
               let extensionCheck = DataManager.shared.imgArchives[index].filePath().pathExtension
               
               print(extensionCheck)
               if extensionCheck == "png" {
                   let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell2
                   let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                   cell.initialization(self, viewMode, DataManager.shared.imgArchives[index])
                   cell.playImg.isHidden = true

                   return cell
               }  else if extensionCheck == "gif" {
                   let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellID2, for: indexPath) as! SettingImgCell2
                   let index = viewMode == .appLib ? indexPath.item : indexPath.item - 1
                   cell.initialization(self, viewMode, DataManager.shared.imgArchives[index])
                   cell.playImg.isHidden = true

                   return cell
               }
               else {
                   let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imgCellIDVideo2, for: indexPath) as! SettingImgCellVideo

                   cell.playImg.isHidden = false
                   cell.deleteBtn.isHidden = true
                   let vidURl = DataManager.shared.imgArchives[index].filePath()
                   DispatchQueue.global(qos: .background).async {
                       let image = self.imageFromVideo(url: vidURl, at: 0)

                       DispatchQueue.main.async {
                           cell.imgView.image = image
                       }
                   }
                   cell.initialization(self, viewMode, DataManager.shared.imgArchives[index])
                   return cell
               }
           }
       }
       return UICollectionViewCell()
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

   // MARK: UICollectionViewDelegate
   override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       if viewMode == .appLib {
           delegate?.didSelect(image: UIImage(contentsOfFile: DataManager.shared.imgArchives[indexPath.item].filePath().path) ?? UIImage())
           dismiss(animated: true, completion: nil)
       }
   }

}

//MARK: - SettingsImgActionCellDelegate
extension SettingsImgArchiveVC: SettingsImgActionCellDelegate {
   func actionCell(didClickedAction mode: SettingsImgArchiveVCMode) {
       if viewMode == .show {
           let picker = UIImagePickerController()
           picker.delegate = self
           picker.sourceType =  UIImagePickerController.SourceType.savedPhotosAlbum
           picker.mediaTypes = [kUTTypeImage as String , kUTTypeMovie as String]
           present(picker, animated: true, completion:nil )
       } else {
           delete(all: true, index: nil)
       }
   }
}

//MARK: - SettingImgCellDelegate
extension SettingsImgArchiveVC: SettingImgCellDelegate2 {
    func didClickDelete2(_ cell: SettingImgCell2) {
        let index = self.collectionView.indexPath(for: cell)!
        delete(all: false, index: index.item - 1)
    }
    
}

extension SettingsImgArchiveVC: SettingImgCellDelegateVid {
   func didClickDeletedVid(_ cell: SettingImgCellVideo) {
       let index = self.collectionView.indexPath(for: cell)!
       delete(all: false, index: index.item - 1)
   }
}

//MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension SettingsImgArchiveVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

       if let imageUrl = info[UIImagePickerController.InfoKey.referenceURL] as? URL {

           print(imageUrl)

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
                                           DataManager.shared.updateImgArchives(newImg, 0, .new)
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
                                   ImageProcess.save(imgFile: photoTaken, to: newImg.filePath()) { (isSucceed, resultDes) in
                                       if isSucceed {
                                           DataManager.shared.updateImgArchives(newImg, 0, .new)
                                           
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
                                           DataManager.shared.updateImgArchives(newImg, 0, .new)
                                           DispatchQueue.main.async {
                                               self.collectionView.reloadData()
                                           }
                                       } else {
                                           DispatchQueue.main.async {
                                               MessageBarService.shared.error(resultDes)
                                           }
                                       }
                                   }
                                   print(DataManager.shared.imgArchives)
                                   print(newImg.filePath().pathExtension)
//                                    self.mediaUrlArr.append(mediaUrl)
//                                    print(self.mediaUrlArr)
//                                    DispatchQueue.main.async {
//                                        self.collectionView.reloadData()
//                                    }
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
//                    DataManager.shared.updateImgArchives(newImg, 0, .new)
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

