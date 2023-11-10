//
//  MatchesMainVideoRecordVC.swift
//  NewFannerCam
//
//  Created by Jin on 1/7/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import ReplayKit
import Photos
import AVKit
import CoreImage
import Accelerate
import CoreVideo
import CoreMedia

struct Stream {
    var time: String
    var name: String
}

protocol YouTubeLiveVideoOutput: AnyObject {
    func startPublishing(completed: @escaping (String?, String?) -> Void)
    func finishPublishing()
    func cancelPublishing()
}

var isFromWatch : Bool = false
var isControllerActive:Bool = false

class MatchesMainVideoRecordVC: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var logoTrailingConstraints           : NSLayoutConstraint!
    var notificationQueue                                = DispatchQueue(label: "com.fannercamapp.notificationQueue")
    var isRecapListSelected                             : Bool = false
    let timeoutInSeconds                                : Double = 60.0 // 350
    let uploadGroup                                     = DispatchGroup()
    var uploadCompleted                                 = false
    var workItem                                        : DispatchWorkItem?
    var videoComposition                                = AVMutableVideoComposition()
    @IBOutlet weak var scoreViewHeightConstraint        : NSLayoutConstraint!
    @IBOutlet weak var scoreViewNew                     : UIView!
    var clipCurrentScore                                : String!
    @IBOutlet weak var fannerLogoConstraint             : NSLayoutConstraint!
    var documentsPath                                   : NSString!
    var clipTag                                         : String!
    var ts                                              : String!
    var finalVideoURL                                   : URL!
    var clipProcessing                                  : Bool = false
    var videoOutputURL                                  : URL!
    var videoWriter                                     : AVAssetWriter!
    var videoWriterInput                                : AVAssetWriterInput!
    var audioWriterInput                                : AVAssetWriterInput!
    var exportVideoInterval                             : TimeInterval?
    var audioFileURL                                    : URL!
    var finalcropURL                                    : URL!
    var finalstableVidURL                               : URL!
    var clipDuration                                    : Int! = 0
    var clipUrlArray                                    : [URL] = []
    @IBOutlet weak var nScoreView                       : UIView!
    var uploadingIndexStatus                            : Int = 0
    var timestampArr                                    : [Double] = []
    var currentClipTimestamp                            : Double!
    var currentClipUploadIndex                          : Int = 0
    var videoData                                       : Data?
    var isUploading                                     : Bool = false
    let otherTaskQueue                                  = DispatchQueue(label: "com.fannerCamn.app.otherTask", qos: .background)
    var saveScoreboardData                              : [String] = []
    private var streamQueue                             : DispatchQueue!
    var recordButtonView                                : UIView?
    var recordButtonOuterView                           : UIView?
    var player                                          : AVPlayer?
    var avpController                                   = AVPlayerViewController()
    
    var isUploadingClipProcess           : Bool = false
    var uploadClip                       : [Clip] = []
    var clipsArrCount                    = 0
    var activityIndicator                : UIActivityIndicatorView!
    var notStopStreaming                 : Bool = false
    var nextUplaod                       : Bool = false
    var isQuality                        : Bool = false
    var saveRecapId                      : Int = 0
    var isLiverecap                      : Bool = false
    var selectedSport                    : String!
    var isClippingReady                  : Bool = false
    var indexClipArr                     : Int = 0
    var existingEndTime                 : CMTime!
    let defaults                        = UserDefaults.standard
    var savedLiverecap                  : [String] = []
    var isSoundLevelCall                = false
    @IBOutlet weak var img1Btn          : UIButton!
    @IBOutlet weak var img2Btn          : UIButton!
    @IBOutlet weak var durationView     : UIView!
    @IBOutlet weak var mainView         : UIView!
    @IBOutlet weak var imgArchive       : UIImageView!
    var audioRecorder                   : AVAudioRecorder!
    var levelTimer                      : Timer? = nil

    var clipsCount                       = 0
    var uploadingClip                    : [Clip]!
    var SoundMeterSlider                 : SummerSlider!
    var zoomvalue                        = CGFloat()
    
//MARK: - IBOutlets & Properties
    @IBOutlet weak var lfPreview        : UIView!   // LFLivePreview
    @IBOutlet weak var preview          : UIView!
    @IBOutlet weak var bottomBar        : UIView!
    @IBOutlet weak var toggleRecordBtn  : UIButton!
    @IBOutlet weak var timeLbl          : UILabel!
    @IBOutlet weak var exitBtn          : UIButton!
    @IBOutlet weak var undoBtn          : UIButton!
    @IBOutlet weak var toggleFlipBtn    : UIButton!
    @IBOutlet weak var zoomFactorBtn    : UIButton!
    
// properties
    private var cameraService           : CameraService!
    private var fanGenService           : FanGenerationService!
    private var fanGenView              : FanGenerationVideo!
    private var selectedMarkerType      : MarkerType = MarkerType.individual
    private var isLoaded                : Bool = false
    private var isFrontCamera           : Bool = false
    private var markerTags              : [Marker] {
        return DataManager.shared.settingsMarkers[selectedMarkerType.rawValue] ?? [Marker]()
    }
    
// live properties
    var output                          : YouTubeLiveVideoOutput!
    var scheduledStartTime              : NSDate?
    private var liveTimer               : Timer!
    private var liveTime                = 0
    
    var selectedMatch                   : SelectedMatch!
    
    var titleForWatch                   : String = ""
    var isRecorded                      : Bool = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    
//MARK: - override functions    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .landscape
        fanGenService = FanGenerationService(selectedMatch, .record)
        
        zoomFactorBtn.layer.cornerRadius = zoomFactorBtn.frame.size.height/2
        zoomFactorBtn.layer.borderColor = UIColor.white.cgColor
        zoomFactorBtn.layer.borderWidth = 1.5
        zoomFactorBtn.layer.masksToBounds = true

        FannerCamWatchKitShared.sharedManager.delegate =  self
        view.isUserInteractionEnabled = false
        
        Utiles.setHUD(true, view, .extraLight, "Configuring camera...")
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterdBG), name: Notification.Name("enterdBG"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterdFG), name: Notification.Name("enterdFG"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveTimerCountdownFromFanGenerationVideo), name: NSNotification.Name("timerCountdownValueChanged"), object: nil)
    }
    
 
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let matches = DataManager.shared.matches
        for currentMatch in matches {
            if currentMatch.id == selectedMatch.match.id {
                selectedMatch.match = currentMatch
                break
            }
        }
        isControllerActive = true
        // Setting the Title
        let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":titleForWatch, "StartDate":Date()]
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
        print(timeLbl.text)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isLoaded {
            if !isLiveMatch() {
                configCamera()
            } else {
                preview.isHidden = true
                perform(#selector(self.setEnabledElements), with: nil, afterDelay: 1.0)
                Utiles.setHUD(false)
            }
            initLayout()
            isLoaded = true
        }
        appDelegate.myOrientation = .landscape
    }
    
    //MARK: - Override functions
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == Constant.Segue.MatchesRecordSegueIdLive {
                let vc = segue.destination as! MatchesMainVideoRecordLiveVC
                vc.selectedMatch = self.selectedMatch
                vc.titleForWatch = self.navigationController?.navigationBar.topItem?.title ?? "" //  self.navigationItem.title ?? ""
            }
        }
    
//    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
//
//        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
//            switch swipeGesture.direction {
//            case .right:
//
//                if !cameraService.isRecording {
//                    print("Swiped right")
//                    isControllerActive = false
//                    if (isRecorded)
//                    {
//                        appDelegate.isSwiped = true
//                        isRecorded = false
//                    }
//                    let messageDict : [String:Any] = ["isStart":false,"isControllerActive":false]
//                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
//                    self.isLoaded = false
//                    cameraService.removeAddedInputs()
//                        if cameraService.autoExposure {
//                        }else {
//                            self.cameraService.autoExposure = !self.cameraService.autoExposure
//                        }
//                    self.performSegue(withIdentifier: Constant.Segue.MatchesRecordSegueIdLive, sender: MatchType.liveMatch)
//                }
//            case .down:
//                print("Swiped down")
//            case .left:
//
//                if !cameraService.isRecording {
//                    print("Swiped left")
//                    if !isLiveMatch() {
//                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: cameraService.currentCameraInput!.device)
//                    }
//                    isControllerActive = false
//                    if (isRecorded)
//                    {
//                        appDelegate.isSwiped = true
//                        isRecorded = false
//                    }
//                    let messageDict : [String:Any] = ["isStart":false,"isControllerActive":false]
//                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
//                    self.isLoaded = false
//                    cameraService.removeAddedInputs()
//                    if cameraService.autoExposure {
//                        }else {
//                            self.cameraService.autoExposure = !self.cameraService.autoExposure
//                        }
//                    self.performSegue(withIdentifier: Constant.Segue.MatchesRecordSegueIdLive, sender: MatchType.liveMatch)
//                }
//            case .up:
//                print("Swiped up")
//            default:
//                break
//            }
//        }
//    }
    
    deinit {
            NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    override var shouldAutorotate: Bool {
        if cameraService != nil && cameraService.isRecording {
            return false
        }else{
            return true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape{
            cameraService.updatePreviewOrientation()
        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchPer = touchPercent(touch: touches.first! as UITouch)
//        cameraService.updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touchPer = touchPercent(touch: touches.first! as UITouch)
//        cameraService.updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
//    }

//     func supportedInterfaceOrientations() -> Int {
//        print("supportedInterfaceOrientations")
//        return Int(UIInterfaceOrientationMask.landscapeLeft.rawValue)
//    }
//
//     func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
//        return UIInterfaceOrientation.landscapeLeft
//    }
    
    //MARK: - init functions
    
    func initLayout() {
        let secondWindow = UIWindow()
        secondWindow.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.size.width,
            height: UIScreen.main.bounds.size.height
        )

        let secondController = UIViewController()
        secondController.view.backgroundColor = .clear
        secondWindow.rootViewController = secondController
        secondWindow.isHidden = false
        self.appDelegate.secondWindow = secondWindow
        self.appDelegate.secondWindow?.backgroundColor = .clear
        
        recordButtonOuterView = UIView(frame:(CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)))

        let width = view.frame.width

        if UIDevice.current.userInterfaceIdiom == .pad {
            let fanGenViewWidth = recordButtonOuterView!.bounds.width - 100
            let fanGenViewHeight = recordButtonOuterView!.bounds.height
            let fanGenViewX = (view.frame.width - fanGenViewWidth) / 2
            let fanGenViewY = (view.frame.height - fanGenViewHeight) / 2
            let fanGenViewFrame = CGRect(x: fanGenViewX, y: fanGenViewY, width: fanGenViewWidth, height: fanGenViewHeight)
            fanGenView = FanGenerationVideo.instanceFromNib(fanGenViewFrame)
            self.fannerLogoConstraint.constant = 120
            self.scoreViewHeightConstraint.constant = 120
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            fanGenView = FanGenerationVideo.instanceFromNib(CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            self.scoreViewHeightConstraint.constant = 20
        }
        fanGenView.delegate = self
        fanGenView.dataSource = self
        fanGenView.initNib()
        fanGenView.setScoreboardUI(withSetting: selectedMatch.match.scoreboardSetting, nil, selectedMatch.match.fstAbbName, selectedMatch.match.sndAbbName)
    
        if self.selectedMatch.match.timerTime != nil {
            self.appDelegate.videoTimerTime = self.selectedMatch.match.timerTime
        }
        if self.selectedMatch.match.countdownTime != nil {
            self.appDelegate.videoCountdownTime = self.selectedMatch.match.countdownTime
        }
        if self.selectedMatch.match.isTimeFromCountdown != nil {
            self.appDelegate.isTimeFromCountdown = self.selectedMatch.match.isTimeFromCountdown
        }
        if self.appDelegate.isTimeFromCountdown {
            fanGenView.setCurrentMatchTime(self.selectedMatch.match.countdownTime != nil ? self.selectedMatch.match.countdownTime : self.appDelegate.videoCountdownTime)
        }
        else {
            fanGenView.setCurrentMatchTime(self.selectedMatch.match.timerTime != nil ? self.selectedMatch.match.timerTime : self.appDelegate.videoTimerTime)
        }

        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().f, team: .first)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().s, team: .second)
        fanGenView.topLeftView.isHidden = true
        fanGenView.topRightView.isHidden = true
        fanGenView.bottomLeftView.isHidden = true
        fanGenView.bottomRightView.isHidden = true
        fanGenView.bottomCenterView.isHidden = true
        validatesLayouts()
        for currentView in self.view.subviews {
            if currentView is FanGenerationVideo  {
                currentView.removeFromSuperview()
            }
        }
        recordButtonOuterView?.addSubview(fanGenView)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchToZoomRecognizer(pinchRecognizer:) ))
        pinchGesture.delegate = self
        fanGenView.addGestureRecognizer(pinchGesture)

        recordButtonView = UIView(frame: CGRect(x: recordButtonOuterView!.bounds.midX-300, y: recordButtonOuterView!.bounds.height-85 , width: 600, height: 65))
        recordButtonView?.addSubview(bottomBar)
        NSLayoutConstraint.activate([
            bottomBar.centerXAnchor.constraint(equalTo: recordButtonView!.centerXAnchor),
            bottomBar.centerYAnchor.constraint(equalTo: recordButtonView!.centerYAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 65),
            bottomBar.widthAnchor.constraint(equalToConstant: 600)
           ])
        recordButtonOuterView?.addSubview(recordButtonView!)
        secondWindow.addSubview(recordButtonOuterView!)
        secondWindow.bringSubviewToFront(recordButtonOuterView!)
        secondWindow.makeKeyAndVisible()

        let screenWidth = 25
        let frameSlider = CGRect(x: durationView.frame.origin.x ,y: 45 , width: durationView.frame.width , height:25)
//        let frameSlider = CGRect(x: bottomBar!.bounds.midX-80, y: bottomBar!.bounds.midY+10, width: 160, height: 25)
        var marksArray1 = Array<Float>()
        marksArray1 = [0,10,20,30,40,50,60,70,80]
        SoundMeterSlider = SummerSlider(frame: frameSlider)
        SoundMeterSlider.unselectedBarColor = UIColor.gray
        SoundMeterSlider.markColor = UIColor.gray
        SoundMeterSlider.markWidth = 1.0
        SoundMeterSlider.thumbTintColor = .clear
        SoundMeterSlider.markPositions = marksArray1
        recordButtonView?.addSubview(SoundMeterSlider)
        nScoreView.addSubview(fanGenView.scoreShowView)
        NSLayoutConstraint.activate([
            fanGenView.scoreShowView.centerXAnchor.constraint(equalTo: nScoreView!.centerXAnchor),
            fanGenView.scoreShowView.centerYAnchor.constraint(equalTo: nScoreView!.centerYAnchor),
            fanGenView.scoreShowView.heightAnchor.constraint(equalToConstant: 40),
            fanGenView.scoreShowView.widthAnchor.constraint(equalToConstant: 275)
           ])
