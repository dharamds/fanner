//
//  OverLayerView.swift
//  CustomPopUp
//
//  Created by Sajjad Sarkoobi on 8.07.2022.
//

import UIKit

class OverLayerView: UIViewController {
    @IBOutlet weak var btnGuide: UIButton!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var onDoneBlock : ((Bool) -> Void)?
    
    @IBOutlet weak var lblBitrateValue: UILabel!
    @IBOutlet weak var saveSwitch: UISwitch!
    var segmentedPresets = [ MatchesMainVideoRecordLiveVC.Preset.sd_540p_30fps_2mbps,
                             MatchesMainVideoRecordLiveVC.Preset.hd_720p_30fps_3mbps,
                             MatchesMainVideoRecordLiveVC.Preset.hd_1080p_30fps_5mbps
                            ]
        
    var BitrateValue = Int()
    var audioQuality = Int()
    var selectedFrameRate = Int()
    var selectedVideoResolutionIndex = Int()
    
    var saveDataSetting: [String] = []
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var tfUrl: UITextField!
    @IBOutlet weak var tfKey: UITextField!
    @IBOutlet weak var segAudio: UISegmentedControl!
    @IBOutlet weak var segFrameRate: UISegmentedControl!
    @IBOutlet weak var segVideoResolution: UISegmentedControl!
    @IBOutlet weak var sliderBitratevalur: UISlider!
    @IBOutlet weak var btnSaveSetting: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    
    
    //image
    @IBOutlet weak var imgUrl: UIImageView!
//    @IBOutlet weak var imgRate3: UIImageView!
    @IBOutlet weak var imgLevel2: UIImageView!
    @IBOutlet weak var imgRate2: UIImageView!
    @IBOutlet weak var imgRate1: UIImageView!
    @IBOutlet weak var imgLevel: UIImageView!
    @IBOutlet weak var imgUse: UIImageView!
    @IBOutlet weak var imgKey: UIImageView!
    
    //IBOutlets
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBAction func doneButtonAction(_ sender: UIButton) {
        hide()

    }
    
    init() {
        super.init(nibName: "OverLayerView", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.closeBtn.setTitle("", for: .normal)
        btnGuide.setTitle("", for: .normal)
        
  
////restream
        ///
//         self.tfKey.text = "re_6976705_b4676822182c86e9aaca"
//        self.tfUrl.text = "rtmp://live.restream.io/live"
        
        //new-07 nov
//        self.tfKey.text = "re_6976705_fcdbeeac7b60bedc1f8f"
//       self.tfUrl.text = "rtmp://live.restream.io/live"
        sliderBitratevalur.minimumValue = 800
        sliderBitratevalur.maximumValue = 15000
        saveDataSetting = defaults.stringArray(forKey: "RTMPSettingDataa") ?? [String]()
        
        if saveDataSetting.count == 8 {
        self.tfKey.text = saveDataSetting[1]
        self.tfUrl.text = saveDataSetting[0]
        self.segAudio.selectedSegmentIndex = Int(saveDataSetting[6])!
        self.segFrameRate.selectedSegmentIndex = Int(saveDataSetting[7])!
        self.segVideoResolution.selectedSegmentIndex = Int(saveDataSetting[4])!
        self.sliderBitratevalur.value = Float(saveDataSetting[5])!
        self.BitrateValue = Int(Float(saveDataSetting[5]) ?? 800)
        self.lblBitrateValue.text = "Bitrate (" + "\(BitrateValue)" + " kbps)"
         
        }
        segColorSetting(seg: segAudio)
        segColorSetting(seg: segFrameRate)
        segColorSetting(seg: segVideoResolution)

        imgColorChange(img: imgKey)
        imgColorChange(img: imgUrl)
        imgColorChange(img: imgUse)
        imgColorChange(img: imgLevel)
        imgColorChange(img: imgRate1)
        imgColorChange(img: imgRate2)
        imgColorChange(img: imgLevel2)
        
        configView()

    }

    
    @IBAction func onCloseBtnClick(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        appDelegate.secondWindow!.isHidden = false
    }
    override func viewDidDisappear(_ animated: Bool) {
      

    }
    
    func imgColorChange(img : UIImageView) {
        img.image = img.image?.withRenderingMode(.alwaysTemplate)
        img.tintColor = UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1)
    }
    
