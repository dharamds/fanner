//
//  SettingViewController.swift
//  DemoStreamingLive
//
//  Created by Aniket Bokre on 18/10/22.
//

import UIKit
import Photos

class SettingViewController: UIViewController {

    var selectedMatch                   : SelectedMatch!

    @IBOutlet weak var qualityVideo: UISegmentedControl!

    var segmentedPresets = [MatchesMainVideoRecordLiveVC.Preset.sd_360p_30fps_1mbps,
                            MatchesMainVideoRecordLiveVC.Preset.sd_540p_30fps_2mbps,
                            MatchesMainVideoRecordLiveVC.Preset.hd_720p_30fps_3mbps,
                            MatchesMainVideoRecordLiveVC.Preset.hd_1080p_30fps_5mbps
        ]
    var keySetting = String()
    var urlSetting = String()
    var selectedFrameRate = "24"
    var selectedVideoResolution : Int = 0
    var selectedButton: UIButton? = nil
    var selectedFrame : UIButton? = nil
    var selectedResolution : UIButton? = nil
    @IBOutlet weak var tfKey: UITextField!
    @IBOutlet weak var tfUrl: UITextField!
    var audioQuality : Int = 48000

    //Encodeing
    @IBOutlet weak var lowAudio: UIButton!
    @IBOutlet weak var mediumAudio: UIButton!
    @IBOutlet weak var highAudio: UIButton!
    @IBOutlet weak var veryHighAudio: UIButton!
    
    @IBOutlet weak var frameRate24: UIButton!
    @IBOutlet weak var frameRate25: UIButton!
    @IBOutlet weak var frameRate30: UIButton!
    
    @IBOutlet weak var videoSD: UIButton!
    @IBOutlet weak var videoHD: UIButton!
    @IBOutlet weak var videoFullHD: UIButton!
    
    @IBOutlet weak var sliderBitrate: UISlider!
    @IBOutlet weak var lblbitrate: UILabel!
    var currentSliderValue : Int = 1500

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.backgroundColor = .lightGray
        self.navigationController?.navigationBar.barTintColor = .black
        self.defaultset(btn: self.lowAudio)
        self.defaultset(btn: self.frameRate24)

//        self.tfKey.text = "re_6063863_0f23fc6e53924cacdbe0"
//        self.tfUrl.text = "rtmp://live.restream.io/live"

        self.lowAudio.tag = 10
        self.mediumAudio.tag = 11
        self.highAudio.tag = 12
        self.veryHighAudio.tag = 13

        self.frameRate24.tag = 20
        self.frameRate25.tag = 21
        self.frameRate30.tag = 22

        if #available(iOS 13.0, *) {
            self.qualityVideo.selectedSegmentTintColor = .black
            self.qualityVideo.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        }
        // color of other options
        self.qualityVideo.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)

        self.sliderBitrate.minimumValue = 1500
        self.sliderBitrate.maximumValue = 15000
        self.sliderBitrate.value = 1500
        self.lblbitrate.text = "Bitrate (\(sliderBitrate.value) kbit/sec)"


         if let selectedBtn =  UserDefaults.standard.value(forKey: "selectedBtn") as? String{
             debugPrint("selectedBtn: ",selectedBtn)
             var btn = UIButton()
             if btn == self.view.viewWithTag(Int(selectedBtn)!)!{
                  updateButtonSelection(btn)
             }
         }

    }


    @IBAction func helpBtnClick(_ sender: Any) {
//        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
//        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "HelpViewController") as! HelpViewController
//
//        self.navigationController?.pushViewController(nextViewController, animated: true)

    }
    @IBAction func sliderBitrate(_ sender: UISlider) {
        var currentValue = Int(sender.value)
        self.lblbitrate.text = "Bitrate (\(currentValue) kbit/sec)"
        self.currentSliderValue = currentValue*1000

    }

    @IBAction func btnAudioClick(_ sender: Any) {
        self.clear(btn: self.lowAudio)
        if(selectedButton == nil){
            updateButtonSelection(sender as! UIButton)
          }else{
              if(selectedButton != sender as? UIButton){
                   selectedButton?.backgroundColor =  UIColor(red: 231/255.0, green: 231/255.0, blue: 231/255.0, alpha: 1)
                  //UIColor(hex: "#E7E7E7")
                  selectedButton?.setTitleColor(.black, for: .normal)
                  updateButtonSelection(sender as! UIButton)
                }
          }
        switch (sender as AnyObject).tag {
            //1 kbps = 1 KHz
        case 10:
            self.audioQuality = 48000
        case 11:
            self.audioQuality = 64000
        case 12:
            self.audioQuality = 96000
        case 13:
            self.audioQuality = 128000
        case .none:
            print("none")
        case .some(_):
            print("some")
        }

    }

    @IBAction func clickFrameRateBtn(_ sender: UIButton) {
        self.clear(btn: self.frameRate24)
        if(selectedFrame == frameRate24){
            updateButtonSelectionframe(sender)
          }else{
              if(selectedFrame != sender ){
                  selectedFrame?.backgroundColor = UIColor(red: 231/255.0, green: 231/255.0, blue: 231/255.0, alpha: 1)
                  //"#E7E7E7")
                  selectedFrame?.setTitleColor(.black, for: .normal)
                  updateButtonSelectionframe(sender)
                }
          }
        self.selectedFrameRate = (selectedFrame?.currentTitle)!

    }



    func updateButtonSelection(_ sender: UIButton){
        selectedButton = sender
        selectedButton?.backgroundColor = .black
        selectedButton?.setTitleColor(.white, for: .normal)
    }

    func updateButtonSelectionframe(_ sender: UIButton){
        selectedFrame = sender
        selectedFrame?.backgroundColor = .black
        selectedFrame?.setTitleColor(.white, for: .normal)
    }

    func updateButtonSelectionResolution(_ sender: UIButton){

        selectedResolution = sender
        selectedResolution?.backgroundColor = .black
        selectedResolution?.setTitleColor(.white, for: .normal)

    }


    func defaultset(btn : UIButton){
        btn.backgroundColor = .black
        btn.setTitleColor(.white, for: .normal)
    }
    func clear(btn : UIButton){
        btn.backgroundColor = UIColor(red: 231/255.0, green: 231/255.0, blue: 231/255.0, alpha: 1)
        //"#E7E7E7")
        btn.setTitleColor(.black, for: .normal)
    }
    
    //backToLive
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
//        if segue.identifier == Constant.Segue.backToLiveSegueId {
//            let vc = segue.destination as! MatchesMainVideoRecordLiveVC
//            vc.selectedMatch = selectedMatch
//
////            }
//        }
    }
    
    
    @IBAction func saveBtnClick(_ sender: UIButton) {

//        self.performSegue(withIdentifier: Constant.Segue.backToLiveSegueId, sender: MatchType.liveMatch)
        
    }
}