//        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
//
//        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)

        levelTimer?.invalidate()
        
        if !isSoundLevelCall {
            self.soundlevel()
            isSoundLevelCall == true
        } else {
            isSoundLevelCall == true
        }
        
        recordButtonOuterView?.bringSubviewToFront(fanGenView.scoreboardSettingView)
        fanGenView.bringSubviewToFront(fanGenView.scoreboardSettingView)
        
        appDelegate.secondWindow!.addSubview(fanGenView.scoreboardSettingView)
        NSLayoutConstraint.activate([
            fanGenView.scoreboardSettingView.centerXAnchor.constraint(equalTo: recordButtonOuterView!.centerXAnchor),
            fanGenView.scoreboardSettingView.centerYAnchor.constraint(equalTo: recordButtonOuterView!.centerYAnchor),
            fanGenView.scoreboardSettingView.heightAnchor.constraint(equalToConstant: recordButtonOuterView!.bounds.height),
            fanGenView.scoreboardSettingView.widthAnchor.constraint(equalToConstant: recordButtonOuterView!.bounds.width)
           ])
                
        self.streamQueue = DispatchQueue(label: "PrepareForStream")
        saveScoreboardData = defaults.stringArray(forKey: "ScoreboardData") ?? [String]()
        if saveScoreboardData.isEmpty {
            self.fanGenView.switchScoreboard.isOn = true
            self.fanGenView.switchScoreboard.isOn = true
            self.fanGenView.switchScoreboard.isOn = true
            self.fanGenView.viewTeam1.backgroundColor =  .systemGreen
            self.fanGenView.homeColorView.backgroundColor = .systemGreen
            self.fanGenView.viewTeam2.backgroundColor = .systemRed
            self.fanGenView.awayColorView.backgroundColor = .systemRed
            self.fanGenView.switchColorDidChange(fanGenView.switchTeamColor)
            self.fanGenView.timerDidChangeSwitcher(fanGenView.switchTimer)
            
            
        }else {
            self.fanGenView.switchScoreboard.isOn = Bool(saveScoreboardData[0])!
            self.fanGenView.switchTeamColor.isOn = Bool(saveScoreboardData[1])!
            self.fanGenView.switchTimer.isOn = Bool(saveScoreboardData[2])!
            if fanGenView.switchScoreboard.isOn == false {
                fanGenView.topScoreView.isHidden = true
                fanGenView.scoreShowView.isHidden = true
            }
            if UserDefaults.standard.backgroundColorTeam1 == nil {
                fanGenView.viewTeam1.backgroundColor = .systemGreen
            }
            if UserDefaults.standard.backgroundColorTeam2 == nil {
                fanGenView.viewTeam2.backgroundColor = .systemRed
            }
            self.fanGenView.switchColorDidChange(fanGenView.switchTeamColor)
            self.fanGenView.timerDidChangeSwitcher(fanGenView.switchTimer)
            fanGenView.viewTeam1.backgroundColor = UserDefaults.standard.backgroundColorTeam1
            fanGenView.homeColorView.backgroundColor = UserDefaults.standard.backgroundColorTeam1
            fanGenView.viewTeam2.backgroundColor = UserDefaults.standard.backgroundColorTeam2
            fanGenView.awayColorView.backgroundColor = UserDefaults.standard.backgroundColorTeam2
        }
        
        let userDefaults = UserDefaults.standard
        savedLiverecap = userDefaults.stringArray(forKey: "Liverecap") ?? []
        print(savedLiverecap)
        if savedLiverecap.isEmpty {
            self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
            self.cameraService.liverecap = false
            self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true
            self.savedLiverecap = ["false" , "false" , "0"]
        }else {
            if self.savedLiverecap[0] == "false" {
                self.fanGenView.switchTimer.isOn = false
                self.fanGenView.timerDidChangeSwitcher(fanGenView.switchTimer)
            }else {
                self.fanGenView.switchTimer.isOn = true
                self.fanGenView.timerDidChangeSwitcher(fanGenView.switchTimer)
            }
            self.isLiverecap = Bool(savedLiverecap[0])!
            self.isQuality = Bool(savedLiverecap[1])!
            self.saveRecapId = UserDefaults.standard.integer(forKey: selectedMatch.match.id)
            print(isLiverecap)
            if self.saveRecapId != 0 {
                if isLiverecap == false {
                    self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
                    self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true
                    self.cameraService.liverecap = false
                    self.fanGenView.markerView.f_collectiveBtn.isHidden = false
                    self.fanGenView.markerView.f_individualBtn.isHidden = false
                    self.fanGenView.markerView.f_genericBtn.isHidden = false
                    
                    self.fanGenView.markerView.s_collectiveBtn.isHidden = false
                    self.fanGenView.markerView.s_individualBtn.isHidden = false
                    self.fanGenView.markerView.s_genericBtn.isHidden = false
                    self.isLiverecap = false
                } else {
                    self.fanGenView.markerView.f_new_collectiveBtn.isHidden = false
                    self.fanGenView.markerView.s_new_collectiveBtn.isHidden = false
                    self.fanGenView.markerView.f_collectiveBtn.isHidden = true
                    self.fanGenView.markerView.f_individualBtn.isHidden = true
                    self.fanGenView.markerView.f_genericBtn.isHidden = true
                    self.cameraService.liverecap = true
                    self.fanGenView.markerView.s_collectiveBtn.isHidden = true
                    self.fanGenView.markerView.s_individualBtn.isHidden = true
                    self.fanGenView.markerView.s_genericBtn.isHidden = true
                    self.isLiverecap = true
                }
            } else {
                self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
                self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true
                self.cameraService.liverecap = false
                self.fanGenView.markerView.f_collectiveBtn.isHidden = false
                self.fanGenView.markerView.f_individualBtn.isHidden = false
                self.fanGenView.markerView.f_genericBtn.isHidden = false
                self.fanGenView.markerView.s_collectiveBtn.isHidden = false
                self.fanGenView.markerView.s_individualBtn.isHidden = false
                self.fanGenView.markerView.s_genericBtn.isHidden = false
            }
            
        }
        
        activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true
        self.fanGenView.markerView.f_collectiveBtn.addSubview(activityIndicator)
        self.fanGenView.markerView.s_collectiveBtn.addSubview(activityIndicator)
        if self.selectedMatch.match.getFilterList().count == 0 {
            self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
            self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true
            self.fanGenView.markerView.f_collectiveBtn.isHidden = false
            self.fanGenView.markerView.f_individualBtn.isHidden = false
            self.fanGenView.markerView.f_genericBtn.isHidden = false
            self.fanGenView.markerView.s_collectiveBtn.isHidden = false
            self.fanGenView.markerView.s_individualBtn.isHidden = false
            self.fanGenView.markerView.s_genericBtn.isHidden = false
        }

        setLiverecapData()
     
        let inset: CGFloat = 70.0 // You can adjust this value as needed
        self.fanGenView.markerView.f_new_collectiveBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: 0)

        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector (tap1))  //Tap function will call when user tap on button
        let longGesture1 = UILongPressGestureRecognizer(target: self, action: #selector(long1))  //Long function will call when user long press on button.
        tapGesture1.numberOfTapsRequired = 1
        tapGesture1.numberOfTouchesRequired = 1
        img1Btn.addGestureRecognizer(tapGesture1)
        img1Btn.addGestureRecognizer(longGesture1)
        
        
        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(tap2))
        let longGesture2 = UILongPressGestureRecognizer(target: self, action: #selector(long2))
        tapGesture2.numberOfTapsRequired = 1
        tapGesture2.numberOfTouchesRequired = 1
        img2Btn.addGestureRecognizer(tapGesture2)
        img2Btn.addGestureRecognizer(longGesture2)

        // Fetch the color for backgroundColorTeam1 from UserDefaults
        if let savedColor1 = UserDefaults.standard.backgroundColorTeam1 {
            // Check if the color is not nil
            // Set the background color of homeColorView to the fetched color
            self.fanGenView.homeColorView.backgroundColor = savedColor1
        } else {
            // Handle the case where the color is not set in UserDefaults
            // You can set a default color or take some other action.
            // For example, set the background color to a default color:
            self.fanGenView.homeColorView.backgroundColor = .green
        }

        // Fetch the color for backgroundColorTeam2 from UserDefaults
        if let savedColor2 = UserDefaults.standard.backgroundColorTeam2 {
            // Check if the color is not nil
            // Set the background color of awayColorView to the fetched color
            self.fanGenView.awayColorView.backgroundColor = savedColor2
        } else {
            // Handle the case where the color is not set in UserDefaults
            // You can set a default color or take some other action.
            // For example, set the background color to a default color:
            self.fanGenView.awayColorView.backgroundColor = .red
        }
//        self.saveTimerCountdownFromFanGenerationVideo()
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.logoAdjust()
        }
    }
    
    func logoAdjust(){
        let videoSize = (view.frame.size.width,view.frame.size.height)// videoTrack?.naturalSize ?? .zeroferfvvvc fv bv
        let videoAspectRatio = videoSize.0 / videoSize.1
        let heightScreen = UIScreen.main.bounds.width //414
        let desiredWidth : CGFloat = heightScreen * CGFloat(videoAspectRatio)
        let desiredHeight : CGFloat = heightScreen

        // Get the current screen height 926 × 428 1024 × 768  812 × 375 ujhkn, m
        let screenWidth : CGFloat = UIScreen.main.bounds.size.width //414
        let screenHeight : CGFloat = UIScreen.main.bounds.size.height

        let aspectRatioWidth = (16 / 9) * screenWidth
        let nearestLowerDivisibleBy16 = Int(aspectRatioWidth / 16) * 16
        
        let xupdate = ((Int(screenHeight) - nearestLowerDivisibleBy16) / 2)
        
        let finalTrailing = xupdate/2
        logoTrailingConstraints.constant = CGFloat(finalTrailing)

    }

    
    func alertRecaplist(){
        
        appDelegate.secondWindow?.isHidden = true
        let alert = UIAlertController(title: "Alert", message: "Please select the Recap on setting match.", preferredStyle: UIAlertController.Style.alert)
        alert.modalPresentationStyle = .popover
        let selectRecapAction = UIAlertAction(title: "Select Recap", style: .default) { (selectRecapAction) in
            print(customerId)
            if customerId != 0
            {
                self.appDelegate.loginWindow = UIWindow(frame: UIScreen.main.bounds)
                let storyboard = UIStoryboard(name: "Matches", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "RecapListVC") as! RecapListVC
                let navigationController = UINavigationController(rootViewController: vc)
                self.appDelegate.secondWindow?.isHidden = false
                self.img1Btn.isUserInteractionEnabled = true
                self.img2Btn.isUserInteractionEnabled = true
                self.img1Btn.alpha = 1.0
                self.img2Btn.alpha = 1.0
                if self.cameraService.liverecap == false {
                    self.fanGenView.switchTimer.isOn = false
                    self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
                }else {
                    self.fanGenView.switchTimer.isOn = true
                    self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
                }
                self.fanGenView.markerView.f_collectiveBtn.isHidden = true
                self.fanGenView.markerView.f_individualBtn.isHidden = true
                self.fanGenView.markerView.f_genericBtn.isHidden = true
                self.cameraService.liverecap = self.cameraService.liverecap
                self.fanGenView.markerView.s_collectiveBtn.isHidden = true
                self.fanGenView.markerView.s_individualBtn.isHidden = true
                self.fanGenView.markerView.s_genericBtn.isHidden = true
                self.fanGenView.markerView.f_new_collectiveBtn.isHidden = false
                self.fanGenView.markerView.s_new_collectiveBtn.isHidden = false
                vc.selectedMatch = self.selectedMatch
                self.appDelegate.loginWindow.rootViewController = navigationController
                self.appDelegate.loginWindow.makeKeyAndVisible()
            }
            else {
                let alert = UIAlertController(title: "Alert", message: "Please sign in before continue.", preferredStyle: UIAlertController.Style.alert)
                let okButtonAction = UIAlertAction(title: "Ok", style: .default) { (okButtonAction) in
                    let vc = SettingsLoginLiverecapVC()
                    self.tabBarController?.selectedIndex = 2
                    self.appDelegate.loginWindow = UIWindow(frame: UIScreen.main.bounds)
                    let storyboard = UIStoryboard(name: "Settings", bundle: nil)
                    let initialViewController = storyboard.instantiateViewController(withIdentifier: "SettingsLoginLiverecapVC") as! SettingsLoginLiverecapVC
                    self.appDelegate.loginWindow.rootViewController = initialViewController
                    self.appDelegate.loginWindow.makeKeyAndVisible()
                }
                alert.addAction(okButtonAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        //ActionTitle.cancel.rawValue
        let cancelbtn = UIAlertAction(title: "Disable Liverecap", style: .cancel) { (cancelbtn) in
            print("cancelllll")
            self.cameraService.liverecap = !self.cameraService.liverecap
            
            if self.fanGenView.timer?.isValid == true {
                   // The timer is running, so we should stop it
                self.fanGenView.onStartBtn(self.fanGenView.startBtn)
                self.saveTimerCountdownFromFanGenerationVideo()
               }
            
            DispatchQueue.main.async {
                self.appDelegate.secondWindow?.isHidden = false
                self.img1Btn.isUserInteractionEnabled = false
                self.img2Btn.isUserInteractionEnabled = false
                self.img1Btn.alpha = 0.5
                self.img2Btn.alpha = 0.5
                
                self.fanGenView.markerView.f_collectiveBtn.isHidden = false
                self.fanGenView.markerView.f_individualBtn.isHidden = false
                self.fanGenView.markerView.f_genericBtn.isHidden = false
                
                self.fanGenView.markerView.s_collectiveBtn.isHidden = false
                self.fanGenView.markerView.s_individualBtn.isHidden = false
                self.fanGenView.markerView.s_genericBtn.isHidden = false
                
                self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
                self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true
                
                self.fanGenView.markerView.f_collectiveBtn.setImage(UIImage(named: "ic_collective_rednew"), for: .normal)
                self.fanGenView.markerView.s_collectiveBtn.setImage(UIImage(named: "ic_collective_rednew"), for: .normal)
                
                self.savedLiverecap = UserDefaults.standard.stringArray(forKey: "Liverecap") ?? []
                if self.savedLiverecap.isEmpty {
                    
                    // Set a default value
                    self.savedLiverecap = ["true", "true"]
                    // Save the default value to UserDefaults
                    UserDefaults.standard.set(self.savedLiverecap, forKey: "Liverecap")
                    
                } else {
                    self.savedLiverecap[0] = "false"
                    self.defaults.set(self.savedLiverecap, forKey: "Liverecap")
                }
                self.isLiverecap = false
                if self.cameraService.liverecap == false {
                    self.fanGenView.switchTimer.isOn = false
                    self.fanGenView.switchTimer.setOn(false, animated: true)
                    self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
                }else {
                    self.fanGenView.switchTimer.isOn = true
                    self.fanGenView.switchTimer.setOn(true, animated: true)
                    self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
                }
            }
        }
        alert.addAction(selectRecapAction)
        alert.addAction(cancelbtn)
        
        self.present(alert, animated: true, completion: nil)
    }

     func setLiverecapData() {
        if let countDictionary = UserDefaults.standard.dictionary(forKey: "CountDictionaryRecord") as? [String: Int] {
            let markerView = fanGenView.markerView! // Assuming fanGenView is an instance variable or accessible in this scope
            print(countDictionary)
            
            markerView.countf_individualLbl = countDictionary["countf_individual"] ?? 0
            markerView.countf_genericLbl = countDictionary["countf_generic"] ?? 0
            markerView.countf_collectiveLbl = countDictionary["countf_collective"] ?? 0
            
            markerView.counts_individualLbl = countDictionary["counts_individual"] ?? 0
            markerView.counts_genericLbl = countDictionary["counts_generic"] ?? 0
            markerView.counts_collectiveLbl = countDictionary["counts_collective"] ?? 0
            
            markerView.countf_new_collectiveLbl = countDictionary["countf_new_collectiveLbl"] ?? 0
            markerView.counts_new_collectiveLbl = countDictionary["counts_new_collectiveLbl"] ?? 0

            markerView.f_individualLbl.text = "\(markerView.countf_individualLbl)"
            markerView.f_genericLbl.text = "\(markerView.countf_genericLbl)"
            markerView.f_collectiveLbl.text = "\(markerView.countf_collectiveLbl)"
            
            markerView.s_individualLbl.text = "\(markerView.counts_individualLbl)"
            markerView.s_genericLbl.text = "\(markerView.counts_genericLbl)"
            markerView.s_collectiveLbl.text = "\(markerView.counts_collectiveLbl)"
            
            markerView.f_new_collectiveLbl.text = "\(markerView.countf_new_collectiveLbl)"
            markerView.s_new_collectiveLbl.text = "\(markerView.counts_new_collectiveLbl)"
        } else {
            print("CountDictionary not found")
        }
    }

    
    func saveLivrecapData() {
        let markerView = fanGenView.markerView! // Assuming fanGenView is an instance variable or accessible in this scope
        let countDictionary: [String: Int] = [
            "countf_individual":  markerView.countf_individualLbl ?? 0,
            "countf_generic":  markerView.countf_genericLbl ?? 0,
            "countf_collective":  markerView.countf_collectiveLbl ?? 0,
            "counts_individual":  markerView.counts_individualLbl ?? 0,
            "counts_generic":  markerView.counts_genericLbl ?? 0,
            "counts_collective":  markerView.counts_collectiveLbl ?? 0,
            "countf_new_collectiveLbl":  markerView.countf_new_collectiveLbl ?? 0,
            "counts_new_collectiveLbl":  markerView.counts_new_collectiveLbl ?? 0
        ]
        // Save the countDictionary in UserDefaults
        UserDefaults.standard.set(countDictionary, forKey: "CountDictionaryRecord")
    }


    
    //directory for audio recording
      func getDirectory() -> URL {
          let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
          let documentDirectory = paths[0]
          return documentDirectory
      }
    
    func soundlevel(){
        let url  = getDirectory().appendingPathComponent("audio.m4a")

        let recordSettings : [String : Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                               AVSampleRateKey: 44100,
                               AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
                   ]
        // Start Audio Recording
                do {
                    audioRecorder = try AVAudioRecorder(url: url, settings: recordSettings)
                    audioRecorder.delegate = self
                    audioRecorder.record()
                    audioRecorder.isMeteringEnabled = true
                    print("audio recording")
                } catch {
                    print("Audio recording hasn't worked")
                }
        levelTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(levelTimerCallback), userInfo: nil, repeats: true)
    }

    
    @objc func levelTimerCallback() {
        
    audioRecorder.updateMeters()
    let level = audioRecorder.averagePower(forChannel: 0) ?? -35
        SoundMeterSlider.maximumValue = 0
        SoundMeterSlider.minimumValue = -30
        SoundMeterSlider.thumbTintColor = .clear
        
        if  level <= -20 {
            SoundMeterSlider.value = level
            SoundMeterSlider.selectedBarColor = UIColor.green
              SoundMeterSlider.minimumTrackTintColor = UIColor.green
        } else if level > -20 && level <= -10 {
            SoundMeterSlider.value = level
            SoundMeterSlider.selectedBarColor = UIColor.yellow
              SoundMeterSlider.minimumTrackTintColor = UIColor.yellow
        } else if level > -10 {
              SoundMeterSlider.selectedBarColor = UIColor.red
              SoundMeterSlider.minimumTrackTintColor = UIColor.red
              SoundMeterSlider.value = level
        }else{
            SoundMeterSlider.selectedBarColor = UIColor.gray
            SoundMeterSlider.value = level
        }
    }
                                 

  
    // in recording mode
    func configCamera() {
        cameraService = CameraService(preview, timeLbl, selectedMatch.match.isResolution1280)
        cameraService.delegate = self
        cameraService.checkDeviceAuthorizationStatus { (isGranted, error) in
            if isGranted {
                self.cameraService.prepare(isFrontCamera: self.isFrontCamera, completionHandler: { (errorStr) in
                    if let err = errorStr {
                        MessageBarService.shared.error(err.localizedDescription)
                    } else {
                        do {
//                            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.cameraService.currentCameraInput!.device)
                            try self.cameraService.displayPreview()
                            NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange(notification:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.cameraService.currentCameraInput!.device)
                            self.lfPreview.isHidden = true
                            self.levelTimer?.invalidate()
                            self.soundlevel()
                        } catch {
                            MessageBarService.shared.error(error.localizedDescription)
                        }
                    }
                    Utiles.setHUD(false)
                    self.perform(#selector(self.setEnabledElements), with: nil, afterDelay: 1.0)
                })
            } else {
                MessageBarService.shared.error(error)
                Utiles.setHUD(false)
            }
        }
    }
    
    @objc func setEnabledElements() {
        view.isUserInteractionEnabled = true
    }
    
    @objc func subjectAreaDidChange(notification: NSNotification) {
        cameraService.subjectAreaDidChange(notification: notification)
    }
    
    @objc func handlePinchToZoomRecognizer(pinchRecognizer: UIPinchGestureRecognizer) {
        if !fanGenView.isDisplayedSubViews {
            let pinchVelocityDividerFactor : Float = 50.0
            
            if pinchRecognizer.state == UIGestureRecognizer.State.changed {
                cameraService.pinchToZoom(pinchRecognizer, pinchVelocityDividerFactor)
            }
        }
    }
    
//MARK: - set layout functions
    func validatesLayouts() {
        if isLiveMatch() {
            exitBtn.isEnabled = liveTimer == nil
            fanGenView.setFangenViewElements(enabled: !exitBtn.isEnabled)
        } else {
            fanGenView.setFangenViewElements(enabled: cameraService.isRecording)
            exitBtn.isEnabled = !cameraService.isRecording
        }
        exitBtn.alpha = exitBtn.isEnabled ? 1 : 0.5
    }
    
    func setUndoBtnEnabled(_ val: Bool) {
        DispatchQueue.main.async {
            self.undoBtn.isEnabled = val
            self.undoBtn.alpha = val ? 1 : 0.5
        }
    }
    
    func setToggleBtnImage(isStarted: Bool) {
        let image = isStarted ? Constant.Image.ToggleStop.image : Constant.Image.ToggleRecord.image
        toggleRecordBtn.setBackgroundImage(image, for: .normal)
    }
    
//MARK: - main fucntions
    func isLiveMatch() -> Bool {
        return selectedMatch.match.type == .liveMatch
    }
    
    func startRecording() {
        DispatchQueue.main.async{ [self] in
            self.fanGenView.isstremingPage = true
//            Utiles.setHUD(true, self.view, .extraLight, "Release recording...")
            self.toggleRecordBtn.isEnabled = false
            self.toggleFlipBtn.isEnabled = false
            self.isRecorded = true
            self.cameraService.changefps(fps: 30)
            self.cameraService.startRecording(self.fanGenService.createNewMainVideo(CMTIMESCALE, self.appDelegate.isSwiped))
        }
    }
    
 
    
//    func saveLivrecapData() {
//        let markerView = fanGenView.markerView! // Assuming fanGenView is an instance variable or accessible in this scope
//        let countDictionary: [String: Int] = [
//            "countf_individual":  markerView.countf_individualLbl ?? 0,
//            "countf_generic":  markerView.countf_genericLbl ?? 0,
//            "countf_collective":  markerView.countf_collectiveLbl ?? 0,
//            "counts_individual":  markerView.counts_individualLbl ?? 0,
//            "counts_generic":  markerView.counts_genericLbl ?? 0,
//            "counts_collective":  markerView.counts_collectiveLbl ?? 0,
//            "countf_new_collectiveLbl":  markerView.countf_new_collectiveLbl ?? 0,
//            "counts_new_collectiveLbl":  markerView.counts_new_collectiveLbl ?? 0
//        ]
//        // Save the countDictionary in UserDefaults
//        UserDefaults.standard.set(countDictionary, forKey: "CountDictionaryRecord")
//    }


    func stopRecording() {
        DispatchQueue.main.async {
//            Utiles.setHUD(true, self.view, .extraLight, "Saving recorded video...") fgrthg rtewg d shb  sz s
            self.fanGenView.isstremingPage = false
            self.saveTimerCountdownFromFanGenerationVideo()
            if self.cameraService.isRecording {
                self.cameraService.stopRecording()
            }
            self.toggleFlipBtn.isEnabled = true
            self.toggleRecordBtn.isEnabled = false
        }
    }
    
    
    @objc func saveTimerCountdownFromFanGenerationVideo() {
        if (self.fanGenView.isCountdown) {
            self.appDelegate.videoCountdownTime = String.init(format: "%02d'%02d", self.fanGenView.countdownValue / 60, self.fanGenView.countdownValue % 60)
        }
        else {
            var length = String(self.fanGenView.totalSecond / 60).count
            if (length == 3) {
                self.appDelegate.videoTimerTime = String.init(format: "%03d'%02d", self.fanGenView.totalSecond / 60, self.fanGenView.totalSecond % 60)
            }
            else {
                self.appDelegate.videoTimerTime = String.init(format: "%02d'%02d", self.fanGenView.totalSecond / 60, self.fanGenView.totalSecond % 60)
            }
        }
        self.appDelegate.isTimeFromCountdown = fanGenView.isCountdown
        self.didSaveTimerAndCountdownTime(self.appDelegate.videoTimerTime, self.appDelegate.videoCountdownTime, self.appDelegate.isTimeFromCountdown)
    }

    
    @objc func liveTimerAction() {
        liveTime += 1
        let timeNow = String( format :"%02d:%02d:%02d", liveTime/3600, (liveTime%3600)/60, liveTime%60)
        self.timeLbl.text = timeNow
    }
    
    @objc func endStreamingReaction() {
//        Utiles.setHUD(false)
        toggleRecordBtn.isEnabled = true
    }
    
    func touchPercent(touch : UITouch) -> CGPoint {
        // Get the dimensions of the screen in points
        let screenSize = UIScreen.main.bounds.size
        // Create an empty CGPoint object set to 0, 0
        var touchPer = CGPoint.zero
        // Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
        touchPer.x = touch.location(in: self.view).x / screenSize.width
        touchPer.y = touch.location(in: self.view).y / screenSize.height
        // Return the populated CGPoint
        return touchPer
    }
    
//MARK: - IBActions
    
//    @objc func focusTap(gesture: UIGestureRecognizer) {
//        if !fanGenView.isDisplayedSubViews, !isLiveMatch() {
//            cameraService.focusAndExposeTap(gestureRecognizer: gesture)
//        }
//    }
    
//    @IBAction func img1Click(_ sender: Any) {
//
//        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector (tap1))  //Tap function will call when user tap on button
//        let longGesture1 = UILongPressGestureRecognizer(target: self, action: #selector(long1))  //Long function will call when user long press on button.
//            tapGesture1.numberOfTapsRequired = 1
//            img1Btn.addGestureRecognizer(tapGesture1)
//            img1Btn.addGestureRecognizer(longGesture1)
//    }
    
    
    func avplayerView(url: URL , tag : Int) {
        self.player = AVPlayer(url: url)
        self.avpController = AVPlayerViewController()
        self.avpController.player = self.player
        avpController.view.tag = tag
        avpController.showsPlaybackControls = false
        self.imgArchive.frame = avpController.view.bounds
        self.imgArchive.addSubview(avpController.view)
        player?.play()
        
    }

    @objc func long1() {
        fanGenView.player?.replaceCurrentItem(with: nil)
        imgArchive.isHidden = true
        player?.replaceCurrentItem(with: nil)
        self.imgArchive.backgroundColor = .clear
    }
    
    @objc func tap1(){
        print("Tappppp1")
        player?.replaceCurrentItem(with: nil)
            self.imgArchive.willRemoveSubview(avpController.view)
            fanGenView.player?.replaceCurrentItem(with: nil)
            if let viewWithTag = self.avpController.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                }
            let imagesArchive1 = DataManager.shared.imgArchives
            if fanGenView.imageArchiveSelected1 == -1 {
                if imagesArchive1.count > 0 {
                    fanGenView.imageArchiveSelected1 =  0
                    imgArchive.isHidden = false
                    if imagesArchive1[0].fileName.contains(".gif") {
                        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                                viewWithTag.removeFromSuperview()
                            }
                        let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                        imgArchive.image = UIImage.gifImageWithData(data!)
                    } else if imagesArchive1[0].fileName.contains(".mov") {
                        let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                        let url = URL(fileURLWithPath: imagesArchive1[fanGenView.imageArchiveSelected1].filePath().path)
                        self.avplayerView(url: url, tag: 100)                    }else {
                        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                                viewWithTag.removeFromSuperview()
                            }
                        imgArchive.image = UIImage(contentsOfFile: imagesArchive1[0].filePath().path)
                    }
                }
            } else {
                if (fanGenView.imageArchiveSelected1 + 1) == imagesArchive1.count {
                    fanGenView.imageArchiveSelected1 =  0
                    imgArchive.isHidden = false
                    if imagesArchive1[0].fileName.contains(".gif") {
                        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                                viewWithTag.removeFromSuperview()
                            }
                        let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                        imgArchive.image = UIImage.gifImageWithData(data!)
                    } else if imagesArchive1[0].fileName.contains(".mov") {
                        let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                        let url = URL(fileURLWithPath: imagesArchive1[fanGenView.imageArchiveSelected1].filePath().path)
                        self.avplayerView(url: url, tag: 100)
                    }else {
                        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                                viewWithTag.removeFromSuperview()
                            }
                        imgArchive.image = UIImage(contentsOfFile: imagesArchive1[0].filePath().path)
                    }
                } else {
                    fanGenView.imageArchiveSelected1 += 1
                    imgArchive.isHidden = false
                    if imagesArchive1[fanGenView.imageArchiveSelected1].fileName.contains(".gif") {
                        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                                viewWithTag.removeFromSuperview()
                            }
                        let data = FileManager.default.contents(atPath: imagesArchive1[fanGenView.imageArchiveSelected1].filePath().path)
                        imgArchive.image = UIImage.gifImageWithData(data!)
                    }else if imagesArchive1[fanGenView.imageArchiveSelected1].fileName.contains(".mov") {
                        let data = FileManager.default.contents(atPath: imagesArchive1[fanGenView.imageArchiveSelected1].filePath().path)
                        let url = URL(fileURLWithPath: imagesArchive1[fanGenView.imageArchiveSelected1].filePath().path)
                        self.avplayerView(url: url, tag: 100)
                    }else {
                        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                                viewWithTag.removeFromSuperview()
                            }
                        imgArchive.image = UIImage(contentsOfFile: imagesArchive1[fanGenView.imageArchiveSelected1].filePath().path)
                    }
                }
            }
        }
    
    