    private func configView() {
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.contentView.alpha = 0
        self.contentView.layer.cornerRadius = 10
    }
    
    func appear(sender: MatchesMainVideoRecordLiveVC) {
        
        sender.present(self, animated: false) {
            self.show()
           
        }
    }
    
    private func show() {
        UIView.animate(withDuration: 1, delay: 0.2) {
            self.backView.alpha = 1
            self.contentView.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseOut) {
            self.backView.alpha = 0
            self.contentView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
            self.removeFromParent()
        }
    }
    
  
    @IBAction func segAudioValueChanged(_ sender: UISegmentedControl) {
        if segAudio.selectedSegmentIndex == 0 {
            self.audioQuality = 48 * 1024
            print("Low")
        }else if segAudio.selectedSegmentIndex == 1 {
            self.audioQuality = 64 * 1024
            print("Medium")
        } else if segAudio.selectedSegmentIndex == 2 {
            self.audioQuality = 96 * 1024
            print("High")
        }else if segAudio.selectedSegmentIndex == 3 {
            self.audioQuality = 128 * 1024
            print("Very High")
        }else {
            self.audioQuality = 48 * 1024
            print("Default Low")
        }
    }
    
    @IBAction func segFrameRateChanged(_ sender: UISegmentedControl) {
        if segFrameRate.selectedSegmentIndex == 0 {
            self.selectedFrameRate = 24
            print("24")
        }else if segFrameRate.selectedSegmentIndex == 1 {
            self.selectedFrameRate = 25
            print("25")
        } else if segFrameRate.selectedSegmentIndex == 2 {
            self.selectedFrameRate = 30
            print("30")
        }else {
            self.selectedFrameRate = 24
            print("default 24")
        }
    }
    
    @IBAction func segVideoResolutionChanged(_ sender: UISegmentedControl) {
       
        self.selectedVideoResolutionIndex = segVideoResolution.selectedSegmentIndex
    }
    
    @IBAction func sliderBitrateValueChanged(_ sender: UISlider) {
        var currentValue = Int(sender.value)
        self.lblBitrateValue.text = "Bitrate (\(currentValue) kbps)"
        self.BitrateValue = Int(currentValue)
        
    }
    
    @IBAction func saveSwitchChanged(_ sender: Any) {
   
    }
    
    @IBAction func saveBtnClick(_ sender: Any) {
        hide()
        self.dismiss(animated: true, completion: nil)
        
        appDelegate.secondWindow!.isHidden = false

        if audioQuality == 0 {
            audioQuality = 48 * 1024
        }else {
            segAudioValueChanged(segAudio)
        }
  
        segFrameRateChanged(segFrameRate)

        
        if BitrateValue == 0 {
            BitrateValue = 1500
        }
        
        saveDataSetting = ["\(tfUrl.text!)" , "\(tfKey.text!)" , "\(audioQuality)" , "\(selectedFrameRate)", "\(segVideoResolution.selectedSegmentIndex)" , "\(BitrateValue)" , "\(segAudio.selectedSegmentIndex)" , "\(segFrameRate.selectedSegmentIndex)"]

        defaults.set(saveDataSetting, forKey: "RTMPSettingDataa")
        
    }
    @IBAction func btnGuideClick(_ sender: UIButton) {
 
        let GuideViewController = GuideViewController()
        GuideViewController.appear(sender: self)

    }
    
    @IBAction func cancelBtnClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        appDelegate.secondWindow!.isHidden = false

    }
    
    func segColorSetting(seg : UISegmentedControl) {
        if #available(iOS 13.0, *) {
            seg.selectedSegmentTintColor = UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1)//.black
            seg.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
            seg.setTitleTextAttributes([.foregroundColor: UIColor(red: 0.0/255.0, green: 122.0/255.0, blue: 255.0/255.0, alpha: 1)], for: .normal)
        }
    }
    
}