//    @IBAction func img2Click(_ sender: Any) {
//        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector (tap2))
//        let longGesture2 = UILongPressGestureRecognizer(target: self, action: #selector(long2))
//        tapGesture2.numberOfTapsRequired = 1
//        tapGesture2.numberOfTouchesRequired = 1
//        img2Btn.addGestureRecognizer(tapGesture2)
//        img2Btn.addGestureRecognizer(longGesture2)
//    }
    
    @objc func long2() {
        fanGenView.player?.replaceCurrentItem(with: nil)
        imgArchive.isHidden = true
        player?.replaceCurrentItem(with: nil)
        self.imgArchive.backgroundColor = .clear
    }
    
    @objc func tap2() {
    print("Tappppp2")
    player?.replaceCurrentItem(with: nil)
    self.imgArchive.willRemoveSubview(avpController.view)
     fanGenView.player?.replaceCurrentItem(with: nil)
     if let viewWithTag = self.avpController.view.viewWithTag(100) {
             viewWithTag.removeFromSuperview()
         }
     let imagesArchive2 = DataManager.shared.imgArchives2
     if fanGenView.imageArchiveSelected2 == -1 {
         if imagesArchive2.count > 0 {
             fanGenView.imageArchiveSelected2 =  0
             imgArchive.isHidden = false
             if imagesArchive2[0].fileName.contains(".gif") {
                 if let viewWithTag = self.avpController.view.viewWithTag(100) {
                         viewWithTag.removeFromSuperview()
                     }
                 let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                 imgArchive.image = UIImage.gifImageWithData(data!)
             }
             else if imagesArchive2[0].fileName.contains(".mov") {
                 let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                 let url = URL(fileURLWithPath: imagesArchive2[fanGenView.imageArchiveSelected2].filePath().path)
                 self.avplayerView(url: url, tag: 100)
             }else {
                 if let viewWithTag = self.avpController.view.viewWithTag(100) {
                         viewWithTag.removeFromSuperview()
                     }
                 imgArchive.image = UIImage(contentsOfFile: imagesArchive2[0].filePath().path)
             }
         }
     } else {
         if (fanGenView.imageArchiveSelected2 + 1) == imagesArchive2.count {
             fanGenView.imageArchiveSelected2 =  0
             imgArchive.isHidden = false
             if imagesArchive2[0].fileName.contains(".gif") {
                 if let viewWithTag = self.avpController.view.viewWithTag(100) {
                         viewWithTag.removeFromSuperview()
                     }
                 let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                 imgArchive.image = UIImage.gifImageWithData(data!)
             }else if imagesArchive2[0].fileName.contains(".mov") {
                 let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                 let url = URL(fileURLWithPath: imagesArchive2[fanGenView.imageArchiveSelected2].filePath().path)
                 self.avplayerView(url: url, tag: 100)
//                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
             }else {
                 if let viewWithTag = self.avpController.view.viewWithTag(100) {
                         viewWithTag.removeFromSuperview()
                     }
                 imgArchive.image = UIImage(contentsOfFile: imagesArchive2[0].filePath().path)
             }
         } else {
             fanGenView.imageArchiveSelected2 += 1
             imgArchive.isHidden = false
             if imagesArchive2[fanGenView.imageArchiveSelected2].fileName.contains(".gif") {
                 if let viewWithTag = self.avpController.view.viewWithTag(100) {
                         viewWithTag.removeFromSuperview()
                     }
                 let data = FileManager.default.contents(atPath: imagesArchive2[fanGenView.imageArchiveSelected2].filePath().path)
                 imgArchive.image = UIImage.gifImageWithData(data!)
             }
             else if imagesArchive2[fanGenView.imageArchiveSelected2].fileName.contains(".mov") {
                 let data = FileManager.default.contents(atPath: imagesArchive2[fanGenView.imageArchiveSelected2].filePath().path)
                 let url = URL(fileURLWithPath: imagesArchive2[fanGenView.imageArchiveSelected2].filePath().path)
                 self.avplayerView(url: url, tag: 100)
             }else {
                 if let viewWithTag = self.avpController.view.viewWithTag(100) {
                         viewWithTag.removeFromSuperview()
                     }
                 imgArchive.image = UIImage(contentsOfFile: imagesArchive2[fanGenView.imageArchiveSelected2].filePath().path)
             }
         }
     }
 }
    
    @IBAction func onToggleRecordBtn(_ sender: UIButton) {
        if isLiveMatch() {
            if sender.isSelected {
                sender.isSelected = false
//                stopStreaming()
            } else {
                sender.isSelected = true
//                startStreaming()
            }
        } else {
            if cameraService.isRecording {
               stopRecording()
                  self.saveLivrecapData()
                
                stopScreenRecording()
                if isLiverecap == true {
                    self.isRecapListSelected = false
                }

               // let sendingData: [String : [String : Any]] = ["Data" : ["message":"Get + stopRecording", "Time":self.timeLbl.text ?? "", "Title":"AA:BB"]]
                DispatchQueue.main.async {
                    self.exitBtn.isUserInteractionEnabled = true
                    let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                print("Call  StopRecording")
                    print(self.timeLbl.text)
                }
                if isControllerActive == true {
                    let messageDict : [String:Any] = ["isStart":false]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
            } else {
                //Recapcaplist = Nil
//                if self.cameraService.liverecap == true {
//                    if let isEmptyRecapList = UserDefaults.standard.object(forKey: "isEmptyRecapList") as? Bool {
//                        // Use the retrieved Boolean value
//                        if isEmptyRecapList {
//                            // The user is logged in
//                            print("isEmptyRecapList\(isEmptyRecapList)")
//                        } else {
//                            // The user is not logged in
//                            print("isEmptyRecapList\(isEmptyRecapList)") //false
//                            self.alertViewRecaplist()
//                            return
//                        }
//                    }
//                }
                
                let userDefaults = UserDefaults.standard
                savedLiverecap = userDefaults.stringArray(forKey: "Liverecap") ?? []
                print("isLiverecap :: \(isLiverecap)")
                
                if self.savedLiverecap.isEmpty {
                    self.isLiverecap =  self.cameraService.liverecap
                }
                if self.cameraService.liverecap == true {
                    
                    if self.isRecapListSelected == false {
                        self.isRecapListSelected = true
                        self.alertRecaplist()
                    } else {
                        
                        self.startRecording()
                        
                        initialSetupAVWriter()
                        
                        startScreenRecording()
                    }
                }else {
                    self.isRecapListSelected = false
                    self.startRecording()
                    initialSetupAVWriter()
                    
                    startScreenRecording()
                }
                
                //  let sendingData: [String : [String : Any]] = ["Data" : ["message":"Get+startRecording", "Time":self.timeLbl.text ?? "", "Title":"AA:BB"]]
                DispatchQueue.main.async {
                    let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                    print(self.timeLbl.text)
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
                print("Call StartRecording")
                if isControllerActive == true {
                    let messageDict : [String:Any] = ["isStart":true]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
                
                
                
            }
        }
    }
    
    //Recapcaplist = Nil
//    func alertViewRecaplist() {
//        appDelegate.secondWindow?.isHidden = true
//        let alert = UIAlertController(title: "Alert", message: "Recaplist is empty", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//            switch action.style{
//                case .default:
//                print("default")
////                self.appDelegate.secondWindow?.isHidden = false
//                self.navigationController?.popViewController(animated: true)
////                self.appDelegate.loginWindow.isHidden = true
//                self.appDelegate.secondWindow?.isHidden = false
//                case .cancel:
//                print("cancel")
//                case .destructive:
//                print("destructive")
//            }
//        }))
//        self.present(alert, animated: true, completion: nil)REFDV CXFV
//    }
    
    
    @IBAction func onSettingBtn(_ sender: UIButton)
    {
        var topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
        topWindow?.rootViewController = UIViewController()
        topWindow?.windowLevel = UIWindow.Level.alert + 1
        appDelegate.secondWindow?.isHidden = true

        let userDefaults = UserDefaults.standard
        let typeAfter = userDefaults.stringArray(forKey: "RTMPSettingDataa")

        let sheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheetController.modalPresentationStyle = .popover

        let gridAction = UIAlertAction(title: ActionTitle.grid.rawValue, style: .default, handler: { (gridAction) in
            self.fanGenView.setGrid(hide: self.fanGenView.isDisplayedGrid() ? true : false)
            self.appDelegate.secondWindow?.isHidden = false
            topWindow?.isHidden = true
            topWindow = nil
        })
        gridAction.setValue(fanGenView.isDisplayedGrid(), forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(gridAction)

        //Add Exposure
        let exposeAction = UIAlertAction(title: ActionTitle.autoExposure.rawValue, style: .default) { (ExpoAction) in
            self.cameraService.autoExposure = !self.cameraService.autoExposure
            self.cameraService.changeAutoExposure()
            self.appDelegate.secondWindow?.isHidden = false
            topWindow?.isHidden = true
            topWindow = nil

            let button1Frame = self.fanGenView.markerView.f_collectiveBtn.frame
            let button2Frame = self.fanGenView.markerView.f_individualBtn.frame

            self.fanGenView.markerView.f_collectiveBtn.frame = button2Frame
            self.fanGenView.markerView.f_individualBtn.frame = button1Frame

            self.fanGenView.markerView.f_collectiveBtn.superview?.setNeedsLayout()
            self.fanGenView.markerView.f_individualBtn.superview?.setNeedsLayout()
        }
        exposeAction.setValue(cameraService.autoExposure, forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(exposeAction)


        //Add Reset counter
        let countResetAction = UIAlertAction(title: ActionTitle.countRest.rawValue, style: .default) { (countResetAction) in
            self.cameraService.CountReset = !self.cameraService.CountReset
            self.resetCounter()
            topWindow?.isHidden = true
            topWindow = nil
            topWindow = nil
            self.appDelegate.secondWindow?.isHidden = false
        }
        countResetAction.setValue(cameraService.CountReset, forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(countResetAction)


        
        //Add NEW Liverecap
        let liverecapAction = UIAlertAction(title: ActionTitle.liveRecap.rawValue, style: .default) { (countResetAction) in
            self.cameraService.liverecap = !self.cameraService.liverecap
            print("self.cameraService.liverecap :: \(self.cameraService.liverecap)")
            
            
            if self.fanGenView.timer?.isValid == true {
                   // The timer is running, so we should stop it
                self.fanGenView.onStartBtn(self.fanGenView.startBtn)
                self.saveTimerCountdownFromFanGenerationVideo()
               }
            
            if self.cameraService.liverecap == false {

                self.fanGenView.switchTimer.isOn = false
                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)

            }else {

                self.fanGenView.switchTimer.isOn = true
                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
            }
            
            if self.cameraService.liverecap == false {
                self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
                self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true
                
                
                self.img1Btn.isUserInteractionEnabled = false
                self.img2Btn.isUserInteractionEnabled = false
                self.img1Btn.alpha = 0.5
                self.img2Btn.alpha = 0.5
                
                self.fanGenView.markerView.f_collectiveBtn.isHidden = false
                self.fanGenView.markerView.f_individualBtn.isHidden = false
                self.fanGenView.markerView.f_genericBtn.isHidden = false
                
                self.fanGenView.markerView.s_collectiveBtn.isHidden = false
                self.fanGenView.markerView.s_individualBtn.isHidden = false
                self.fanGenView.markerView.s_genericBtn.isHidden = false
                self.isLiverecap = false
            } else {
                self.fanGenView.markerView.f_new_collectiveBtn.isHidden = false
                self.fanGenView.markerView.s_new_collectiveBtn.isHidden = false
            
                self.img1Btn.isUserInteractionEnabled = true
                self.img2Btn.isUserInteractionEnabled = true
                self.img1Btn.alpha = 1.0
                self.img2Btn.alpha = 1.0

                self.fanGenView.markerView.f_collectiveBtn.isHidden = true
                self.fanGenView.markerView.f_individualBtn.isHidden = true
                self.fanGenView.markerView.f_genericBtn.isHidden = true
                
                self.fanGenView.markerView.s_collectiveBtn.isHidden = true
                self.fanGenView.markerView.s_individualBtn.isHidden = true
                self.fanGenView.markerView.s_genericBtn.isHidden = true
                self.isLiverecap = true
            }
          
//            self.saveTimerCountdownFromFanGenerationVideo()
            
            if self.appDelegate.isTimeFromCountdown {
                self.fanGenView.setCurrentMatchTime(self.selectedMatch.match.countdownTime != nil ? self.selectedMatch.match.countdownTime : self.appDelegate.videoCountdownTime)
            }
            else {
                self.fanGenView.setCurrentMatchTime(self.selectedMatch.match.timerTime != nil ? self.selectedMatch.match.timerTime : self.appDelegate.videoTimerTime)
            }
                if customerId == 0 {
              
                    // Create the alert controller
                    let alertController = UIAlertController(title: "Alert", message: "Please Login Liverecap", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                        UIAlertAction in
                        let myBoolValue = true
                        self.defaults.set(myBoolValue, forKey: "LoginAllow")
                        self.defaults.synchronize()
                        self.appDelegate.loginWindow = UIWindow(frame: UIScreen.main.bounds)
                        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
                        let initialViewController = storyboard.instantiateViewController(withIdentifier: "SettingsLoginLiverecapVC") as! SettingsLoginLiverecapVC
                        self.appDelegate.loginWindow.rootViewController = initialViewController
                        self.appDelegate.loginWindow.makeKeyAndVisible()
                        
                        
                    }
                    //                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                    //                      UIAlertAction in
                    //                      NSLog("Cancel Pressed")
                    //                  }
                    // Add the actions
                    alertController.addAction(okAction)
                    //                  alertController.addAction(cancelAction)
                    // Present the controller
                    self.present(alertController, animated: true, completion: nil)
                    
                } else {
                    self.savedLiverecap = ["\(self.cameraService.liverecap)", "true"]
                    if self.savedLiverecap.isEmpty {
                        // Set a default value
                        self.savedLiverecap = ["true", "true"]
                        // Save the default value to UserDefaults
                        UserDefaults.standard.set(self.savedLiverecap, forKey: "Liverecap")
                        
                    }else {
                        UserDefaults.standard.set(self.savedLiverecap, forKey: "Liverecap")
                        //                self.cameraService.liverecap = !self.cameraService.liverecap
                        print("self.cameraService.liverecap savedLiverecap ::: \(self.savedLiverecap)")
                    }
                    topWindow?.isHidden = true
                    topWindow = nil
                    topWindow = nil
                    self.appDelegate.secondWindow?.isHidden = false
            }
        }
        if cameraService.isRecording {
            liverecapAction.isEnabled = false
        }else {
            liverecapAction.isEnabled = true
        }
       
        if self.cameraService.liverecap == false {
            liverecapAction.setValue( false, forKey: SheetKeys.isChecked.rawValue)
        }else {
            liverecapAction.setValue(true, forKey: SheetKeys.isChecked.rawValue)
        }
        

        
        liverecapAction.setValue(cameraService.liverecap, forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(liverecapAction)


        //Add LIVERECAP
//        let liverecapAction = UIAlertAction(title: ActionTitle.liveRecap.rawValue, style: .default) { (liverecapAction) in
//            print(customerId)
//
//
//            if customerId != 0 {
//
//                let recapId = 0//UserDefaults.standard.integer(forKey: self.selectedMatch.match.id)
//                print(recapId)
//                if recapId == 0
//                {
//
//                    let alert = UIAlertController(title: "Alert", message: "Please select the Recap on setting match.", preferredStyle: UIAlertController.Style.alert)
//
//                    alert.modalPresentationStyle = .popover
//                    let selectRecapAction = UIAlertAction(title: "Select Recap", style: .default) { (selectRecapAction) in
//                        print(customerId)
//                        if customerId != 0
//                        {
//
//                            self.appDelegate.loginWindow = UIWindow(frame: UIScreen.main.bounds)
//
//                            let storyboard = UIStoryboard(name: "Matches", bundle: nil)
//                            let vc = storyboard.instantiateViewController(withIdentifier: "RecapListVC") as! RecapListVC
//
//                            let navigationController = UINavigationController(rootViewController: vc)
//
//                            self.appDelegate.secondWindow?.isHidden = false
//
//                            self.img1Btn.isUserInteractionEnabled = true
//                            self.img2Btn.isUserInteractionEnabled = true
//
//                            self.img1Btn.alpha = 1.0
//                            self.img2Btn.alpha = 1.0
//
//                            self.savedLiverecap[0] = "true"
//
//                            if self.savedLiverecap[0] == "false" {
//
//                                self.fanGenView.switchTimer.isOn = false
//                                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
//
//                            }else {
//
//                                self.fanGenView.switchTimer.isOn = true
//                                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
//                            }
//
//
//                            self.fanGenView.markerView.f_collectiveBtn.isHidden = true
//                            self.fanGenView.markerView.f_individualBtn.isHidden = true
//                            self.fanGenView.markerView.f_genericBtn.isHidden = true
//
//                            self.cameraService.liverecap = self.cameraService.liverecap
//
//                            self.fanGenView.markerView.s_collectiveBtn.isHidden = true
//                            self.fanGenView.markerView.s_individualBtn.isHidden = true
//                            self.fanGenView.markerView.s_genericBtn.isHidden = true
//
//                            self.fanGenView.markerView.f_new_collectiveBtn.isHidden = false
//                            self.fanGenView.markerView.s_new_collectiveBtn.isHidden = false
//
//                            vc.selectedMatch = self.selectedMatch
//                            self.appDelegate.loginWindow.rootViewController = navigationController
//                            self.appDelegate.loginWindow.makeKeyAndVisible()
//
//
//                        }
//                        else {
//                            let alert = UIAlertController(title: "Alert", message: "Please sign in before continue.", preferredStyle: UIAlertController.Style.alert)
//
//                            let okButtonAction = UIAlertAction(title: "Ok", style: .default) { (okButtonAction) in
//                                let vc = SettingsLoginLiverecapVC()
//
//                                self.tabBarController?.selectedIndex = 2
//                                self.appDelegate.loginWindow = UIWindow(frame: UIScreen.main.bounds)
//                                let storyboard = UIStoryboard(name: "Settings", bundle: nil)
//                                let initialViewController = storyboard.instantiateViewController(withIdentifier: "SettingsLoginLiverecapVC") as! SettingsLoginLiverecapVC
//
//                                self.appDelegate.loginWindow.rootViewController = initialViewController
//                                self.appDelegate.loginWindow.makeKeyAndVisible()
//                            }
//                            alert.addAction(okButtonAction)
//                            self.present(alert, animated: true, completion: nil)
//                        }
//
//                    }
//
//
//                    //ActionTitle.cancel.rawValue
//                    let cancelbtn = UIAlertAction(title: "Disable Liverecap", style: .cancel) { (cancelbtn) in
//                        print("cancelllll")
//                        self.cameraService.liverecap = !self.cameraService.liverecap
//                        DispatchQueue.main.async {
//                            self.appDelegate.secondWindow?.isHidden = false
//
//                            self.img1Btn.isUserInteractionEnabled = false
//                            self.img2Btn.isUserInteractionEnabled = false
//
//                            self.img1Btn.alpha = 0.5
//                            self.img2Btn.alpha = 0.5
//
//
//                        self.fanGenView.markerView.f_collectiveBtn.isHidden = false
//                        self.fanGenView.markerView.f_individualBtn.isHidden = false
//                        self.fanGenView.markerView.f_genericBtn.isHidden = false
//
//                        self.fanGenView.markerView.s_collectiveBtn.isHidden = false
//                        self.fanGenView.markerView.s_individualBtn.isHidden = false
//                        self.fanGenView.markerView.s_genericBtn.isHidden = false
//
//
//                        self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
//                        self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true
//
//                        self.fanGenView.markerView.f_collectiveBtn.setImage(UIImage(named: "ic_collective_rednew"), for: .normal)
//                        self.fanGenView.markerView.s_collectiveBtn.setImage(UIImage(named: "ic_collective_rednew"), for: .normal)
////                            print(self.savedLiverecap)
//
//                            self.savedLiverecap = UserDefaults.standard.stringArray(forKey: "Liverecap") ?? []
//                            if self.savedLiverecap.isEmpty {
//
//                                    // Set a default value
//                                    self.savedLiverecap = ["true", "true"]
//
//                                    // Save the default value to UserDefaults
//                                UserDefaults.standard.set(self.savedLiverecap, forKey: "Liverecap")
//
//
//                            } else {
//                                self.savedLiverecap[0] = "false"
//                                    print(self.savedLiverecap)
//                                self.defaults.set(self.savedLiverecap, forKey: "Liverecap")
//                                print(self.savedLiverecap)
//                            }
//
//
//                            if self.savedLiverecap[0] == "false" {
//
//                                self.fanGenView.switchTimer.isOn = false
//                                self.fanGenView.switchTimer.setOn(false, animated: true)
//                                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
//
//                            }else {
//                                self.fanGenView.switchTimer.isOn = true
//                                self.fanGenView.switchTimer.setOn(true, animated: true)
//                                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
//                            }
//                        }
//                        print(self.savedLiverecap)
//
//                    }
//
//                    alert.addAction(selectRecapAction)
//                    alert.addAction(cancelbtn)
//
//                    if let presenter = alert.popoverPresentationController {
//                        presenter.sourceView = sender
//                        presenter.sourceRect = sender.bounds
//                    }
//
//                    self.present(alert, animated: true, completion: nil)
//                    return;0
//                }
//
//                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//                alert.modalPresentationStyle = .popover
//                let highAction = UIAlertAction(title: ActionTitle.standarQuality.rawValue, style: .default) { (highAction) in
////                    self.createVideo(true, generator)
//                }
//                let meAction = UIAlertAction(title: ActionTitle.webQuality.rawValue, style: .default) { (meAction) in
////                    self.createVideo(false, generator)
//                }
//                alert.addAction(UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel, handler: nil))
//                alert.addAction(highAction)
//                alert.addAction(meAction)
//                if let presenter = alert.popoverPresentationController {
//                    presenter.sourceView = sender
//                    presenter.sourceRect = sender.bounds
//                }
//                self.present(alert, animated: true, completion: nil)
//            }else{
//
//                // Create the alert controller
//                let alertController = UIAlertController(title: "Alert", message: "Please Login Liverecap", preferredStyle: .alert)
//
//                let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
//                      UIAlertAction in
//
//                    let myBoolValue = true
//                    self.defaults.set(myBoolValue, forKey: "LoginAllow")
//                    self.defaults.synchronize()
//                    NSLog("OK Pressed")
//
//                    self.appDelegate.loginWindow = UIWindow(frame: UIScreen.main.bounds)
//                    let storyboard = UIStoryboard(name: "Settings", bundle: nil)
//                    let initialViewController = storyboard.instantiateViewController(withIdentifier: "SettingsLoginLiverecapVC") as! SettingsLoginLiverecapVC
//                    self.appDelegate.loginWindow.rootViewController = initialViewController
//                    self.appDelegate.loginWindow.makeKeyAndVisible()
//
//
//                  }
////                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
////                      UIAlertAction in
////                      NSLog("Cancel Pressed")
////                  }
//                  // Add the actions
//                  alertController.addAction(okAction)
//
////                  alertController.addAction(cancelAction)
//
//                  // Present the controller
//                self.present(alertController, animated: true, completion: nil)
//            }
//        }
//
//
//        if cameraService.isRecording {
//            liverecapAction.isEnabled = false
//        }else {
//            liverecapAction.isEnabled = true
//        }
//        if self.savedLiverecap[0] == "false" {
//            liverecapAction.setValue(!cameraService.liverecap, forKey: SheetKeys.isChecked.rawValue)
//        }else {
//            liverecapAction.setValue(cameraService.liverecap, forKey: SheetKeys.isChecked.rawValue)
//        }
////        liverecapAction.setValue(cameraService.liverecap, forKey: SheetKeys.isChecked.rawValue)
//        sheetController.addAction(liverecapAction)

        //Add Scoreboard
        let scoreboardAction = UIAlertAction(title: ActionTitle.scoreboardSettings.rawValue, style: .default) { (scoreboardAction) in
            self.appDelegate.secondWindow?.isHidden = false
            self.cameraService.scoreboard = self.cameraService.scoreboard
            if self.savedLiverecap[0] == "false" {
                self.fanGenView.switchTimer.isOn = false
                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
            }else {
                self.fanGenView.switchTimer.isOn = true
                self.fanGenView.timerDidChangeSwitcher(self.fanGenView.switchTimer)
            }
            self.fanGenView.displayScoreboardSettingView(self.fanGenService.selectedMatch.match.scoreboardSetting, selectedMatch: self.fanGenService.selectedMatch)
            self.didTapScoreboard(self.fanGenView)
            self.view.sendSubviewToBack(self.bottomBar)
            topWindow?.isHidden = true
            topWindow = nil
        }
        
        if self.cameraService.liverecap == false {
            scoreboardAction.isEnabled = false
        }else {
            scoreboardAction.isEnabled = true
        }
       
        scoreboardAction.setValue(cameraService.scoreboard, forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(scoreboardAction)

        let cancelAction = UIAlertAction(title: ActionTitle.cancel.rawValue, style: .cancel){ (cancelAction) in
            self.appDelegate.secondWindow?.isHidden = false
            topWindow?.isHidden = true
            topWindow = nil
        }
        sheetController.addAction(cancelAction)
        if let presenter = sheetController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        topWindow?.makeKeyAndVisible()
        topWindow?.rootViewController?.present(sheetController, animated: true, completion: nil)
    }
    
    func resetCounter() {
        let markerView = fanGenView.markerView! // Assuming fanGenView is an instance variabldfgderte or accessible in this scope
        markerView.countf_individualLbl = 0
        markerView.countf_genericLbl = 0
        markerView.countf_collectiveLbl = 0
        markerView.counts_individualLbl = 0
        markerView.counts_genericLbl = 0
        markerView.counts_collectiveLbl = 0
        markerView.countf_new_collectiveLbl = 0
        markerView.counts_new_collectiveLbl = 0
        
        markerView.f_individualLbl.text = "\(markerView.countf_individualLbl)"
        markerView.f_genericLbl.text = "\(markerView.countf_genericLbl)"
        markerView.f_collectiveLbl.text = "\(markerView.countf_collectiveLbl)"
        markerView.s_individualLbl.text = "\(markerView.counts_individualLbl)"
        markerView.s_genericLbl.text = "\(markerView.counts_genericLbl)"
        markerView.s_collectiveLbl.text = "\(markerView.counts_collectiveLbl)"
        markerView.f_new_collectiveLbl.text = "\(markerView.countf_new_collectiveLbl)"
        markerView.s_new_collectiveLbl.text = "\(markerView.counts_new_collectiveLbl)"
        
        let countDictionary: [String: Int] = [
            "countf_individual": markerView.countf_individualLbl,
            "countf_generic": markerView.countf_genericLbl,
            "countf_collective": markerView.countf_collectiveLbl,
            "counts_individual": markerView.counts_individualLbl,
            "counts_generic": markerView.counts_genericLbl,
            "counts_collective": markerView.counts_collectiveLbl,
            "countf_new_collectiveLbl": markerView.countf_new_collectiveLbl,
            "counts_new_collectiveLbl": markerView.counts_new_collectiveLbl
        ]
        UserDefaults.standard.set(countDictionary, forKey: "CountDictionaryRecord")
    }

    @IBAction func onUndoBtn(_ sender: UIButton) {
        MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure you want to remove the last clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
            let (undoMarker, undoTeam) = self.fanGenService.getLastClipInfo()
            self.fanGenView.undoAnimation(undoMarker, undoTeam)
            self.setUndoBtnEnabled(self.fanGenService.undoAction())
        }, onNo: nil)
    }
    
    @IBAction func onBackBtn(_ sender: Any) {
        
        if fanGenView.timer?.isValid == true {
               // The timer is running, so we should stop it
            self.fanGenView.onStartBtn(self.fanGenView.startBtn)
            self.saveTimerCountdownFromFanGenerationVideo()
           }

        self.defaults.set(self.savedLiverecap, forKey: "Liverecap")
        self.appDelegate.loginWindow = nil
        self.appDelegate.secondWindow = nil
        levelTimer?.invalidate()
        levelTimer = nil
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .portrait
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onFlipCameraBtn(_ sender: Any) {
            if !isLiveMatch(){
//                Utiles.setHUD(true, view, .extraLight, "Load camera...")
                isFrontCamera = !isFrontCamera
                self.cameraService.removeAddedInputs()
                configCamera()
                levelTimer?.invalidate()
                if !isSoundLevelCall {
                    self.soundlevel()
                    isSoundLevelCall == true
                } else {
                    isSoundLevelCall == true
            }
        }
    }
    
    func accessSavedClip(index: Int) {
        print("process for uploading: \(currentClipUploadIndex)")
        self.videoData = nil
        do {
            let clipURL = clipUrlArray[currentClipUploadIndex]
            self.videoData = try Data(contentsOf: clipURL)
            self.uploadClip = self.fanGenService.clipsArr
            self.currentClipTimestamp = timestampArr[currentClipUploadIndex]
            self.sendToLiverecapVideoSelection(quality: self.isQuality, index: self.currentClipUploadIndex, ClipURL: clipURL)
            
        } catch {
            print("Error accessing video data: \(error)")
            self.uploadingIndexStatus = self.uploadingIndexStatus-1
            self.toggleRecordBtn.isUserInteractionEnabled = true

            if self.uploadingIndexStatus == 0 {
                self.currentClipUploadIndex = 0
                self.uploadingIndexStatus = 0
                self.clipUrlArray.removeAll()
                DispatchQueue.main.async{
                  self.exitBtn.setTitle("Exit", for: .normal)
                  self.toggleRecordBtn.alpha = 1.0
                  self.toggleFlipBtn.isUserInteractionEnabled = true
                    self.exitBtn.alpha = 0.5
                  self.exitBtn.isUserInteractionEnabled = false
                                    
                }
                self.isUploading = false
            } else {
                self.isUploading = true
                self.currentClipUploadIndex = self.currentClipUploadIndex + 1
               
                DispatchQueue.main.async {
                    self.exitBtn.setTitle("\(self.uploadingIndexStatus)", for: .normal)
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    self.accessSavedClip(index: self.currentClipUploadIndex)
                    self.toggleRecordBtn.alpha = 0.5
                    self.toggleFlipBtn.isUserInteractionEnabled = false
                    self.exitBtn.alpha = 0.5
                    self.exitBtn.isUserInteractionEnabled = false
                }
            }
        }
    }
    private func saveToPhotos(tempURL: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
        } completionHandler: { success, error in
            if success == true {
                print("Saved rolling clip to photos")
            } else {
                print("Error exporting clip to Photos \(String(describing: error))")
            }
        }
    }
    
       func sendToLiverecapVideoSelection(quality: Bool , index : Int , ClipURL : URL) {
              self.isUploadingClipProcess = true
              let selectedClips = uploadClip[index]//selectedMatch.match.clips.filter { $0.isSelected }
           print(selectedClips)
              otherTaskQueue.async {
                  let generator = VideoProcess([selectedClips], self.selectedMatch.match)
                  self.createClipsForLiverecap(quality, generator, ClipURL: ClipURL)
              }
          }

    func createClipsForLiverecap(_ highBitrate: Bool, _ generator: VideoProcess ,  ClipURL : URL) {
        func generatingVideoClip() {
            dirManager.clearTempDir()
            otherTaskQueue.async {
                let newVideo = Video(self.selectedMatch.match.namePresentation(), highBitrate, self.selectedMatch.match.quality())
                // - pre clip video
                if self.selectedMatch.match.preClip.isExistingPreClipFile(), self.selectedMatch.match.preClip.isSelected {
                    self.UploadVideoToServer(highBitrate, newVideo, 0, generator, false)
                }
                else
                {
                    self.UploadVideoToServer(highBitrate, newVideo, 0, generator, false)
                }
            }
        }
        otherTaskQueue.async { [weak self] in
            guard let self = self else { return }
            generatingVideoClip()
        }
        
    }
          
       
    func UploadVideoToServer(_ highBitrate: Bool, _ newVideo: Video, _ index: Int, _ generator: VideoProcess, _ isPreClip: Bool) {
        let oWebManager: AlamofireManager = AlamofireManager()
        let timeoutTimer = DispatchSource.makeTimerSource(queue: .main)
        timeoutTimer.setEventHandler {
            if !self.uploadCompleted {
                print("Upload timed out")
                oWebManager.cancelTask()
            }
            // End the dispatch group to allow further processing
            //                   self.uploadGroup.leave()
        }
        timeoutTimer.schedule(deadline: .now() + timeoutInSeconds)
        timeoutTimer.resume()
        
        do {
            let base64Encoded = self.videoData?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            var clip : Clip!
            let recapId = UserDefaults.standard.integer(forKey: self.selectedMatch.match.id)
            var teamName = ""
            var clipTag = ""
            var tagName = ""
            var duration : Float64!
            
            if !isPreClip
            {
                clip = generator.clips[index]
                //  teamName = clip.team == .first ? self.selectedMatch.match.fstName : self.selectedMatch.match.sndName
                DispatchQueue.main.async() {
                    if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.f_new_collectiveBtn {
                        clip.team == .first
                        teamName = self.selectedMatch.match.fstName
                    }
                    if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.s_new_collectiveBtn {
                        clip.team == .second
                        teamName = self.selectedMatch.match.sndName
                    }
                }
                if let tag = clip.clipTag{
                    clipTag = String(describing: tag)
                }
                tagName = "\(clip.titleDescription()) \(clipTag)"
                if let marker = clip.marker {
                    duration = marker.duration
                }
            }
            // API call
            let strUrl: String = getServerBaseUrl() + getCreateClipURL()
            var logoTeam1 : UIImage?
            if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath(.first)) {
                logoTeam1 = img
            } else {
                logoTeam1 = Constant.Image.DefaultTeamLogo.image
            }
            
            var logoTeam2 : UIImage?
            if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath(.second)) {
                logoTeam2 = img
            } else {
                logoTeam2 = Constant.Image.DefaultTeamLogo.image
            }
            
            var logoEvent : UIImage?
            if let img = VideoProcess.loadImg(from: self.selectedMatch.match.matchLogoPath()) {
                logoEvent = img
            } else {
                logoEvent = Constant.Image.DefaultTeamLogo.image
            }
            
            let Tags : [String]! = []

            DispatchQueue.main.async {
                let scoreFirstTeam  = self.fanGenView.fGoalsLbl.text!
                let scoreSecondTeam = self.fanGenView.sGoalsLbl.text!
                self.clipCurrentScore = "\(scoreFirstTeam) - \(scoreSecondTeam)"
            }
            
            // "score": !isPreClip ? self.selectedMatch.match.scoreDescription(clip.getEndTimeInMatch()) : "",
            let postParam = [
                "team1": generator.match.fstName ?? "",
                "team2": generator.match.sndName ?? "",
                "logoTeam1": self.convertImageToBase64String(img: logoTeam1!),
                "logoTeam2": self.convertImageToBase64String(img: logoTeam2!),
                "eventName": self.selectedMatch.match.namePresentation(),
                "logoEvent": self.convertImageToBase64String(img: logoEvent!),
                "score": !isPreClip ? self.clipCurrentScore! : "",
                "minutesOfTheMatch": !isPreClip ? clip.period ?? "" : "",
                "tags": Tags ?? [],
                "duration": duration ?? 0,
                "resolution": self.selectedMatch.match.quality() == AVAssetExportPreset1280x720 ? "720" : "1080",
                "frameRate": 0,
                "bitRate": 0,
                "device": "",
                "geoLocation": "",
                "isRecapMain": false,
                "recapId": recapId,
                "customerId": customerId,
                "clipTitle": !isPreClip ? "\(teamName), \(tagName)" : "Pre clip",
                "clipDescription": !isPreClip ? "\(teamName), \(tagName)" : "Pre clip",
                "clipFile": base64Encoded,
                "creationDate": self.currentClipTimestamp
            ] as [String : Any]
            
            
            print("Team 1:", postParam["team1"] ?? "")
            print("Team 2:", postParam["team2"] ?? "")
            print("Event Name:", postParam["eventName"] ?? "")
            print("score:", postParam["score"] ?? "")
            print(postParam["minutesOfTheMatch"])
            print(postParam["tags"])
            print(postParam["duration"])
            print(postParam["resolution"])
            print(postParam["recapId"])
            print(postParam["customerId"])
            print(postParam["clipTitle"])
            print(postParam["clipDescription"])
            
            // Start the upload within the dispatch group
            uploadGroup.enter()
            
            oWebManager.requestPost(strUrl, parameters: postParam) { (jsonResult) in
                if let errorMessage = jsonResult["errorMessage"] as? String
                {
                    if errorMessage.isEmpty
                    {
                        if isPreClip
                        {
                            //self.clipVideosForLiverecap(highBitrate, newVideo, 0, generator, false)efrwe eudhqw9j
                        }
                        else
                        {
                            if index == generator.clips.count - 1 {
                                timeoutTimer.cancel()
                                
                                self.notificationQueue.async {
//                                    MessageBarService.shared.notify ("Finished uploading!").self
                                    DispatchQueue.main.async {
                                        self.exitBtn.backgroundColor = .systemGreen
                                        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                                            self.exitBtn.backgroundColor = .systemRed
                                        }
                                    }
                                }
                                self.uploadingIndexStatus = self.uploadingIndexStatus-1
                                self.toggleRecordBtn.isUserInteractionEnabled = true

                                if self.uploadingIndexStatus == 0 {
                                    self.currentClipUploadIndex = 0
                                    self.uploadingIndexStatus = 0
                                    self.fanGenService.clipsArr.removeAll()
                                    self.clipUrlArray.removeAll()
                                    DispatchQueue.main.async{
                                        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                                            self.exitBtn.setTitle("Exit", for: .normal)
                                            self.toggleRecordBtn.alpha = 1.0
                                            self.toggleFlipBtn.isUserInteractionEnabled = true
                                            self.exitBtn.alpha = 0.5
                                            self.exitBtn.isUserInteractionEnabled = false
                                        }
                                    }
                                    self.isUploading = false
                                } else {
                                    self.isUploading = true
                                    self.currentClipUploadIndex = self.currentClipUploadIndex + 1
                                    print(self.currentClipUploadIndex)
                                    DispatchQueue.main.async {
                                        self.exitBtn.setTitle("\(self.uploadingIndexStatus)", for: .normal)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                        self.accessSavedClip(index: self.currentClipUploadIndex)
                                        self.toggleRecordBtn.alpha = 0.5
                                        self.toggleFlipBtn.isUserInteractionEnabled = false
                                        self.exitBtn.alpha = 0.5
                                        self.exitBtn.isUserInteractionEnabled = false
                                    }
                                    //  self.UploadVideoToServer(highBitrate, newVideo, 0, generator, false)
                                }
                                //  self.endUpload()
                            }
                        }
                    }
                    else
                    {
                        print("errorMessage :: \(errorMessage)")
                        //                                  Utiles.setHUD("Finished uploading...")
                        //                                  Utiles.setHUD(false)
                        self.exitBtn.isEnabled = true
                        self.notificationQueue.async {
                            MessageBarService.shared.error("Failed to upload clip. The reason: " + errorMessage)
                        }
                        //print("Failed to upload clip. The reason: + \(errorMessage)")
                        //self.endUpload()
                        
                        self.uploadingIndexStatus = self.uploadingIndexStatus-1
                        self.toggleRecordBtn.isUserInteractionEnabled = true

                        if self.uploadingIndexStatus == 0 {
                            self.currentClipUploadIndex = 0
                            self.uploadingIndexStatus = 0
                            self.clipUrlArray.removeAll()
                            DispatchQueue.main.async{
                                self.exitBtn.setTitle("Exit", for: .normal)
                                self.toggleRecordBtn.alpha = 1.0
                                self.toggleFlipBtn.isUserInteractionEnabled = true
                                self.exitBtn.alpha = 0.5
                                self.exitBtn.isUserInteractionEnabled = false
                                
                            }
                            self.isUploading = false
                        } else {
                            self.isUploading = true
                            self.currentClipUploadIndex = self.currentClipUploadIndex + 1
                            
                            DispatchQueue.main.async {
                                self.exitBtn.setTitle("\(self.uploadingIndexStatus)", for: .normal)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                                self.accessSavedClip(index: self.currentClipUploadIndex)
                                self.toggleRecordBtn.alpha = 0.5
                                self.toggleFlipBtn.isUserInteractionEnabled = false
                                self.exitBtn.alpha = 0.5
                                self.exitBtn.isUserInteractionEnabled = false
                            }
                            //self.UploadVideoToServer(highBitrate, newVideo, 0, generator, false) s jhm bnkv ,j hmhj
                        }
                    }
                }
            }
            
        } catch {
            print(error)
            return
        }
        uploadGroup.leave()
    }
    
//    DispatchQueue.main.async{
//        self.exitBtn.backgroundColor = .systemGreen
//        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
//            self.exitBtn.backgroundColor = .systemRed
//        }
//    }
    
    
    func convertImageToBase64String (img: UIImage) -> String {
        return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }

    
}

extension MatchesMainVideoRecordVC {


    private func startScreenRecording() {
        if isRecording() {
            print("Attempting To start recording while recording is in progress")
            return
        }
        if #available(iOS 15.0, *) {
            RPScreenRecorder.shared().isMicrophoneEnabled = true
            RPScreenRecorder.shared().startCapture { [weak self] cmSampleBuffer, rpSampleBufferType, err in
                guard let self = self else { return }
                self.handleSampleBuffer(cmSampleBuffer, sampleType: rpSampleBufferType)
 
            }

        }
    }
    
    
    func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer, sampleType: RPSampleBufferType) {
//            guard let self = self else { return }
            switch sampleType {
            case .video:
                // Handle video sample buffer
                if clipProcessing == false {
                    if CMSampleBufferDataIsReady(sampleBuffer) {
                        if self.videoWriter.status == .unknown {
                            self.videoWriter.startWriting()
                            self.videoWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                        }
                        if self.videoWriter.status == .failed {
                            print("Error occurred, status = \(self.videoWriter.status.rawValue), \(self.videoWriter.error?.localizedDescription ?? "Unknown error")")
                            return
                        }
                        
                        if sampleType == .video, self.videoWriterInput!.isReadyForMoreMediaData {
                            self.videoWriterInput?.append(sampleBuffer)
                            
                        }
                    }
                }
                
            case .audioApp, .audioMic:
                // Handle audio sample buffer
                // Add audio microphone buffer to AVAssetWriter Audio Inpu
                if clipProcessing == false {
                    if sampleType == .audioMic, self.audioWriterInput!.isReadyForMoreMediaData {
//                        print("MIC BUFFER RECEIVED")
//                        print("Audio Buffer Came")
                        self.audioWriterInput?.append(sampleBuffer)
                    }
                }
            }
    }
    
    //pad
//    func cropVideoWidth(from videoURL: URL, to outputURL: URL, completion: @escaping (Error?) -> Void){
//        let asset = AVAsset(url: videoURL)
//        // Video track
//        let composition = AVMutableComposition()
//        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        if let videoAssetTrack = asset.tracks(withMediaType: .video).first {
//            try? videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoAssetTrack, at: .zero)
//        }
//        // Audio track
//        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//        if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
//            try? audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioAssetTrack, at: .zero)
//        }
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            let videoSize = videoTrack?.naturalSize ?? .zero
//            print("videoSize :: \(videoSize)")
//            let transform = videoTrack?.preferredTransform ?? .identity
//            let videoAspectRatio = videoSize.width / videoSize.height
//
//            // Get the current screen width
//            let screenWidth: CGFloat = UIScreen.main.bounds.size.width
//            let screenHeight: CGFloat = UIScreen.main.bounds.size.height
//            print("screenWidth :: \(screenHeight)")
//
//            // Specify the desired aspect ratio
//            let aspectRatioWidth: CGFloat = 4.0
//            let aspectRatioHeight: CGFloat = 3.0
//
//            let newCropHeight = (screenHeight * aspectRatioHeight) / aspectRatioWidth //610
//
//            let cropAmount = (videoSize.height - newCropHeight) / 2.0
//            print("cropAmount :: \(cropAmount)")
//            // Apply the crop to the video track
//            let instruction = AVMutableVideoCompositionInstruction()
//            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
//
//            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
//            let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
//            let translate = CGAffineTransform(translationX: 0, y: -cropAmount) // Crop equally from top and bottom
//            transformer.setTransform(scale.concatenating(translate), at: .zero)
//            instruction.layerInstructions = [transformer]
//
//            videoComposition = AVMutableVideoComposition()
//            videoComposition.instructions = [instruction]
//            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//            videoComposition.renderSize = CGSize(width: screenWidth, height: newCropHeight)
//        } else {
//            let videoSize = videoTrack?.naturalSize ?? .zero
//            let transform = videoTrack?.preferredTransform ?? .identity
//            let videoAspectRatio = videoSize.width / videoSize.height
//
//            let heightScreen = UIScreen.main.bounds.height
//            let desiredWidth : CGFloat = CGFloat(heightScreen) * videoAspectRatio
//            let desiredHeight : CGFloat = CGFloat(heightScreen)
//
//            // Specify the desired aspect ratio
//            let aspectRatioWidth: CGFloat = 16.0
//            let aspectRatioHeight: CGFloat = 9.0
//
//            // Get the current screen height 926 × 428 1024 × 768  812 × 375
//            let screenHeight : CGFloat = UIScreen.main.bounds.size.height
//            let screenWidth : CGFloat = UIScreen.main.bounds.size.width
//
////             Calculate the targetScreenWidth to maintain the desired aspect ratio
//            let targetScreenWidth = (screenHeight * aspectRatioWidth) / aspectRatioHeight
//            let xupdate = (screenWidth - targetScreenWidth) / 2
//            print("xupdate : \(xupdate)")
////
//
////            print("16:9 :: \(desiredHeight)")
//////            let desiredHeight: CGFloat = heightScreen // The target height
////            let aspectRatioWidth = (16 / 9) * desiredHeight
////
////            print("aspectRatioWidth \(aspectRatioWidth)")
////
//////            let number = 666.67
////            let nearestLowerDivisibleBy16 = Int(aspectRatioWidth / 16) * 16
////            print("nearestLowerDivisibleBy16 \(nearestLowerDivisibleBy16)")
////
////            let xupdate = (Int(screenWidth) - nearestLowerDivisibleBy16) / 2
////            print("xupdate : \(xupdate)")
////            print("Width for 16:9 aspect ratio at a height of \(desiredHeight) is: \(aspectRatioWidth)")
//
//
//
//            // Apply the crop to the video track
//            let instruction = AVMutableVideoCompositionInstruction()
//            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
//
//            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
//            let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
//            let translate = CGAffineTransform(translationX: CGFloat(-xupdate), y: 0)
//            transformer.setTransform(scale.concatenating(translate), at: .zero)
//            instruction.layerInstructions = [transformer]
//
//            videoComposition = AVMutableVideoComposition()
//            videoComposition.instructions = [instruction]
//            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//            videoComposition.renderSize = CGSize(width: aspectRatioWidth , height: desiredHeight)
//
//            print("videoComposition.renderSize   \(videoComposition.renderSize)")
//        }
//        //AVAssetExportPresetPassthrough //AVAssetExportPresetHighestQuality
//        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
//            completion(NSError(domain: "VideoCropErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"]))
//            return
//        }
//
//        exportSession.videoComposition = videoComposition
//        exportSession.outputURL = outputURL
//        exportSession.outputFileType = .mov
//        exportSession.exportAsynchronously {
//            if exportSession.status == .completed {
//                completion(nil)
//            } else if let error = exportSession.error {
//                completion(error)
//            } else {
//                completion(NSError(domain: "VideoCropErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"]))
//            }
//        }
//    }

    func cropVideoWidth(from videoURL: URL, to outputURL: URL, completion: @escaping (Error?) -> Void){
        let asset = AVAsset(url: videoURL)
        
        // Video track
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        if let videoAssetTrack = asset.tracks(withMediaType: .video).first {
            try? videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoAssetTrack, at: .zero)
        }
        
        // Audio track
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
            try? audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioAssetTrack, at: .zero)
        }
       
        if UIDevice.current.userInterfaceIdiom == .pad {
            let videoSize = videoTrack?.naturalSize ?? .zero
            
            print("videoSize :: \(videoSize)")
            let transform = videoTrack?.preferredTransform ?? .identity
            let videoAspectRatio = videoSize.width / videoSize.height
            
            // Get the current screen width
            let screenWidth: CGFloat = UIScreen.main.bounds.size.width
            let screenHeight: CGFloat = UIScreen.main.bounds.size.height
            print("screenWidth :: \(screenHeight)")
            // Calculate the desired height and the amount to crop equally from the top and bottom
            //        let desiredHeight: CGFloat = 610
            
            // Specify the desired aspect ratio
            let aspectRatioWidth: CGFloat = 4.0
            let aspectRatioHeight: CGFloat = 3.0
            
            let newCropHeight = (screenHeight * aspectRatioHeight) / aspectRatioWidth //610
            
            print("newCropHeight :: \(newCropHeight)")
            print("videoSize.height :: \(videoSize.height)")
            let cropAmount = (videoSize.height - newCropHeight) / 2.0
            print("cropAmount :: \(cropAmount)")
            // Apply the crop to the video track
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
            let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
            let translate = CGAffineTransform(translationX: 0, y: -cropAmount) // Crop equally from top and bottom
            transformer.setTransform(scale.concatenating(translate), at: .zero)
            
            instruction.layerInstructions = [transformer]
            
            videoComposition = AVMutableVideoComposition()
            videoComposition.instructions = [instruction]
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.renderSize = CGSize(width: screenWidth, height: newCropHeight)
        } else {
            let videoSize = videoTrack?.naturalSize ?? .zero
            let transform = videoTrack?.preferredTransform ?? .identity
            let videoAspectRatio = videoSize.width / videoSize.height

            let heightScreen = UIScreen.main.bounds.height
            let desiredWidth : CGFloat = heightScreen * videoAspectRatio
            let desiredHeight : CGFloat = heightScreen


            // Specify the desired aspect ratio
//            let aspectRatioWidth: CGFloat = 16.0
//            let aspectRatioHeight: CGFloat = 9.0

            // Get the current screen height 926 × 428 1024 × 768  812 × 375
            let screenHeight : CGFloat = UIScreen.main.bounds.size.height
            let screenWidth : CGFloat = UIScreen.main.bounds.size.width


//            // Calculate the targetScreenWidth to maintain the desired aspect ratio
//            let targetScreenWidth = (screenHeight * aspectRatioWidth) / aspectRatioHeight
//
//            let xupdate = (screenWidth - targetScreenWidth) / 2
//
//            print("xupdate : \(xupdate)")
//

            
            print("16:9 :: \(desiredHeight)")
//            let desiredHeight: CGFloat = heightScreen // The target height
            let aspectRatioWidth = (16 / 9) * desiredHeight

            print("aspectRatioWidth \(aspectRatioWidth)")

//            let number = 666.67
            let nearestLowerDivisibleBy16 = Int(aspectRatioWidth / 16) * 16
            print("nearestLowerDivisibleBy16 \(nearestLowerDivisibleBy16)")

            let xupdate = (Int(screenWidth) - nearestLowerDivisibleBy16) / 2
            print("xupdate : \(xupdate)")
            print("Width for 16:9 aspect ratio at a height of \(desiredHeight) is: \(aspectRatioWidth)")
            
            
            // Apply the crop to the video track
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
            let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
            let translate = CGAffineTransform(translationX: -CGFloat(xupdate), y: 0)
            transformer.setTransform(scale.concatenating(translate), at: .zero)

    //        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
    //        let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
    //        let translate = CGAffineTransform(translationX: -80, y: 0) // Adjust the X value as needed
    //        transformer.setTransform(scale.concatenating(translate), at: .zero)fewrqfgcewhgewds dx



            instruction.layerInstructions = [transformer]

            videoComposition = AVMutableVideoComposition()
            videoComposition.instructions = [instruction]
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.renderSize = CGSize(width: CGFloat(nearestLowerDivisibleBy16), height: desiredHeight)
        }
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(NSError(domain: "VideoCropErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"]))
            return
        }
        
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                completion(nil)
            } else if let error = exportSession.error {
                completion(error)
            } else {
                completion(NSError(domain: "VideoCropErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"]))
            }
        }
    }

    func initialSetupAVWriter() {
        self.ts = String(Int(NSDate().timeIntervalSince1970 * 1000))
        self.documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.videoOutputURL = URL(fileURLWithPath: self.documentsPath.appendingPathComponent("MyVideo" + ts + ".mp4"))
        // Check if the file already exists and delete it if necessary
        do {
            try FileManager.default.removeItem(at: videoOutputURL)
        } catch {
            print("File cannot be deleted or not found! ", error.localizedDescription)
        }
        do {
            videoWriter = try AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mov)

        } catch let writerError as NSError {
            print("Error opening video file", writerError)
            videoWriter = nil
            return
        }
        // Video settingsdoichs; n
//        let videoOutputSettings: [String: Any] = [
//            AVVideoCodecKey: AVVideoCodecType.h264,
//            AVVideoWidthKey: UIScreen.main.bounds.size.width,
//            AVVideoHeightKey: UIScreen.main.bounds.size.height,
//        ]

//        let yourBitrate: Int = 25000000 // 25 Mbps (adjust as needed)
        let yourBitrate: Int = 30_000_000 // 30 Mbps (adjust as needed)
        
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: UIScreen.main.bounds.size.width,
            AVVideoHeightKey: UIScreen.main.bounds.size.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: yourBitrate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]


        // Audio settings
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100.0,
            AVEncoderBitRateKey: 96000,
        ]
        
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)

        videoWriterInput?.expectsMediaDataInRealTime = true
        audioWriterInput?.expectsMediaDataInRealTime = true

        videoWriter?.add(videoWriterInput!)
        videoWriter?.add(audioWriterInput!)
    }
    
    private func stopScreenRecording() {
        if !isRecording() {
            print("Attempting the stop recording without an on going recording session")
            return
        }
        if #available(iOS 15.0, *) {
            RPScreenRecorder.shared().stopCapture { err in
                if err != nil {
                    print("Failed to stop screen recording")
                    // Would be ideal to let user know about this with an alert
                }
                print("Rolling Clip stopped successfully")
            }
        }
    }


    private func isRecording() -> Bool {
        return RPScreenRecorder.shared().isRecording
    }
    
    private func getDirectoryClip() -> URL {
        var tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        let stringDate = formatter.string(from: Date())
        tempPath.appendPathComponent(String.localizedStringWithFormat("output-%@.mp4", stringDate))
        return tempPath
    }

}

//MARK: - UIGestureRecognizerDelegate

extension MatchesMainVideoRecordVC: UIGestureRecognizerDelegate {
    
}

//MARK: - CameraServiceDelegate

extension MatchesMainVideoRecordVC: CameraServiceDelegate {
    
    func zoomCondition(_ zoomFactor: CGFloat?) -> CGFloat? {
        zoomvalue = zoomFactor!
        //For Triple camera
        if #available(iOS 13.0, *) {
            if AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil {
                zoomvalue = zoomFactor! - 0.5
                return zoomvalue
            }
        }
        //For Dual wide
        if #available(iOS 13.0, *) {
            if AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil {
                zoomvalue = zoomFactor! - 0.5
                return zoomvalue
            }
        }
        //For wide and telephoto
        if #available(iOS 13.0, *) {
            if AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil {
                zoomvalue = zoomFactor! - 0.5
                return zoomvalue
            }
        }
        // For Dual camera
         if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil {
             zoomvalue = zoomFactor!
             return zoomvalue
         }

        return zoomvalue
    }
    
    func onChangeZoomFactor(_ zoomFactor: CGFloat?) {
        guard zoomFactor == nil else {
            zoomvalue = zoomFactor!
            zoomCondition(zoomFactor)
            
//            if #available(iOS 13.0, *) {
//                if AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil {
//                    zoomvalue = zoomFactor! - 0.5
//                }
//                else if AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil {yejhjmfgjjuym
//                    zoomvalue = zoomFactor! - 0.5
//                }
//            }
            
            var roundValue :String = zoomvalue.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0fx", zoomvalue) : String(format: "%.1fx", zoomvalue)
            roundValue = roundValue.replacingOccurrences(of: ".0", with: "")
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.zoomFactorBtn.setTitle(roundValue, for: .normal)
                    self.zoomFactorBtn.layoutIfNeeded()
                }
            }
            return
        }
    }
    
    
    func onRecordingAMinute(_ currentTime: CMTime) {
        // For watch Need to call here
        let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":titleForWatch]
        print(timeLbl.text)
       //  let sendingData: [String : [String : Any]] = ["Data" : ["message":"Get+startRecording", "Time":self.timeLbl.text ?? "", "Title":"AA:BB"]]
        //overgearing
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {
            
        }
        
    }
    
    func cameraService(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        validatesLayouts()
        toggleRecordBtn.isEnabled = true
        setToggleBtnImage(isStarted: true)
        Utiles.setHUD(false)
    }
    
    func cameraService(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        validatesLayouts()
        fanGenService.resetAllNewClips()
        toggleRecordBtn.isEnabled = true
        setToggleBtnImage(isStarted: false)
        Utiles.setHUD(false)
    } 
}

//MARK: - FannerCamWatchKitSharedDelegate

extension MatchesMainVideoRecordVC : FannerCamWatchKitSharedDelegate {
    func getDataFromWatch(watchMessage: [String : Any]) {
        let controller : String = watchMessage["Controller"] as! String
        if controller == "RecordingController" {
             self.onToggleRecordBtn(toggleRecordBtn)
        } else if controller == "GenericMarkerController" {
            if isControllerActive == true {
                isFromWatch = true
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapOnGeneric"), object: nil)
                print(2)
            }
        }  else if controller == "CollectiveMarkerController" {
            //S
           if isControllerActive == true {
        
            isFromWatch = true
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapOnCollective"), object: nil)
            
            //E
            DispatchQueue.main.async {
//                self.fanGenService.setNewClipMarker(self.markerTags[0], 0)
//                self.view.bringSubviewToFront(self.fanGenView)
//                self.selectedMarkerType = .collective
//                self.fanGenService.didTapMarker(self.cameraService.currentRecordedTime, .collective, .second, 0)
//                self.setUndoBtnEnabled(true)
            }
             print(3)
            }
        }  else if controller == "TagController" {
           if isControllerActive == true {
            
            
            isFromWatch = true
            
            let selectedTag = watchMessage["SelectedTag"] as! Int
             NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapOnCollectiveTag"), object: nil, userInfo: ["SelectedTag" : selectedTag])
            
//            DispatchQueue.main.async {
//                self.fanGenService.setNewClipMarker(self.markerTags[selectedTag], 0)
//                self.view.bringSubviewToFront(self.bottomBar)
//            }
  
             //   view.bringSubviewToFront(bottomBar)
            //let selectedTag : (String, String) = watchMessage["selectedTag"] as! (String, String)
           
            print(4)
            }
        } else if controller == "RecordingControllerCheck" {
            if isControllerActive == true {
                if cameraService.isRecording {
                    DispatchQueue.main.async {
                        let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                        print(self.timeLbl.text)
                        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                    }
                } else {
                    
                    DispatchQueue.main.async {
                        let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                        print(self.timeLbl.text)
                        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                    }
                    
                }
                print(5)
            } else {
                let messageDict : [String:Any] = ["isStart":false, "isControllerActive":false]
                FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}

            }
        } else if controller == "GenericMarkerControllerCheck" {
            if isControllerActive == true {
                if cameraService.isRecording {
                    let messageDict : [String:Any] = ["isStart":true]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                } else {
                    let messageDict : [String:Any] = ["isStart":false]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
                print(5)
            } else {
                let messageDict : [String:Any] = ["isStart":false, "isControllerActive":false]
                FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
            }
        } else {
            let messageDict : [String:Any] = ["isStart":false, "isControllerActive":false]
            FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
        }
    }
    
    //MARK: - Background & forground notifications
    
    @objc func didEnterdBG(notification: NSNotification){
        isControllerActive = false
        let messageDict : [String:Any]
        if cameraService.isRecording {
            messageDict = ["isStart":true,"isControllerActive":false]
        } else {
            messageDict = ["isStart":false,"isControllerActive":false]
        }
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
    
    @objc func didEnterdFG(notification: NSNotification) {
        isControllerActive = true
        let messageDict : [String:Any]
        if cameraService.isRecording {
            messageDict = ["isStart":true,"isControllerActive":true]
        } else {
            messageDict = ["isStart":false,"isControllerActive":true]
        }
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
}


//MARK: - FanGenerationVideoViewDelegate

extension MatchesMainVideoRecordVC: FanGenerationVideoDelegate, FanGenerationVideoDataSource {
    
    func didSaveScoreboardSwitch(_ switchScoreboard: Bool?) {
        //
    }
    
    func undoScore(_ fanGenVideo: FanGenerationVideo, team: Team) {
        fanGenVideo.setUndoBtn(enabled: fanGenService.undoGoal(team), team: team)
        let fScore = fanGenService.selectedMatch.match.getScoreAt(of: .first)
        fanGenView.set(goal: fScore, .first)
        let sScore = fanGenService.selectedMatch.match.getScoreAt(of: .second)
        fanGenView.set(goal: sScore, .second)
    }
    
    func didTapScoreboard(_ fanGenerationVideo: FanGenerationVideo)
    {
        fanGenView.displayScoreboardSettingView(fanGenService.selectedMatch.match.scoreboardSetting, selectedMatch: fanGenService.selectedMatch)
        
        print("Last selected Type:: \(fanGenService.selectedMatch.match.isTimeFromCountdown)")

        if (!fanGenView.isTimerOn)
        {
            fanGenView.DisplayInitialTime(fanGenService.selectedMatch.match.timerTime ?? appDelegate.videoTimerTime, fanGenService.selectedMatch.match.countdownTime ?? appDelegate.videoCountdownTime, fanGenService.selectedMatch.match.isTimeFromCountdown ?? appDelegate.isTimeFromCountdown)
            
        }
        
        view.bringSubviewToFront(fanGenView)
    }
//    if !fanGenView.isCountdownOn {
//        fanGenView.DisplayInitialCountdown(
//            fanGenService.selectedMatch.match.countdownDuration ?? appDelegate.defaultCountdownDuration,
//            fanGenService.selectedMatch.match.countdownStartValue ?? appDelegate.defaultCountdownStartValue
//        )
//    }


    func didTapGoal(_ fanGenerationVideo: FanGenerationVideo, goals value: String, team: Team) {
        _ = fanGenService.setGoals(cameraService.currentRecordedTime, Int(value) ?? 0 , team)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().f, team: .first)
        fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().s, team: .second)
    }
    
    
    func didTapMarker(_ markerView: MarkersView, _ marker: UIButton, _ type: FanGenMarker, _ team: Team, _ countPressed: Int) {
        if type == .individual || type == .collective {
            DispatchQueue.main.async {
                if isFromWatch == true {
                    self.view.bringSubviewToFront(self.fanGenView)

                } else {
                    self.view.bringSubviewToFront(self.fanGenView)
                }
            }
        }
        if type == .generic{
            self.startAnimation(selectedBtn: self.fanGenView.markerView.selectedBtn)
        }
        self.toggleRecordBtn.isUserInteractionEnabled = true
        self.toggleRecordBtn.alpha = 1.0
        selectedMarkerType = type.markerType
        self.clipProcessing = true
        if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.f_new_collectiveBtn ||  self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.s_new_collectiveBtn {
            self.toggleRecordBtn.isUserInteractionEnabled = false
            self.toggleRecordBtn.alpha = 0.5
            self.exitBtn.isUserInteractionEnabled = false
            self.exitBtn.alpha = 0.5
            
        }
        if selectedMarkerType == .collective {
            selectedMarkerType = .collectiveSport
         
            if let selectedSport = defaults.object(forKey: "selectedSport") as? String {
                // Use the selectedSport value
                print(selectedSport)
                self.selectedSport = selectedSport
            } else {
                print("Nil")
                self.selectedSport = "Soccer"
            }
                if let markersData = defaults.data(forKey: selectedSport),
                   let markers = try? JSONDecoder().decode([Marker].self, from: markersData) {
                    DataManager.shared.settingsMarkers[MarkerType.collectiveSport.rawValue] = markers
                } else {
                    let vc = SportDetailVC()
                    if let markers =  vc.sportDetailsMarkers[selectedSport] {
                        DataManager.shared.settingsMarkers[MarkerType.collectiveSport.rawValue] = markers
                    }
                }
            print(markerTags)
            DataManager.shared.settingsMarkers[MarkerType.collectiveSport.rawValue] = markerTags
        }
        if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.f_new_collectiveBtn {
            fanGenService.didTapMarker(cameraService.currentRecordedTime, type, .first, countPressed)
        }else if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.s_new_collectiveBtn {
            fanGenService.didTapMarker(cameraService.currentRecordedTime, type, .second, countPressed)
        }else {
            fanGenService.didTapMarker(cameraService.currentRecordedTime, type, team, countPressed)
        }
        setUndoBtnEnabled(true)
        let clip_creation_date = NSDate().timeIntervalSince1970
    
        timestampArr.append(clip_creation_date)
        self.fanGenService.isclipping = true
    }
    
    
    func createDirectoryIfNotExists(directoryName: String) -> URL? {
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryURL = documentsDirectory.appendingPathComponent(directoryName)
            // Check if the directory already exists
            if !FileManager.default.fileExists(atPath: directoryURL.path) {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                return directoryURL
            } else {
                return directoryURL
            }
        } catch {
            print("Error creating directory: \(error)")
            return nil
        }
    }

    func saveVideoToDirectory(videoURL: URL, inDirectory directoryURL: URL) -> URL? {
        do {
            let fileName = videoURL.lastPathComponent
            let destinationURL = directoryURL.appendingPathComponent(fileName)
            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error saving video: \(error)")
            return nil
        }
    }
    
    func startAnimation(selectedBtn : UIButton){
        UIView.animate(withDuration: 0.6,
            animations: {
                selectedBtn.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            },
            completion: { _ in
                UIView.animate(withDuration: 0.6) {
                    selectedBtn.transform = CGAffineTransform.identity
                }
            })
    }

    
    func didTapMarker(_ type: FanGenMarker, _ team: Team, _ countPressed: Int) {
        selectedMarkerType = type.markerType
        fanGenService.didTapMarker(cameraService.currentRecordedTime, type, team, countPressed)
        setUndoBtnEnabled(true)
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didSelectTagAt index: Int, _ type: FanGenMarker, _ countPressed: Int) {
        fanGenService.setNewClipMarker(markerTags[index], countPressed)
        clipDuration = Int(markerTags[index].duration)
        print(markerTags[index].duration)
        self.saveLivrecapData()
        if type == .collective {
          DispatchQueue.main.async {
                 if (isFromWatch == true) {
                    self.view.bringSubviewToFront(self.bottomBar)
                     self.bottomBar.isHidden = false
                } else {
                    self.view.bringSubviewToFront(self.bottomBar)
                    self.bottomBar.isHidden = false
                }
            }
        }
        if type == .individual || type == .collective  {
            self.startAnimation(selectedBtn: self.fanGenView.markerView.selectedBtn)
        }
        
        if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.f_new_collectiveBtn ||  self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.s_new_collectiveBtn {
            DispatchQueue.main.async() {
                if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.f_new_collectiveBtn {
                    print("f_new_collectiveBtn")
                    self.fanGenView.markerView.f_new_collectiveBtn.showLoading()
                    self.fanGenView.markerView.f_new_collectiveBtn.centerActivityIndicatorInButton(xConstant: 35, yConstant: 0)
                    self.fanGenView.setupLiveButton()
                 
                }
                if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.s_new_collectiveBtn {
                    print("s_new_collectiveBtn")
                        self.fanGenView.markerView.s_new_collectiveBtn.showLoading()
                        self.fanGenView.markerView.s_new_collectiveBtn.centerActivityIndicatorInButton(xConstant: -35, yConstant: 0)
                        self.fanGenView.setupLiveButton()
                }
                
                self.fanGenView.markerView.f_new_collectiveBtn.isUserInteractionEnabled = false
                self.fanGenView.markerView.s_new_collectiveBtn.isUserInteractionEnabled = false
            }
            
            let userDefaults = UserDefaults.standard
            savedLiverecap = userDefaults.stringArray(forKey: "Liverecap") ?? []
            print(savedLiverecap)
            self.isLiverecap = Bool(savedLiverecap[0])!
            self.isQuality = Bool(savedLiverecap[1])!
            self.saveRecapId = Int(savedLiverecap[2])!
            print(isLiverecap)
            if isLiverecap == true {
                self.toggleRecordBtn.alpha = 0.5
                self.toggleFlipBtn.isUserInteractionEnabled = false
                self.exitBtn.alpha = 0.5
                self.exitBtn.isUserInteractionEnabled = false
                self.createNsaveClip()
            }
        }

    }

    func createNsaveClip() {
        self.videoWriterInput.markAsFinished()
        self.audioWriterInput.markAsFinished()
        self.videoWriter.finishWriting {
            print("finished writing video")
            let videoOutputURL = URL(fileURLWithPath: self.documentsPath.appendingPathComponent("MyVideo" + self.ts + ".mov"))
            // Clean up movie file:
            do {
                try FileManager.default.removeItem(at: videoOutputURL)
            } catch {
                print(error.localizedDescription)
            }

            do {
                try FileManager.default.moveItem(at: self.videoOutputURL, to: videoOutputURL)
            } catch {
                print(error.localizedDescription)
            }

            print("finished writing video file")
            print(videoOutputURL)
            self.finalVideoURL = videoOutputURL
            DispatchQueue.main.async() {
                if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.f_new_collectiveBtn {
                    print("f_new_collectiveBtn")
                    self.fanGenView.markerView.f_new_collectiveBtn.hideLoading()
                    self.exitBtn.setTitle("\(self.uploadingIndexStatus)", for: .normal)
                    self.setUndoBtnEnabled(false)
                }
                if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.s_new_collectiveBtn {
                    print("s_new_collectiveBtn")
                    self.fanGenView.markerView.s_new_collectiveBtn.hideLoading()
                    self.setUndoBtnEnabled(false)
                }
                self.fanGenView.markerView.f_new_collectiveBtn.isUserInteractionEnabled = true
                self.fanGenView.markerView.s_new_collectiveBtn.isUserInteractionEnabled = true
            }
//           self.saveToPhotos(tempURL: self.finalVideoURL)
            let asset = AVAsset(url: self.finalVideoURL)
            let durationInSeconds = CMTimeGetSeconds(asset.duration)
            self.existingEndTime = CMTime(seconds: durationInSeconds, preferredTimescale: 1000) // Use your preferred timescale
            self.finalcropURL = URL(fileURLWithPath: self.documentsPath.appendingPathComponent("MyCropVideo" + self.ts + ".mov"))
            self.cropVideo(inputURL: self.finalVideoURL, outputURL: self.finalcropURL, endTime: durationInSeconds) { error in
                if let error = error {
                    print("Error cropping video: \(error.localizedDescription)")
                } else {
                    print("Video cropped successfully")
                    self.finalstableVidURL = URL(fileURLWithPath: self.documentsPath.appendingPathComponent("MyStableVideo" + self.ts + ".mov"))
//                   self.saveToPhotos(tempURL: self.finalcropURL)
                    self.cropVideoWidth(from: self.finalcropURL, to: self.finalstableVidURL) { error in
                        if let error = error {
                            print("Error cropping video: \(error)")
                        } else {
                            print("Video cropped successfully!")
                           self.saveToPhotos(tempURL: self.finalstableVidURL)
                            self.clipUrlArray.append(self.finalstableVidURL)
                            self.uploadingToLiverecap()
                        }
                    }
                }
            }
                       
            self.videoWriter = nil
            self.videoWriterInput = nil
            self.audioWriterInput = nil
            self.initialSetupAVWriter()
            self.clipProcessing = false
        }
    }
//    dsnkl
    func uploadingToLiverecap(){
        if self.clipUrlArray.count == 1 {
            self.uploadingIndexStatus = self.uploadingIndexStatus+1
            DispatchQueue.main.async() {
                self.exitBtn.setTitle("\(self.uploadingIndexStatus ?? 0)", for: .normal)
            }
            self.accessSavedClip(index: self.currentClipUploadIndex ?? 0)
        }else {
            self.uploadingIndexStatus = self.uploadingIndexStatus+1
            DispatchQueue.main.async() {
                self.exitBtn.setTitle("\(self.uploadingIndexStatus ?? 0)", for: .normal)
            }
        }
    }
    func cropVideo(inputURL: URL, outputURL: URL, endTime: Double, completion: @escaping (Error?) -> Void) {
        let asset = AVAsset(url: inputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            completion(NSError(domain: "com.yourapp.video", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."]))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov // Output format (change as needed)
        
        if endTime > Double(self.clipDuration) {
            // If the end time is greater than the clip duration, create a time range for cropping.
            let startCMTime = CMTime(seconds: endTime - Double(self.clipDuration), preferredTimescale: asset.duration.timescale)
            let endCMTime = CMTime(seconds: Double(endTime), preferredTimescale: asset.duration.timescale)
            let timeRange = CMTimeRangeFromTimeToTime(start: startCMTime, end: endCMTime)
            exportSession.timeRange = timeRange
        } else {
            // If the end time is within the clip duration, create a time range for cropping from the beginning.
            let startCMTime = CMTime(seconds: .zero, preferredTimescale: asset.duration.timescale)
            let endCMTime = CMTime(seconds: Double(endTime), preferredTimescale: asset.duration.timescale)
            let timeRange = CMTimeRangeFromTimeToTime(start: startCMTime, end: endCMTime)
            exportSession.timeRange = timeRange
        }

        exportSession.shouldOptimizeForNetworkUse = true // Optimize for network use
        exportSession.canPerformMultiplePassesOverSourceMediaData = true // Enable multiple passes for better quality
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(nil)
            case .failed:
                print(exportSession.error ?? "Unknown error")
                completion(exportSession.error)
            case .cancelled:
                completion(NSError(domain: "com.yourapp.video", code: 0, userInfo: [NSLocalizedDescriptionKey: "Export cancelled."]))
            default:
                break
            }
        }
    }


//    func cropVideo(inputURL: URL, outputURL: URL, endTime: Double, completion: @escaping (Error?) -> Void) {gf658rfuyh hj
//        let asset = AVAsset(url: inputURL)
//        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
//            completion(NSError(domain: "com.yourapp.video", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."]))
//            return
//        }
//        exportSession.outputURL = outputURL
//        exportSession.outputFileType = AVFileType.mov
////        let duration = CMTimeGetSeconds(asset.duration)
////        let startTime = 0 //max(0, endTime - 10) // Ensure start time is not negative
////        let endTime = asset.duration //min(endTime, duration) // Ensure end time is not greater than the video duration
//        if endTime > Double(self.clipDuration) {
//        // 20 > 16
//            print("Duration is greater than clip duration")
//            let startCMTime = CMTime(seconds: endTime - Double(self.clipDuration), preferredTimescale: asset.duration.timescale)
//            let endCMTime = CMTime(seconds: Double(endTime), preferredTimescale: asset.duration.timescale)
//            let timeRange = CMTimeRangeFromTimeToTime(start: startCMTime, end: endCMTime)
//            exportSession.timeRange = timeRange
//        } else {
//            print("Duration is not greater than clip duration")
//            // 5 < 16
//            let startCMTime = CMTime(seconds: .zero, preferredTimescale: asset.duration.timescale)
//            let endCMTime = CMTime(seconds: Double(endTime), preferredTimescale: asset.duration.timescale)
//            let timeRange = CMTimeRangeFromTimeToTime(start: startCMTime, end: endCMTime)
//            exportSession.timeRange = timeRange
//        }
//        exportSession.exportAsynchronously {
//            switch exportSession.status {
//            case .completed:
//                completion(nil)
//            case .failed:
//                print(exportSession.error)
//                completion(exportSession.error)
//            case .cancelled:
//                completion(NSError(domain: "com.yourapp.video", code: 0, userInfo: [NSLocalizedDescriptionKey: "Export cancelled."]))
//            default:
//                break
//            }
//        }
//    }

    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, heightForTagViewAt index: Int) -> CGFloat {
        return 50
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didClickedTagSave button: UIButton, tagNum value: String, countPressed: Int) {
        view.bringSubviewToFront(bottomBar)
        fanGenService.setNewClipTag(value, countPressed)
    }
    
    func didSaveScoreboardSetting(_ period: String?, _ point1: String?, _ point2: String?, _ point3: String?) {
        if period != nil {
            let isChanged = fanGenService.selectedMatch.match.scoreboardSetting.set(Int(point1!)!, Int(point2!)!, Int(point3!)!, period!)
            if isChanged {
                fanGenService.saveAction()
                fanGenView.setScoreboardUI(withSetting: fanGenService.selectedMatch.match.scoreboardSetting, nil, selectedMatch.match.fstAbbName,  selectedMatch.match.sndAbbName)
                MessageBarService.shared.notify("Successfully saved changed setting!")
            } else {
                if fanGenView.isTimeAnyChange == true {
                    MessageBarService.shared.notify("Successfully saved changed setting!")
                    fanGenView.isTimeAnyChange = false
                }else {
                    MessageBarService.shared.warning("No changed setting")
                }
            }
        }
        view.bringSubviewToFront(bottomBar)
    }
    
    func fanGenerationVideoMode() -> FanGenMode {
        return .record
    }
    
    func fanGenScoreValue(_ fanGenerationVideo: FanGenerationVideo, _ team: Team) -> Int? {
        return selectedMatch.match.getScoreAt(of: team)
    }
    
    func numberOfTags(in fanGenerationVideo: FanGenerationVideo) -> Int {
        return markerTags.count
    }
    
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, tagCellAt index: Int) -> Marker {
        return markerTags[index]
    }
    
    func didSaveTimerAndCountdownTime(_ timerTimer: String?, _ countdownTime: String?, _ isTimeFromCountdown : Bool?) {
        
        let isChanged = fanGenService.selectedMatch.match.set(timerTimer!, countdownTime!, isTimeFromCountdown!)
        if isChanged {
            selectedMatch.match.timerTime = appDelegate.videoTimerTime
            selectedMatch.match.countdownTime = appDelegate.videoCountdownTime
            selectedMatch.match.isTimeFromCountdown = appDelegate.isTimeFromCountdown
            fanGenService.saveAction()
        }
    }
}

// Live 
//extension MatchesMainVideoRecordVC: PresenterDelegate {
//    func didStartLive() {
//        liveTimer = Timer(timeInterval: 1.0, target: self, selector: #selector(liveTimerAction), userInfo: nil, repeats: true)
//        validatesLayouts()
//        setToggleBtnImage(isStarted: true)
//
//        perform(#selector(endStreamingReaction), with: nil, afterDelay: 1.0)
//    }
//
//    func didChangedLiveStatus() {
//        perform(#selector(endStreamingReaction), with: nil, afterDelay: 1.0)
//    }
//}

/*
 //oldcode without window
 func initLayout() {
     fanGenView = FanGenerationVideo.instanceFromNib(CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
     fanGenView.delegate = self
     fanGenView.dataSource = self
     fanGenView.initNib()
     fanGenView.setScoreboardUI(withSetting: selectedMatch.match.scoreboardSetting, nil, selectedMatch.match.fstAbbName, selectedMatch.match.sndAbbName)

     if self.selectedMatch.match.timerTime != nil {
         self.appDelegate.videoTimerTime = self.selectedMatch.match.timerTime
     }
     if self.selectedMatch.match.countdownTime != nil {
         self.appDelegate.videoCountdownTime = self.selectedMatch.match.countdownTime
     }

     if self.selectedMatch.match.isTimeFromCountdown != nil {
         self.appDelegate.isTimeFromCountdown = self.selectedMatch.match.isTimeFromCountdown
     }

     if self.appDelegate.isTimeFromCountdown {
         fanGenView.setCurrentMatchTime(self.selectedMatch.match.countdownTime != nil ? self.selectedMatch.match.countdownTime : self.appDelegate.videoCountdownTime)
     }
     else {
         fanGenView.setCurrentMatchTime(self.selectedMatch.match.timerTime != nil ? self.selectedMatch.match.timerTime : self.appDelegate.videoTimerTime)
     }

     print("MatchesMainVideoRecordVC  ")


     fanGenView.setCurrentMatchTime(fanGenService.matchTime(with: CMTime.zero))
     fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().f, team: .first)
     fanGenView.setUndoBtn(enabled: fanGenService.checkScoreUndoAvailable().s, team: .second)
     fanGenView.topLeftView.isHidden = true
     fanGenView.topRightView.isHidden = true
     fanGenView.bottomLeftView.isHidden = true
     fanGenView.bottomRightView.isHidden = true
     fanGenView.bottomCenterView.isHidden = true
     validatesLayouts()

     for currentView in self.view.subviews {
         if currentView is FanGenerationVideo  {
             currentView.removeFromSuperview()
         }
     }
     view.addSubview(fanGenView)

//        let gesture = UITapGestureRecognizer(target: self, action: #selector(focusTap(gesture:)))
//        fanGenView.addGestureRecognizer(gesture)

     let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchToZoomRecognizer(pinchRecognizer:) ))
     pinchGesture.delegate = self
     fanGenView.addGestureRecognizer(pinchGesture)
     view.bringSubviewToFront(bottomBar)



     levelTimer?.invalidate()
         if !isSoundLevelCall {
             self.soundlevel()
             isSoundLevelCall == true
         } else {
             isSoundLevelCall == true
         }

     print()

//        fanGenView.homeSelectColorBtn.isUserInteractionEnabled = false
//        fanGenView.awayColorGRSlider.isUserInteractionEnabled = false

     fanGenView.viewTeam1.isHidden = true
     fanGenView.viewTeam2.isHidden = true

     fanGenView.viewPeriodSB.isHidden = true
     fanGenView.fPeriodLbl.isHidden = true

     fanGenView.viewTimeSB.isHidden = true
     fanGenView.timeMatchLbl.isHidden = true


     self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
     self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true

     self.setLiverecapData()

     let userDefaults = UserDefaults.standard
     savedLiverecap = userDefaults.stringArray(forKey: "Liverecap") ?? []

     print(savedLiverecap)
//
     if savedLiverecap.isEmpty {
         self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
         self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true

     }else {
         self.isLiverecap = Bool(savedLiverecap[0])!
         self.isQuality = Bool(savedLiverecap[1])!

//            self.saveRecapId = Int(savedLiverecap[2])!

         self.saveRecapId = UserDefaults.standard.integer(forKey: selectedMatch.match.id)
         print(saveRecapId)

         if self.saveRecapId != 0 {

             if isLiverecap == false {

                 self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
                 self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true

                 self.fanGenView.markerView.f_collectiveBtn.isHidden = false
                 self.fanGenView.markerView.f_individualBtn.isHidden = false
                 self.fanGenView.markerView.f_genericBtn.isHidden = false

                 self.fanGenView.markerView.s_collectiveBtn.isHidden = false
                 self.fanGenView.markerView.s_individualBtn.isHidden = false
                 self.fanGenView.markerView.s_genericBtn.isHidden = false
                 self.isLiverecap = false
             } else {
                 //                self.fanGenView.markerView.f_collectiveBtn.setImage(UIImage(named: "collective_red_liverecap"), for: .normal)
                 //                self.fanGenView.markerView.s_collectiveBtn.setImage(UIImage(named: "collective_red_liverecap"), for: .normal)
                 self.fanGenView.markerView.f_new_collectiveBtn.isHidden = false
                 self.fanGenView.markerView.s_new_collectiveBtn.isHidden = false

                 self.fanGenView.markerView.f_collectiveBtn.isHidden = true
                 self.fanGenView.markerView.f_individualBtn.isHidden = true
                 self.fanGenView.markerView.f_genericBtn.isHidden = true

                 self.fanGenView.markerView.s_collectiveBtn.isHidden = true
                 self.fanGenView.markerView.s_individualBtn.isHidden = true
                 self.fanGenView.markerView.s_genericBtn.isHidden = true
                 self.isLiverecap = true
             }
         }else {

//                self.fanGenView.markerView.f_collectiveBtn.setImage(UIImage(named: "ic_collective_rednew"), for: .normal)
//                self.fanGenView.markerView.s_collectiveBtn.setImage(UIImage(named: "ic_collective_rednew"), for: .normal)

             self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
             self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true

             self.fanGenView.markerView.f_collectiveBtn.isHidden = false
             self.fanGenView.markerView.f_individualBtn.isHidden = false
             self.fanGenView.markerView.f_genericBtn.isHidden = false

             self.fanGenView.markerView.s_collectiveBtn.isHidden = false
             self.fanGenView.markerView.s_individualBtn.isHidden = false
             self.fanGenView.markerView.s_genericBtn.isHidden = false

         }

     }


     // Create the activity indicator
     activityIndicator = UIActivityIndicatorView(style: .gray)
     activityIndicator.hidesWhenStopped = true

     // Add the activity indicator as a subview of the button
     self.fanGenView.markerView.f_collectiveBtn.addSubview(activityIndicator)
     self.fanGenView.markerView.s_collectiveBtn.addSubview(activityIndicator)

     print(self.selectedMatch.match.getFilterList().count)

     print(UserDefaults.standard.integer(forKey: self.selectedMatch.match.id))

     if self.selectedMatch.match.getFilterList().count == 0 {
         print("Zero")

         self.fanGenView.markerView.f_new_collectiveBtn.isHidden = true
         self.fanGenView.markerView.s_new_collectiveBtn.isHidden = true

         self.fanGenView.markerView.f_collectiveBtn.isHidden = false
         self.fanGenView.markerView.f_individualBtn.isHidden = false
         self.fanGenView.markerView.f_genericBtn.isHidden = false

         self.fanGenView.markerView.s_collectiveBtn.isHidden = false
         self.fanGenView.markerView.s_individualBtn.isHidden = false
         self.fanGenView.markerView.s_genericBtn.isHidden = false
     }


 }
 
 
 
 


 func cropVideoWidth(inputVideoPath: URL, outputVideoPath: URL, completion: @escaping (Bool, Error?) -> Void) {
     let videoURL = inputVideoPath
     let videoAsset = AVAsset(url: videoURL)

     guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality) else {
         completion(false, nil)
         return
     }

     // Configure export session properties
     exportSession.outputURL = outputVideoPath
     exportSession.outputFileType = .mov

     // Use standard target dimensions (e.g., 1920x1080 for 16:9 aspect ratio)
     //working
     let targetWidth: CGFloat = 1920.0
     let targetHeight: CGFloat = 1080.0

     let scaleFactor = targetWidth / videoAsset.tracks(withMediaType: .video)[0].naturalSize.width

     // Define the cropping filter
     let cropFilter = CIFilter(name: "CICrop")
     cropFilter?.setValue(CIVector(x: 0, y: 0, z: targetWidth, w: targetHeight), forKey: "inputRectangle")

     // Apply the filter to the video track using a video composition instruction
     let videoComposition = AVMutableVideoComposition()
     videoComposition.renderSize = CGSize(width: targetWidth, height: targetHeight)
     videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

     let instruction = AVMutableVideoCompositionInstruction()
     instruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoAsset.duration)

     let videoTrack = videoAsset.tracks(withMediaType: .video)[0]
     let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

     // Apply a scale and translation to center the cropped area
     let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
     let translation = CGAffineTransform(translationX: 0, y: (targetHeight - videoAsset.tracks(withMediaType: .video)[0].naturalSize.height * scaleFactor) / 2) // Center vertically
     let transform = scale.concatenating(translation)

     layerInstruction.setTransform(transform, at: .zero)
     instruction.layerInstructions = [layerInstruction]

     // Set the filter instruction in the video composition
     instruction.backgroundColor = UIColor.black.cgColor // You can change the background color as needed

     videoComposition.instructions = [instruction]

     exportSession.videoComposition = videoComposition

     exportSession.exportAsynchronously {
         DispatchQueue.main.async {
             switch exportSession.status {
             case .completed:
                 print("Cropping completed!")
                 // Save the cropped video to the Photos library
                 PHPhotoLibrary.shared().performChanges({
                     let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputVideoPath)
                     request?.creationDate = Date()
                 }) { success, error in
                     if success {
                         completion(true, nil)
                     } else {
                         print("Failed to save video to Photos library: \(error?.localizedDescription ?? "")")
                         completion(false, error)
                     }
                 }
             case .failed:
                 print("Cropping failed: \(exportSession.error?.localizedDescription ?? "")")
                 completion(false, exportSession.error)
             case .cancelled:
                 print("Cropping cancelled")
                 completion(false, nil)
             default:
                 break
             }
         }
     }
 }

 func cropVideoToFill(inputVideoPath: URL, outputVideoPath: URL, targetWidth: CGFloat, targetHeight: CGFloat, completion: @escaping (Bool, Error?) -> Void) {
     let videoURL = inputVideoPath
      let videoAsset = AVAsset(url: videoURL)

      guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality) else {
          completion(false, nil)
          return
      }

      // Configure export session properties
      exportSession.outputURL = outputVideoPath
      exportSession.outputFileType = .mov

      let videoTrack = videoAsset.tracks(withMediaType: .video)[0]
      let naturalSize = videoTrack.naturalSize

      // Calculate the scaling factor to fit the cropped width within the target dimensions
      let scaleFactorX = cropWidth / naturalSize.width

      // Calculate the new video size after scaling
      let scaledWidth = naturalSize.width * scaleFactorX
      let scaledHeight = naturalSize.height * scaleFactorX

      // Define the cropping rect to remove the left side
      let cropRect = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)

      // Define the cropping filter
      let cropFilter = CIFilter(name: "CICrop")
      cropFilter?.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")

      // Apply the filter to the video track using a video composition instruction
      let videoComposition = AVMutableVideoComposition()
      videoComposition.renderSize = CGSize(width: scaledWidth, height: scaledHeight)
      videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

      let instruction = AVMutableVideoCompositionInstruction()
      instruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoAsset.duration)

      let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

      // Apply the scale transform to fit the cropped width within the target dimensions
      let scale = CGAffineTransform(scaleX: scaleFactorX, y: scaleFactorX)

      layerInstruction.setTransform(scale, at: .zero)
      instruction.layerInstructions = [layerInstruction]

      // Set the filter instruction in the video composition
      instruction.backgroundColor = UIColor.black.cgColor // You can change the background color as needed

      videoComposition.instructions = [instruction]

      exportSession.videoComposition = videoComposition

     exportSession.exportAsynchronously {
         DispatchQueue.main.async {
             switch exportSession.status {
             case .completed:
                 print("Cropping completed!")
                 // Save the cropped video to the Photos library
                 PHPhotoLibrary.shared().performChanges({
                     let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputVideoPath)
                     request?.creationDate = Date()
                 }) { success, error in
                     if success {
                         completion(true, nil)
                     } else {
                         print("Failed to save video to Photos library: \(error?.localizedDescription ?? "")")
                         completion(false, error)
                     }
                 }
             case .failed:
                 print("Cropping failed: \(exportSession.error?.localizedDescription ?? "")")
                 completion(false, exportSession.error)
             case .cancelled:
                 print("Cropping cancelled")
                 completion(false, nil)
             default:
                 break
             }
         }
     }
 }
 
 func cropVideoToFill(inputVideoPath: URL, outputVideoPath: URL, targetWidth: CGFloat, targetHeight: CGFloat, reductionWidth: CGFloat, completion: @escaping (Bool, Error?) -> Void) {
     let videoURL = inputVideoPath
     let videoAsset = AVAsset(url: videoURL)
     
     guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality) else {
         completion(false, nil)
         return
     }
     
     // Configure export session properties
     exportSession.outputURL = outputVideoPath
     exportSession.outputFileType = .mov
     
     let videoTrack = videoAsset.tracks(withMediaType: .video)[0]
     let naturalSize = videoTrack.naturalSize
     
     // Calculate the scaling factors to fill the target dimensions
     let scaleFactorX = (targetWidth - reductionWidth) / naturalSize.width
     let scaleFactorY = targetHeight / naturalSize.height
     let scaleFactor = max(scaleFactorX, scaleFactorY)
     
     // Calculate the new video size after scaling
     let scaledWidth = naturalSize.width * scaleFactor
     let scaledHeight = naturalSize.height * scaleFactor
     
     // Calculate the cropping rect to fill the target dimensions and center the video
     let cropRect = CGRect(x: (scaledWidth - targetWidth) / 2, y: (scaledHeight - targetHeight) / 2, width: targetWidth - reductionWidth, height: targetHeight)
     
     // Define the cropping filter
     let cropFilter = CIFilter(name: "CICrop")
     cropFilter?.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
     
     // Apply the filter to the video track using a video composition instruction
     let videoComposition = AVMutableVideoComposition()
     videoComposition.renderSize = CGSize(width: targetWidth, height: targetHeight)
     videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
     
     let instruction = AVMutableVideoCompositionInstruction()
     instruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoAsset.duration)
     
     let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
     
     // Apply the scale transform to fill the video within the target dimensions
     let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
     
     layerInstruction.setTransform(scale, at: .zero)
     instruction.layerInstructions = [layerInstruction]
     
     // Set the filter instruction in the video composition
     instruction.backgroundColor = UIColor.black.cgColor // You can change the background color as needed
     
     videoComposition.instructions = [instruction]
     
     exportSession.videoComposition = videoComposition
     
     exportSession.exportAsynchronously {
         DispatchQueue.main.async {
             switch exportSession.status {
             case .completed:
                 print("Cropping completed!")
                 // Save the cropped video to the Photos library
                 PHPhotoLibrary.shared().performChanges({
                     let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputVideoPath)
                     request?.creationDate = Date()
                 }) { success, error in
                     if success {
                         completion(true, nil)
                     } else {
                         print("Failed to save video to Photos library: \(error?.localizedDescription ?? "")")
                         completion(false, error)
                     }
                 }
             case .failed:
                 print("Cropping failed: \(exportSession.error?.localizedDescription ?? "")")
                 completion(false, exportSession.error)
             case .cancelled:
                 print("Cropping cancelled")
                 completion(false, nil)
             default:
                 break
             }
         }
     }
 }


     private func saveToPhotos(tempURL: URL) {
         PHPhotoLibrary.shared().performChanges {
             PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
         } completionHandler: { success, error in
             if success == true {
                 print("Saved rolling clip to photos")
 
                 let finalpath = self.getDirectoryClip()
                 self.cropVideoToFill(inputVideoPath: tempURL, outputVideoPath: finalpath, targetWidth: 1280, targetHeight: 720,  reductionWidth: 500)
                 { success, error in
                     if success {
                          Cropping successful, you can use the cropped video at outputVideoPath
                         print("Saved Cropping clip to photos")
 
                     } else {
                          Handle the error
                         if let error = error {
                             print("Error: \(error.localizedDescription)")
                         }
                     }
                 }
             } else {
                 print("Error exporting clip to Photos \(String(describing: error))")
             }
         }
     }

 
 
 working code for crop and save
 
     private func saveToPhotos(tempURL: URL) {
         PHPhotoLibrary.shared().performChanges {
             PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
         } completionHandler: { success, error in
             if success == true {
                 print("Saved rolling clip to photos")
 
             } else {
                 print("Error exporting clip to Photos \(String(describing: error))")
             }
         }
     }

     
     func cropVid(inputVid: URL){
         let asset = AVAsset(url: inputVid)
         let durationInSeconds = CMTimeGetSeconds(asset.duration)
 
 
         self.ts = String(Int(NSDate().timeIntervalSince1970 * 1000))
         self.documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
         self.finalcropURL = URL(fileURLWithPath: self.documentsPath.appendingPathComponent("MyCropVideo" + self.ts + ".mov"))
 
         self.cropVideo(inputURL: inputVid, outputURL: self.finalcropURL, endTime: durationInSeconds) { error in
             if let error = error {
                 print("Error cropping video: \(error.localizedDescription)")
             } else {
                 print("Video cropped successfully")
                 self.clipUrlArray.append(self.finalcropURL)
 
 
                 if self.clipUrlArray.count == 1 {
                     self.uploadingIndexStatus = self.uploadingIndexStatus+1
 
                     DispatchQueue.main.async() {
                         self.exitBtn.setTitle("\(self.uploadingIndexStatus ?? 0)", for: .normal)
                     }
 
                     self.accessSavedClip(index: self.currentClipUploadIndex ?? 0)
 
                     self.isUploading = true
 
                 }else {
                     self.uploadingIndexStatus = self.uploadingIndexStatus+1
                     DispatchQueue.main.async() {
                         self.exitBtn.setTitle("\(self.uploadingIndexStatus ?? 0)", for: .normal)
                     }
                 }
 
             }
         }
     }

     func cropVideo(inputURL: URL, outputURL: URL, endTime: Double, completion: @escaping (Error?) -> Void) {
         let asset = AVAsset(url: inputURL)
 
         guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
             completion(NSError(domain: "com.yourapp.video", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session."]))
             return
         }
 
         exportSession.outputURL = outputURL
         exportSession.outputFileType = AVFileType.mov
 
         let duration = CMTimeGetSeconds(asset.duration)
 //        let startTime = 0 //max(0, endTime - 10) // Ensure start time is not negative
 //        let endTime = asset.duration //min(endTime, duration) // Ensure end time is not greater than the video duration
 
         let startCMTime = CMTime(seconds: endTime - Double(self.clipDuration), preferredTimescale: asset.duration.timescale)
         let endCMTime = CMTime(seconds: Double(endTime), preferredTimescale: asset.duration.timescale)
         let timeRange = CMTimeRangeFromTimeToTime(start: startCMTime, end: endCMTime)
 
         exportSession.timeRange = timeRange
 
         exportSession.exportAsynchronously {
             switch exportSession.status {
             case .completed:
                 completion(nil)
             case .failed:
                 print(exportSession.error)
                 completion(exportSession.error)
             case .cancelled:
                 completion(NSError(domain: "com.yourapp.video", code: 0, userInfo: [NSLocalizedDescriptionKey: "Export cancelled."]))
             default:
                 break
             }
         }
     }
     
 
     func stabilizeAndAppendToSampleBufferArray(sampleBuffer: CMSampleBuffer) {
         // Convert the sample buffer to a CIImagetyr  45 e
         guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
               let ciImage = CIImage(cvImageBuffer: pixelBuffer) else {
             return
         }
 
         // Apply video stabilization filter to the CIImage
         if let stabilizedImage = ciImage.applyingFilter("CIVideoStabilization") {
             // Create a CIContext to render the CIImage into a CVPixelBuffer
             let ciContext = CIContext()
 
             let pixelBufferWidth = CVPixelBufferGetWidth(pixelBuffer)
             let pixelBufferHeight = CVPixelBufferGetHeight(pixelBuffer)
 
             var renderedPixelBuffer: CVPixelBuffer?
             CVPixelBufferCreate(nil, pixelBufferWidth, pixelBufferHeight, kCVPixelFormatType_32BGRA, nil, &renderedPixelBuffer)
 
             ciContext.render(stabilizedImage, to: renderedPixelBuffer!)
 
             // Create a new CMSampleBuffer with the stabilized frame
             var newSampleBuffer: CMSampleBuffer?
             var sampleTimingInfo = CMSampleTimingInfo(duration: CMSampleBufferGetDuration(sampleBuffer),
                                                       presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
                                                       decodeTimeStamp: CMSampleBufferGetDecodeTimeStamp(sampleBuffer))
 
             CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                imageBuffer: renderedPixelBuffer!,
                                                dataReady: true,
                                                makeDataReadyCallback: nil,
                                                refcon: nil,
                                                formatDescription: CMSampleBufferGetFormatDescription(sampleBuffer)!,
                                                sampleTiming: &sampleTimingInfo,
                                                sampleBufferOut: &newSampleBuffer)
 
             // Append the stabilized frame to your sample buffer array
             sampleBufferArray.append(newSampleBuffer!)
         }
     }

 
iphone
    func cropVideoWidth(from videoURL: URL, to outputURL: URL, completion: @escaping (Error?) -> Void) {
        let asset = AVAsset(url: videoURL)

        // Video track
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        if let videoAssetTrack = asset.tracks(withMediaType: .video).first {
            try? videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoAssetTrack, at: .zero)
        }

        // Audio track
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
            try? audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioAssetTrack, at: .zero)
        }

        let videoSize = videoTrack?.naturalSize ?? .zero
        let transform = videoTrack?.preferredTransform ?? .identity
        let videoAspectRatio = videoSize.width / videoSize.height

        let heightScreen = UIScreen.main.bounds.height
        let desiredWidth : CGFloat = heightScreen * videoAspectRatio
        let desiredHeight : CGFloat = heightScreen


        // Specify the desired aspect ratio
        let aspectRatioWidth: CGFloat = 16.0
        let aspectRatioHeight: CGFloat = 9.0

        // Get the current screen height 926 × 428 1024 × 768  812 × 375
        let screenHeight : CGFloat = UIScreen.main.bounds.size.height
        let screenWidth : CGFloat = UIScreen.main.bounds.size.width


        // Calculate the targetScreenWidth to maintain the desired aspect ratio
        let targetScreenWidth = (screenHeight * aspectRatioWidth) / aspectRatioHeight

        let xupdate = (screenWidth - targetScreenWidth) / 2

        print("xupdate : \(xupdate)")


        // Apply the crop to the video track
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
        let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
        let translate = CGAffineTransform(translationX: -xupdate, y: 0)
        transformer.setTransform(scale.concatenating(translate), at: .zero)

//        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
//        let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
//        let translate = CGAffineTransform(translationX: -80, y: 0) // Adjust the X value as needed
//        transformer.setTransform(scale.concatenating(translate), at: .zero)fewrqfgcewhgewds dx



        instruction.layerInstructions = [transformer]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: targetScreenWidth, height: desiredHeight)

        print("desiredWidth ::: \(desiredWidth)")
        print(desiredHeight)
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(NSError(domain: "VideoCropErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"]))
            return
        }

        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                completion(nil)
            } else if let error = exportSession.error {
                completion(error)
            } else {
                completion(NSError(domain: "VideoCropErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"]))
            }
        }
    }

 func didTapMarker(_ markerView: MarkersView, _ marker: UIButton, _ type: FanGenMarker, _ team: Team, _ countPressed: Int) {
     if type == .individual || type == .collective {
         DispatchQueue.main.async {
             if isFromWatch == true {
                 self.view.bringSubviewToFront(self.fanGenView)
             } else {
                 self.view.bringSubviewToFront(self.fanGenView)
             }
         }
     }
     selectedMarkerType = type.markerType

     
     if selectedMarkerType == .collective {
         selectedMarkerType = .collectiveSport
         
         print(markerTags)
         DataManager.shared.settingsMarkers[MarkerType.collectiveSport.rawValue] = markerTags
         print(DataManager.shared.settingsMarkers[MarkerType.collectiveSport.rawValue])
     }
     fanGenService.didTapMarker(cameraService.currentRecordedTime, type, team, countPressed)
     setUndoBtnEnabled(true)
 }
 
 
    func startTask() {
        // Create a DispatchWorkItem
        workItem = DispatchWorkItem {
            // Your task code here
            self.createNsaveClip()
            print("Task completed successfully.")
        }

        // Execute the task on a background queue
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem!)
    }

    func cancelTask() {
        // Check if workItem is not nil and hasn't been cancelled already
        if let workItem = workItem, !workItem.isCancelled {
            workItem.cancel()

            self.toggleRecordBtn.isUserInteractionEnabled = true

            print(self.uploadingIndexStatus)
            print(self.currentClipUploadIndex)

                self.currentClipUploadIndex = 0
                self.uploadingIndexStatus = 0
                self.fanGenService.clipsArr.removeAll()
                self.clipUrlArray.removeAll()
                DispatchQueue.main.async{
                    DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                        self.exitBtn.setTitle("Exit", for: .normal)
                        self.toggleRecordBtn.alpha = 1.0
                        self.toggleFlipBtn.isUserInteractionEnabled = true
                        self.exitBtn.alpha = 0.5
                        self.exitBtn.isUserInteractionEnabled = false
                    }
                }
                self.isUploading = false
        }
    }

 
 
 
 func stabilizeVideo(inputURL: URL, outputURL: URL, completion: @escaping (Error?) -> Void) {
     let asset = AVAsset(url: inputURL)
     let composition = AVMutableComposition()
     guard let videoTrack = asset.tracks(withMediaType: .video).first else {
         completion(NSError(domain: "YourAppDomain", code: 1, userInfo: nil))
         return
     }
     let videoComposition = AVMutableVideoComposition()
     videoComposition.renderSize = videoTrack.naturalSize
     videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // Adjust frame rate as needed

     let instruction = AVMutableVideoCompositionInstruction()
     instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
     let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

     let transform = videoTrack.preferredTransform
     layerInstruction.setTransform(transform, at: .zero)
     instruction.layerInstructions = [layerInstruction]
     videoComposition.instructions = [instruction]

     let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
     exportSession?.outputFileType = .mov
     exportSession?.outputURL = outputURL
     exportSession?.videoComposition = videoComposition

     exportSession?.exportAsynchronously {
         if exportSession?.status == .completed {
             completion(nil)
         } else if exportSession?.status == .failed {
             completion(exportSession?.error)
         }
     }
 }
 
 func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didSelectTagAt index: Int, _ type: FanGenMarker, _ countPressed: Int) {
     fanGenService.setNewClipMarker(markerTags[index], countPressed)
     
     print(markerTags[index].duration)
     
     if type == .collective {
         
         DispatchQueue.main.async {
             if (isFromWatch == true) {
                     self.view.bringSubviewToFront(self.bottomBar)
             } else {
                    self.view.bringSubviewToFront(self.bottomBar)
             }
         }
     }
 }
 
 func listVideosInDirectory(directoryName: String) -> [URL] {
     let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
     let directoryURL = documentsDirectory.appendingPathComponent(directoryName)
     
     do {
         let videoURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
         return videoURLs
     } catch {
         print("Error listing videos: \(error)")
         return []
     }
 }



 func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     let directoryName = "Clip_Liverecap"
     let videoURLs = listVideosInDirectory(directoryName: directoryName)
     return videoURLs.count
 }

 func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "ClipListTableViewCell", for: indexPath) as! ClipListTableViewCell
     let directoryName = "Clip_Liverecap"
     let videoURLs = listVideosInDirectory(directoryName: directoryName)
     if indexPath.row < videoURLs.count {
         let videoURL = videoURLs[indexPath.row]
         cell.setVideo(url: videoURL)
     } else {
         print("Invalid index or no video URL at index: \(indexPath.row)")
     }
     return cell
 }
 
 */
