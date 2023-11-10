//
//  MatchesMainVideoRecordLiveVC.swift
//  NewFannerCam
//
//  Created by Komal on 17/03/21.
//  Copyright © 2021 fannercam3. All rights reserved.
//




import UIKit
import AVFoundation
import AudioToolbox
import AVKit
import HaishinKit
import VideoToolbox
//import Loaf
import Photos
import ImageIO
import ReplayKit
import Alamofire
import SwiftMessageBar


class MatchesMainVideoRecordLiveVC: UIViewController, RTMPStreamDelegate, RPScreenRecorderDelegate, AVAudioRecorderDelegate  {
    var testCount : Int = 0
    let rtmpHandlerQueue              = DispatchQueue(label: "com.fannerCamn.app.rtmpHandlerQueue")
//    var alternateFunction = false
    @IBOutlet weak var logoTrailingConstraints: NSLayoutConstraint!
    var videoComposition                                = AVMutableVideoComposition()
    var isRecapListSelected                             : Bool = false
    var notificationQueue                                = DispatchQueue(label: "com.fannercamapp.notificationQueue")
    let uploadGroup                                     = DispatchGroup()
    var uploadCompleted                                 = false
    let timeoutInSeconds                                : Double = 60.0 // 350
    var clipCurrentScore                                : String!
    var finalstableVidURL : URL!
    var documentsPath: NSString!
    var ts: String!
    var finalcropURL : URL!
    
    
    var timestampArr: [Double] = []
    var currentClipTimestamp : Double!
    var currentClipUploadIndex              : Int = 0
    var videoData                           : Data?
    var uploadingIndexStatus                : Int = 0
    var clipUrlArray                        : [URL] = []
    var isUploading                         : Bool = false
    let kbpsfpsQueue              = DispatchQueue(label: "com.fannerCamn.app.kbpsfpsQueue", qos: .userInitiated)
    
    var audioNewRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?

  
    var finalVideoURL : URL!
    private let processingQueue = DispatchQueue(label: "com.yourapp.processingQueue")
    let videoProcessingQueueSample = DispatchQueue(label: "com.fannerCamn.videoProcessingQueue", attributes: .concurrent)
  
    var videoOutputURLFull: URL!
    var videoWriterFull: AVAssetWriter!
    var videoWriterInputFull: AVAssetWriterInput!
    var audioWriterInputFull: AVAssetWriterInput!
    
    var videoOutputURL: URL!
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var audioWriterInput: AVAssetWriterInput!
    
    
    var newAssetWriterInput: AVAssetWriterInput!
    var clipProcessing : Bool = false
    var existingEndTime: CMTime!
    var clipDuration : Int! = 0
    private var lastUpdateTime      : TimeInterval = 0
    private let minUpdateInterval   : TimeInterval = 0.1 // Adjust the interval as needed
    let videoProcessingQueue        = DispatchQueue(label: "com.fannerCamn.app.videoProcessing", qos: .userInteractive)
    let otherTaskQueue              = DispatchQueue(label: "com.fannerCamn.app.otherTask", qos: .background)
    let uploadQueue                 = DispatchQueue(label: "com.fannerCamn.uploadQueue")
    var currentIndex                = 0
    var selectedSport               : String!
    var sportsMarker                = [Marker]()
    var clipsArrCount               = 0
    var uploadClip                  : [Clip] = []
    var notStopStreaming            : Bool = false
    var indexClipArr                : Int = 0
    var isAlreadyUploading          : Bool = false
    var nextUplaod                  : Bool = false
    var isUploadedSuccessfully      : Bool = false
    var isUploadingClipProcess      : Bool = false
    var activityIndicator           : UIActivityIndicatorView!
    var isQuality                   : Bool = false
    var saveRecapId                 : Int = 0
    var isLiverecap                 : Bool = false

    var isClippingReady                     : Bool = false
    var isclipRecordDone                    : Bool = false
    var isClipCreating                      : Bool = false
    var ZeroCheck                           : Int = 0
    var Other                               : String!
    var valueR                              : String!
    var valueG                              : String!
    var valueB                              : String!
    var valueAlpha                          : String!
    var saveScoreboardData                  : [String] = []
    let defaults                            = UserDefaults.standard
    private var streamQueue                 : DispatchQueue!
    private var backgroundStreamingID       : UIBackgroundTaskIdentifier!
    @IBOutlet weak var scoreboardHeight     : NSLayoutConstraint!
    var isScreenCaptured                    : Bool  = false
    var player                              : AVPlayer?
    var avpController                       = AVPlayerViewController()
    @IBOutlet weak var testScore            : UIView!
    @IBOutlet weak var imgArchive           : UIImageView!
    @IBOutlet weak var WindowDetailView     : UIView!
    var recordButtonView                    : UIView?
    var recordButtonOuterView               : UIView?
    @IBOutlet weak var img2Btn              : UIButton!
    @IBOutlet weak var img1Btn              : UIButton!
    @IBOutlet weak var previewCam           : UIView!
    @IBOutlet weak var lblfpskbps           : UILabel!
    @IBOutlet weak var imgCurrentStatus     : UIImageView!
    @IBOutlet weak var lblCurrentStatus     : UILabel!
    @IBOutlet weak var statusView           : UIView!
    @IBOutlet weak var imgShare             : UIImageView!
    @IBOutlet weak var viewTime             : UIView!
    var isstreaming : Bool = false
    var segmentedPresets = [ MatchesMainVideoRecordLiveVC.Preset.sd_540p_30fps_2mbps,
                             MatchesMainVideoRecordLiveVC.Preset.hd_720p_30fps_3mbps,
                             MatchesMainVideoRecordLiveVC.Preset.hd_1080p_30fps_5mbps
                            ]

    // RTMP Connection & RTMP Stream
    private var rtmpConnection      = RTMPConnection()
    private var rtmpStream          : RTMPStream!
    var audioQuality                = Int()
    var selectedFrameRate           = Int()
    var selectedVideoResolution     = String()
    var savedRtmpSettings           : [String] = []
    var savedLiverecap              : [String] = []
    var isLiveStreamRTMP            : Bool = false
    var BitrateValue                : Int = 1500
    @IBOutlet weak var livePreview  : MTHKView!
    @IBOutlet weak var settingRTMP  : UIButton!

    private var defaultCamera               : AVCaptureDevice.Position = .back
    @IBOutlet weak var fannerlogoConstraint : NSLayoutConstraint!
    
    private var liveDesired         = false
    private var reconnectAttempt    = 0
    private var firstAttempt        = 1
    private var lastBwChange        = 0
    public var streamKey            : String! = ""
    public var preset               : Preset!
    var rtmpEndpoint                : String! = ""
    
    // Some basic presets for live streaming
    enum Preset {
        case sd_360p_30fps_1mbps
        case sd_540p_30fps_2mbps
        case hd_720p_30fps_3mbps
        case hd_1080p_30fps_5mbps
    }
      
    
    // An encoding profile - width, height, framerate, video bitrate
    private class Profile {
        public var width : Int = 0
        public var height : Int = 0
        public var frameRate : Int = 24
        public var bitrate : Int = 1500
        
        init(width: Int, height: Int, frameRate: Int, bitrate: Int) {
            self.width = width
            self.height = height
            self.frameRate = frameRate
            self.bitrate = bitrate
        }
    }

    
    private func presetToProfile(preset: Preset) -> Profile {
        switch preset {
        case .sd_360p_30fps_1mbps:
            return Profile(width: 640, height: 360, frameRate: Int(selectedFrameRate), bitrate: BitrateValue)
        case .sd_540p_30fps_2mbps:
            return Profile(width: 960, height: 540, frameRate: Int(selectedFrameRate), bitrate: BitrateValue)
        case .hd_720p_30fps_3mbps:
            return Profile(width: 1280, height: 720, frameRate: Int(selectedFrameRate), bitrate: BitrateValue)
        case .hd_1080p_30fps_5mbps:
            return Profile(width: 1920, height: 1080, frameRate: Int(selectedFrameRate), bitrate: BitrateValue)

        }
    }

    // Configures the live stream
    private func configureStream(preset: Preset , selectedFrameRate : Int)
    {

        let profile = presetToProfile(preset: preset)
        // Configure the capture settings from the camera
        if preset == .hd_1080p_30fps_5mbps {
            rtmpStream.captureSettings = [
                .fps : selectedFrameRate ,
                .sessionPreset: AVCaptureSession.Preset.hd1920x1080,
                .continuousAutofocus: true,
                .continuousExposure: true,
//                 .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
                ]
        }else if preset == .hd_720p_30fps_3mbps {
            rtmpStream.captureSettings = [
                .fps : selectedFrameRate ,
                .sessionPreset: AVCaptureSession.Preset.hd1280x720,
                .continuousAutofocus: true,
                .continuousExposure: true,
//                 .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
                ]
        }else if preset == .sd_540p_30fps_2mbps {
            rtmpStream.captureSettings = [
                .fps : selectedFrameRate ,
                .sessionPreset: AVCaptureSession.Preset.iFrame960x540,
                .continuousAutofocus: true,
                .continuousExposure: true,
//                 .preferredVideoStabilizationMode: AVCaptureVideoStabilizationMode.auto
                ]
        }else {

        }
        // Get the orientation of the app, and set the video orientation appropriately
        if #available(iOS 13.0, *) {
            
            if let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                let videoOrientation = DeviceUtil.videoOrientation(by: orientation)
                rtmpStream.orientation = videoOrientation!
                rtmpStream.videoSettings = [
                    .width                           : (orientation.isPortrait) ? profile.height : profile.width,
                    .height                          : (orientation.isPortrait) ? profile.width : profile.height,
                    .bitrate                         : profile.bitrate,
                    .profileLevel                    : kVTProfileLevel_H264_Baseline_AutoLevel,
                    .maxKeyFrameIntervalDuration     : 2, // 2 seconds
                ]
            }
        } else {

        }
       
        // Configure the RTMP audio stream
        rtmpStream.audioSettings = [
            .sampleRate         : 48_000 ,
            .bitrate            : audioQuality//128000 // Always use 128kbps
            
        ]
        
        rtmpStream.recorderSettings = [
            AVMediaType.audio: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 0,
                // AVEncoderBitRateKey: 128000,
            ],
            AVMediaType.video: [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoHeightKey: 0,
                AVVideoWidthKey: 0,
                /*
                AVVideoCompressionPropertiesKey: [
                    AVVideoMaxKeyFrameIntervalDurationKey: 2,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline30,
                    AVVideoAverageBitRateKey: 512000
                ]
                */
            ],
        ]

    }
 
    
    // Publishes the live stream
    private func publishStream() {
        rtmpStream.publish(self.streamKey)

    }
    
    // Triggers and attempt to connect to an RTMP hostname
    private func connectRTMP() {
        rtmpConnection.connect(rtmpEndpoint)
    }
    
    var audioRecorder                       : AVAudioRecorder!
    var levelTimer                          : Timer? = nil
    deinit {
        levelTimer?.invalidate()
        }
    var SoundMeterSlider                    : SummerSlider!
    var zoomvalue                            = CGFloat()
    var isSoundLevelCall                     = false
    
    //MARK: - IBOutlets & Properties
//    @IBOutlet weak var lfPreview                : UIView!   // LFLivePreview
//    @IBOutlet weak var preview                  : UIView!
    @IBOutlet weak var bottomBar                : UIView!
    @IBOutlet weak var viewCircle               : UIView!
    @IBOutlet weak var imgLiveShow              : UIImageView!
    @IBOutlet weak var imgRecording             : UIImageView!
    @IBOutlet weak var timeLbl                  : UILabel!
    @IBOutlet weak var toggleRecordBtn          : UIButton!
    @IBOutlet weak var exitBtn                  : UIButton!
    @IBOutlet weak var undoBtn                  : UIButton!
    @IBOutlet weak var toggleFlipBtn            : UIButton!
    @IBOutlet weak var zoomFactorBtn            : UIButton!
    @IBOutlet weak var settingBtn               : UIButton!
    @IBOutlet weak var imgFannerView            : UIImageView!
    @IBOutlet weak var liveStatus: UILabel!
    
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
    var yourNumber = 0
    
    //MARK: - override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        img1Btn.setTitle("", for: .normal)
        img2Btn.setTitle("", for: .normal)
        self.lblCurrentStatus.isHidden = true
        self.liveStatus.isHidden = true
        self.statusView.isHidden = true
        bottomBar.isHidden = false
        settingBtn.isHidden = false
        zoomFactorBtn.isHidden = false
   
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .landscape
        fanGenService = FanGenerationService(selectedMatch, .record)
    
        zoomFactorBtn.layer.cornerRadius = zoomFactorBtn.frame.size.height/2
        zoomFactorBtn.layer.borderColor = UIColor.white.cgColor
        zoomFactorBtn.layer.borderWidth = 1.5
        zoomFactorBtn.layer.masksToBounds = true
        
        FannerCamWatchKitShared.sharedManager.delegate =  self
        
        view.isUserInteractionEnabled = false
        
//        Utiles.setHUD(true, view, .extraLight, "Configuring camera...")
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterdBG), name: Notification.Name("enterdBG"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterdFG), name: Notification.Name("enterdFG"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveTimerCountdownFromFanGenerationVideo), name: NSNotification.Name("timerCountdownValueChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(animateFannerLogo), name: Notification.Name("LogoAnimationNotification"), object: nil)

    }

    @objc func saveTimerCountdownFromFanGenerationVideo() {
        if (self.fanGenView.isCountdown) {
            self.appDelegate.videoCountdownTime = String.init(format: "%02d'%02d", self.fanGenView.countdownValue / 60, self.fanGenView.countdownValue % 60)
        }
        else {
            let length = String(self.fanGenView.totalSecond / 60).count
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
//            self.fannerLogoConstraint.constant = 120 //07
            self.scoreboardHeight.constant = 120
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            fanGenView = FanGenerationVideo.instanceFromNib(CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
            self.scoreboardHeight.constant = 20
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
        let frameSlider = CGRect(x: bottomBar!.bounds.midX-80, y: bottomBar!.bounds.midY+10, width: 160, height: 25)
        var marksArray1 = Array<Float>()
        marksArray1 = [0,10,20,30,40,50,60,70,80]
        SoundMeterSlider = SummerSlider(frame: frameSlider)
        SoundMeterSlider.unselectedBarColor = UIColor.gray
        SoundMeterSlider.markColor = UIColor.gray
        SoundMeterSlider.markWidth = 1.0
        SoundMeterSlider.thumbTintColor = .clear
        SoundMeterSlider.markPositions = marksArray1
        recordButtonView?.addSubview(SoundMeterSlider)
        testScore.addSubview(fanGenView.scoreShowView)
        NSLayoutConstraint.activate([
            fanGenView.scoreShowView.centerXAnchor.constraint(equalTo: testScore!.centerXAnchor),
            fanGenView.scoreShowView.centerYAnchor.constraint(equalTo: testScore!.centerYAnchor),
            fanGenView.scoreShowView.heightAnchor.constraint(equalToConstant: 40),
            fanGenView.scoreShowView.widthAnchor.constraint(equalToConstant: 275)
           ])
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackGround), name: UIApplication.didEnterBackgroundNotification, object: nil)

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
        self.backgroundStreamingID = UIBackgroundTaskIdentifier.invalid
        saveScoreboardData = defaults.stringArray(forKey: "ScoreboardDataLive") ?? [String]()

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
        savedLiverecap = userDefaults.stringArray(forKey: "LiverecapLive") ?? []
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
        self.defaults.set(self.savedLiverecap, forKey: "LiverecapLive")
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

    func logoAdjust() {
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
        logoTrailingConstraints.constant = CGFloat(finalTrailing) //07

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
                
                self.savedLiverecap = UserDefaults.standard.stringArray(forKey: "LiverecapLive") ?? []
                if self.savedLiverecap.isEmpty {
                    
                    // Set a default value
                    self.savedLiverecap = ["true", "true"]
                    // Save the default value to UserDefaults
                    UserDefaults.standard.set(self.savedLiverecap, forKey: "LiverecapLive")
                    
                } else {
                    self.savedLiverecap[0] = "false"
                    self.defaults.set(self.savedLiverecap, forKey: "LiverecapLive")
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
       if let countDictionary = UserDefaults.standard.dictionary(forKey: "CountDictionaryRecordLive") as? [String: Int] {
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
       UserDefaults.standard.set(countDictionary, forKey: "CountDictionaryRecordLive")
   }




    @objc func appWillEnterBackGround() {
        if isstreaming {
            self.onToggleRecordBtn(toggleRecordBtn)
            alertBackgroundView()
        }else {
//            self.onToggleRecordBtn(toggleRecordBtn)
        }
    }
    

    @objc func appWillEnterForeground()
    {
//        alertBackgroundView()
    }
 
    @objc func animateFannerLogo(){
        imgFannerView.image = UIImage.gifImageWithName("fanner-logo-gift")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.imgFannerView.image = UIImage(named: "fanner_logo")
        }
    }
    
  
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        levelTimer?.invalidate()
        WindowDetailView.isHidden = true
        let matches = DataManager.shared.matches
        for currentMatch in matches {
            if currentMatch.id == selectedMatch.match.id {
                selectedMatch.match = currentMatch
                break
            }
        }
        isControllerActive = true
  
        let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":titleForWatch, "StartDate":Date()]
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isLoaded {
            if !isLiveMatch() {
                configCamera()
            } else {
                perform(#selector(self.setEnabledElements), with: nil, afterDelay: 1.0)
                Utiles.setHUD(false)
            }
            initLayout()
            isLoaded = true
            self.view.isUserInteractionEnabled = true
        }
        appDelegate.secondWindow?.isHidden = false
        testScore.isHidden = false
    }
    
    func startRecording() {
       
        fanGenView.isstremingPage = true
//        streamQueue.async {
        DispatchQueue.main.async{ [self] in
            self.toggleFlipBtn.alpha = 0.5
            self.toggleFlipBtn.isUserInteractionEnabled = false
//            self.toggleRecordBtn.isEnabled = false
            self.isRecorded = true
            self.cameraService.startRecording(self.fanGenService.createNewMainVideo(CMTIMESCALE, self.appDelegate.isSwiped))
        }
    }
    
    
    func stopRecording() {
  
        DispatchQueue.main.async{ [self] in
            self.toggleFlipBtn.alpha = 1.0
            self.toggleFlipBtn.isUserInteractionEnabled = true
            
        }
        saveTimerCountdownFromFanGenerationVideo()
          streamQueue.async {
              if self.cameraService.isRecording {
                  self.cameraService.stopRecording()
                  self.saveLivrecapData()
              }
        }
    }
    
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
    
//    @IBAction func Img1BtnClick(_ sender: UIButton) {
//
//        let tapGesture1 = UITapGestureRecognizer(target: self, action: #selector (tap1))  //Tap function will call when user tap on button
//        let longGesture1 = UILongPressGestureRecognizer(target: self, action: #selector(long1))  //Long function will call when user long press on button.
//            tapGesture1.numberOfTapsRequired = 1
//            img1Btn.addGestureRecognizer(tapGesture1)
//            img1Btn.addGestureRecognizer(longGesture1)
//    }
    
    


    @objc func long1() {
        fanGenView.player?.replaceCurrentItem(with: nil)
        imgArchive.isHidden = true
        player?.replaceCurrentItem(with: nil)
        self.imgArchive.backgroundColor = .clear

    }
    
    @objc func tap1() {
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
    
//    @IBAction func Img2BtnClick(_ sender: UIButton) {
//        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector (tap2))
//        let longGesture2 = UILongPressGestureRecognizer(target: self, action: #selector(long2))
//        tapGesture2.numberOfTapsRequired = 1
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
    
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .right:
                if !cameraService.isRecording {
                    print("Swiped right")
                }
            case .down:
                print("Swiped down")
            case .left:
                if !cameraService.isRecording {
                    print("Swiped left")
                }
            case .up:
                print("Swiped up")
            default:
                break
            }
        }
    }
    
 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        levelTimer?.invalidate()
        cameraService.removeAddedInputs()
        WindowDetailView.isHidden = true
        appDelegate.secondWindow?.isHidden = true
        RPScreenRecorder.shared().isMicrophoneEnabled = false
        
        let isCaptured = UIScreen.main.isCaptured
        if isCaptured {
            do {
                try self.rtmpStream.close()
                try rtmpConnection.close()
            } catch let error as NSError {
                // Handle the error appropriately
                print("Error closing RTMP stream/connection: \(error.localizedDescription)")
            }
        }else {
    
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !isLiveMatch() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: cameraService.currentCameraInput!.device)
        }
        isControllerActive = false
        let messageDict : [String:Any] = ["isStart":false,"isControllerActive":false]
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
    }
     
    override var shouldAutorotate: Bool {  
        if cameraService != nil && cameraService.isRecording {
            return true
        }else{
            return true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape{
            cameraService.updatePreviewOrientation()
        }
    }
    

    //MARK: - init functions
    
    //directory for audio recording
      func getDirectory() -> URL {
          let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
          let documentDirectory = paths[0]
          return documentDirectory
      }
    
    func soundlevel() {
        let url  = getDirectory().appendingPathComponent("audio.m4a")
        let recordSettings : [String : Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                               AVSampleRateKey: 44100,
                               AVNumberOfChannelsKey: 2,
                            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
                   ]
        // Start Audio Recording
                do {
                    audioRecorder = try AVAudioRecorder(url: url, settings: recordSettings)
                    audioRecorder.delegate = self
                    audioRecorder.record()
                    audioRecorder.isMeteringEnabled = true
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
                                 
    @objc func bottomCenterSwipe(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == .left || swipeGesture.direction == .right {
                print("bottom center swipe left or right")
                if !cameraService.isRecording {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.myOrientation = .landscape
                    if (isRecorded) {
                        self.appDelegate.isSwiped = true
                        isRecorded = false
                    }
                    dismiss(animated: true, completion: nil)
                }
            }
        }
    }
     
    // in recording mode
    func configCamera() {
        cameraService = CameraService( previewCam , timeLbl, selectedMatch.match.isResolution1280)
        cameraService.delegate = self
        cameraService.checkDeviceAuthorizationStatus { (isGranted, error) in
            if isGranted {
                self.cameraService.prepare(isFrontCamera: self.isFrontCamera, completionHandler: { (errorStr) in
                    if let err = errorStr {
                        MessageBarService.shared.error(err.localizedDescription)
                    } else {
                        do {
                            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.cameraService.currentCameraInput!.device)
                            try self.cameraService.displayPreview()
                            NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange(notification:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.cameraService.currentCameraInput!.device)
                            self.livePreview.isHidden = true
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
        zoomFactorBtn.isHidden = false
        if !fanGenView.isDisplayedSubViews {
            let pinchVelocityDividerFactor : Float = 50.0
            if pinchRecognizer.state == UIGestureRecognizer.State.changed {
                cameraService.pinchToZoom(pinchRecognizer, pinchVelocityDividerFactor)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if self.cameraService.isRecording {
                        if pinchRecognizer.state == .began {
                            self.zoomFactorBtn.isHidden = false
                        }else if pinchRecognizer.state == .changed {
                                self.zoomFactorBtn.isHidden = false
                            }
                        else {
                            self.zoomFactorBtn.isHidden = false
                        }
                    }else {
                        let pinchVelocityDividerFactor : Float = 50.0
                        if pinchRecognizer.state == UIGestureRecognizer.State.changed {
                            self.cameraService.pinchToZoom(pinchRecognizer, pinchVelocityDividerFactor)
                        }
                    }
                }
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
    
    func setToggleBtnImage(isStarted: Bool)  {
        
        if isStarted == true {

            imgLiveShow.image = UIImage(named: "liveStart")
//            fanGenView.bottomLeftView.isUserInteractionEnabled = true
//            fanGenView.bottomRightView.isUserInteractionEnabled = true
//            fanGenView.topLeftView.isUserInteractionEnabled = true
//            fanGenView.topRightView.isUserInteractionEnabled = true
        } else {
          
//            bottomBar.isHidden = false
//            viewCircle.backgroundColor = UIColor.white
//            imgRecording.image = UIImage(named: "ic_record_red")
//            toggleRecordBtn.setImage(UIImage(named: "ic_record_red"), for: .normal)

            fanGenView.bottomLeftView.isUserInteractionEnabled = false
            fanGenView.bottomRightView.isUserInteractionEnabled = false
            fanGenView.topLeftView.isUserInteractionEnabled = false
            fanGenView.topRightView.isUserInteractionEnabled = false
        }
        
        let image = isStarted ? Constant.Image.ToggleStop.image : Constant.Image.ToggleRecord.image
        print(image)
        toggleRecordBtn.setBackgroundImage(image, for: .normal)
    }
    
    
    //MARK: - main fucntions
    func isLiveMatch() -> Bool {
        return selectedMatch.match.type == .liveMatch
    }


    func startStreaming() {

        self.lblCurrentStatus.isHidden = false
        self.liveStatus.isHidden = false
        self.statusView.isHidden = false
        zoomFactorBtn.isHidden = false
        livePreview.isHidden = true
        previewCam.isHidden = false
        self.toggleRecordBtn.isEnabled = true
        self.isRecorded = true
        
        if isstreaming {
                    if rtmpConnection.connected {
                        publishStream()
                    } else {
                        connectRTMP()
                    }
                liveDesired = true
            } else {
                rtmpStream.close()
                liveDesired = false
            }
    }

    func alertView() {
        appDelegate.secondWindow?.isHidden = true
        let alert = UIAlertController(title: "Alert", message: "Please Enter Stream key And Stream Url", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
                case .default:
                print("default")
                self.appDelegate.secondWindow?.isHidden = false
                case .cancel:
                print("cancel")
                case .destructive:
                print("destructive")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
   
    func alertBackgroundView() {
        appDelegate.secondWindow?.isHidden = true
        let alert = UIAlertController(title: "Alert", message: "Live Streaming and Recording has stopped ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
                case .default:
                self.appDelegate.secondWindow?.isHidden = false
                self.onBackBtn(self)
                self.appDelegate.myOrientation = .portrait
                case .cancel:
                print("cancel")
                case .destructive:
                print("destructive")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func stopStreaming() {

        DispatchQueue.main.async {
          self.lblCurrentStatus.text = "Closed"
          self.imgCurrentStatus.image = UIImage(named: "icons8-no-video")
          self.timeLbl.text = "00:00:00"
        }
        self.liveStatus.isHidden = true
        self.statusView.isHidden = true
        self.toggleRecordBtn.isEnabled = true
        zoomFactorBtn.isHidden = false
        settingBtn.isHidden = false
        previewCam.isHidden = false
 
        if liveTimer != nil {
            liveTimer.invalidate()
            liveTimer = nil
        }
        validatesLayouts()
        setToggleBtnImage(isStarted: false)
        
        let isCaptured = UIScreen.main.isCaptured
        if isCaptured {
            self.rtmpStream.close()
            rtmpConnection.close()
                        
        }else {
    
        }
        liveDesired = false
        self.timeLbl.text = "00:00:00"
    }
    
    @objc func liveTimerAction() {
        liveTime += 1
        let timeNow = String( format :"%02d:%02d:%02d", liveTime/3600, (liveTime%3600)/60, liveTime%60)
        self.timeLbl.text = timeNow
    }
    
    @objc func endStreamingReaction() {
        Utiles.setHUD(false)
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

   
    func startUIChanges() {
        
        DispatchQueue.main.async {
            self.toggleRecordBtn.isEnabled = true
            self.lblfpskbps.isHidden = false
            self.imgLiveShow.image = UIImage(named: "liveStart")
            self.settingBtn.isHidden = false
            self.zoomFactorBtn.isHidden = false
            self.livePreview.bringSubviewToFront(self.settingBtn)
            
            self.isScreenCaptured = true
            self.fanGenService.firstExcute = 1
            self.isstreaming = true
        }
    }
    
    
    func stopUIChanges() {
        DispatchQueue.main.async {
            self.fanGenView.isstremingPage = false
            self.zoomFactorBtn.isHidden = false
            self.settingBtn.isHidden = false
            self.livePreview.isHidden = true
            self.previewCam.isHidden = false
            
            self.toggleRecordBtn.isEnabled = true
            self.settingBtn.isHidden = false
            self.zoomFactorBtn.isHidden = false
            self.fanGenView.bottomLeftView.isUserInteractionEnabled = false
            self.fanGenView.bottomRightView.isUserInteractionEnabled = false
            self.fanGenView.topLeftView.isUserInteractionEnabled = false
            self.fanGenView.topRightView.isUserInteractionEnabled = false
            
            self.currentIndex = 0
            self.fanGenService.firstExcute = 0
            self.indexClipArr = 0
            self.lblfpskbps.isHidden = true
            self.isUploadingClipProcess = false
            
            self.timeLbl.text = "00:00:00"
            self.isstreaming = false
        }
    }
    
    @IBAction func onToggleRecordBtn(_ sender: UIButton) {

            if isstreaming {
                self.stopRecording()
                
                if notStopStreaming == false {
                    self.setupStopStreaming()
                }
                
                   self.saveLivrecapData()
             
                 if isLiverecap == true {
                     self.isRecapListSelected = false
                 }
                
                DispatchQueue.main.async {
                    //                  [weak self]     in
                    let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
                if isControllerActive == true {
                    let messageDict : [String:Any] = ["isStart":false]
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                }
                uploadQueue.async {
                    self.stopUIChanges()
                }
            } else {
         
                let userDefaults = UserDefaults.standard
                savedRtmpSettings = userDefaults.stringArray(forKey: "RTMPSettingDataa") ?? []
                if savedRtmpSettings.isEmpty {
                    if streamKey == "" && rtmpEndpoint == "" {
                        self.isstreaming = false
                        alertView()
                        return
                    }
                }else {
                    
                    
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
                    
                   
                
                    DispatchQueue.main.async {
                        let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
                            FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                        }
                        if isControllerActive == true {
                            let messageDict : [String:Any] = ["isStart":true]
                            FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                        }
                }
            }
    }
    
    private func stopScreenRecording() {
    }
    
    private func startScreenRecording() {
        self.rtmpEndpoint = savedRtmpSettings[0]
         self.streamKey = savedRtmpSettings[1]
        self.audioQuality = Int(savedRtmpSettings[2])!
        self.selectedFrameRate = Int(savedRtmpSettings[3])!
        let qualityIndex = savedRtmpSettings[4]
        self.preset = segmentedPresets[Int(qualityIndex)!]
        let bRate = Int(savedRtmpSettings[5])
        self.BitrateValue = bRate!*1000
       
       if streamKey == "" || rtmpEndpoint == "" {
           self.isstreaming = false
           alertView()
           return
       }
       self.startRecording()
       
       uploadQueue.async {
           self.startUIChanges()
       }
       
       if notStopStreaming == false {
         
           self.setupStartStreaming()
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
    
    func initialFullSetupAVWriter() {
        self.ts = String(Int(NSDate().timeIntervalSince1970 * 1000))
        self.documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        self.videoOutputURLFull = URL(fileURLWithPath: self.documentsPath.appendingPathComponent("MyVideo" + ts + ".mp4"))
        // Check if the file already exists and delete it if necessary
        do {
            try FileManager.default.removeItem(at: videoOutputURLFull)
        } catch {
            print("File cannot be deleted or not found! ", error.localizedDescription)
        }
        
        do {
            videoWriterFull = try AVAssetWriter(outputURL: videoOutputURLFull, fileType: AVFileType.mp4)
        } catch let writerError as NSError {
            print("Error opening video file", writerError)
            videoWriterFull = nil
            return
        }
        // Video settings
        let videoOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: UIScreen.main.bounds.size.width,
            AVVideoHeightKey: UIScreen.main.bounds.size.height,
        ]

        // Audio settings
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100.0,
            AVEncoderBitRateKey: 96000,
        ]
        
        
        videoWriterInputFull = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
          audioWriterInputFull = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)

        videoWriterInputFull?.expectsMediaDataInRealTime = true
        audioWriterInputFull?.expectsMediaDataInRealTime = true

        videoWriterFull?.add(videoWriterInputFull!)
        videoWriterFull?.add(audioWriterInputFull!)
    }
    
    func setupStartStreaming(){
        self.toggleRecordBtn.isUserInteractionEnabled = true
        self.toggleRecordBtn.alpha = 1.0
        self.rtmpSetup()
        self.cameraService.changefps(fps: selectedFrameRate)
        rtmpStream.videoSettings[.bitrate] = BitrateValue

    if isScreenCaptured {
        RPScreenRecorder.shared().stopCapture()
    }else {
        
        
        initialSetupAVWriter()
        initialFullSetupAVWriter()
        RPScreenRecorder.shared().isMicrophoneEnabled = true
        
        RPScreenRecorder.shared().startCapture { [weak self] cmSampleBuffer, rpSampleBufferType, err in
            guard let self = self else { return }
            
            self.handleSampleBuffer(cmSampleBuffer, sampleType: rpSampleBufferType)
            // Handle errors if needed
            
            
        }

        
    }
        
        DispatchQueue.main.async {
            self.startStreaming()
        }

        rtmpHandlerQueue.async {
            
            // Add event listeners for RTMP status changes and IO Errors
            self.rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(self.rtmpStatusHandler), observer: self)
            self.rtmpConnection.addEventListener(.ioError, selector: #selector(self.rtmpErrorHandler), observer: self)
        }
    }
        


    func setupStopStreaming(){
        self.toggleRecordBtn.isUserInteractionEnabled = true
        self.toggleRecordBtn.alpha = 1.0
        self.exitBtn.isUserInteractionEnabled = true
        self.exitBtn.alpha = 1.0
        
        if isScreenCaptured {
            if notStopStreaming == false {
                RPScreenRecorder.shared().stopCapture()
                self.isScreenCaptured = false
            }
        }
      
//        self.stopAudioRecording()
        DispatchQueue.main.async {
            self.stopStreaming()
        }
        
        
        rtmpHandlerQueue.async {
            self.rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(self.rtmpStatusHandler), observer: self)
            self.rtmpConnection.removeEventListener(.ioError, selector: #selector(self.rtmpErrorHandler), observer: self)
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
//                           self.saveToPhotos(tempURL: self.finalstableVidURL)
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

//    func cropVideoWidth(from videoURL: URL, to outputURL: URL, completion: @escaping (Error?) -> Void){
//        let asset = AVAsset(url: videoURL)
//
//        // Video track
//        let composition = AVMutableComposition()
//        let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
//        if let videoAssetTrack = asset.tracks(withMediaType: .video).first {
//            try? videoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoAssetTrack, at: .zero)
//        }
//
//        // Audio track
//        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//        if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
//            try? audioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioAssetTrack, at: .zero)
//        }
//
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            let videoSize = videoTrack?.naturalSize ?? .zero
//
//            print("videoSize :: \(videoSize)")
//            let transform = videoTrack?.preferredTransform ?? .identity
//            let videoAspectRatio = videoSize.width / videoSize.height
//
//            // Get the current screen width
//            let screenWidth: CGFloat = UIScreen.main.bounds.size.width
//            let screenHeight: CGFloat = UIScreen.main.bounds.size.height
//            print("screenWidth :: \(screenHeight)")
//            // Calculate the desired height and the amount to crop equally from the top and bottom
//            //        let desiredHeight: CGFloat = 610
//
//            // Specify the desired aspect ratio
//            let aspectRatioWidth: CGFloat = 4.0
//            let aspectRatioHeight: CGFloat = 3.0
//
//            let newCropHeight = (screenHeight * aspectRatioHeight) / aspectRatioWidth //610
//
//            print("newCropHeight :: \(newCropHeight)")
//            print("videoSize.height :: \(videoSize.height)")
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
//
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
//            let desiredWidth : CGFloat = heightScreen * videoAspectRatio
//            let desiredHeight : CGFloat = heightScreen
//
//
//            // Specify the desired aspect ratio
////            let aspectRatioWidth: CGFloat = 16.0
////            let aspectRatioHeight: CGFloat = 9.0
//
//            // Get the current screen height 926 × 428 1024 × 768  812 × 375
//            let screenHeight : CGFloat = UIScreen.main.bounds.size.height
//            let screenWidth : CGFloat = UIScreen.main.bounds.size.width
//
//
////            // Calculate the targetScreenWidth to maintain the desired aspect ratio
////            let targetScreenWidth = (screenHeight * aspectRatioWidth) / aspectRatioHeight
////
////            let xupdate = (screenWidth - targetScreenWidth) / 2
////
////            print("xupdate : \(xupdate)")
////
//
//
//            print("16:9 :: \(desiredHeight)")
////            let desiredHeight: CGFloat = heightScreen // The target height
//            let aspectRatioWidth = (16 / 9) * desiredHeight
//
//            print("aspectRatioWidth \(aspectRatioWidth)")
//
////            let number = 666.67
//            let nearestLowerDivisibleBy16 = Int(aspectRatioWidth / 16) * 16
//            print("nearestLowerDivisibleBy16 \(nearestLowerDivisibleBy16)")
//
//            let xupdate = (Int(screenWidth) - nearestLowerDivisibleBy16) / 2
//            print("xupdate : \(xupdate)")
//            print("Width for 16:9 aspect ratio at a height of \(desiredHeight) is: \(aspectRatioWidth)")
//
//
//            // Apply the crop to the video track
//            let instruction = AVMutableVideoCompositionInstruction()
//            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
//
//            let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
//            let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
//            let translate = CGAffineTransform(translationX: -CGFloat(xupdate), y: 0)
//            transformer.setTransform(scale.concatenating(translate), at: .zero)
//
//    //        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
//    //        let scale = CGAffineTransform(scaleX: 1.0, y: 1.0)
//    //        let translate = CGAffineTransform(translationX: -80, y: 0) // Adjust the X value as needed
//    //        transformer.setTransform(scale.concatenating(translate), at: .zero)fewrqfgcewhgewds dx
//
//
//
//            instruction.layerInstructions = [transformer]
//
//            videoComposition = AVMutableVideoComposition()
//            videoComposition.instructions = [instruction]
//            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
//            videoComposition.renderSize = CGSize(width: CGFloat(nearestLowerDivisibleBy16), height: desiredHeight)
//        }
//        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
//            completion(NSError(domain: "VideoCropErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"]))
//            return
//        }
//
//        exportSession.videoComposition = videoComposition
//        exportSession.outputURL = outputURL
//        exportSession.outputFileType = .mp4
//
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
                        UserDefaults.standard.set(self.savedLiverecap, forKey: "LiverecapLive")
                        
                    }else {
                        UserDefaults.standard.set(self.savedLiverecap, forKey: "LiverecapLive")
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

        
        //Add Rtmp Setting
        let rtmpAction = UIAlertAction(title: ActionTitle.liveSetting.rawValue, style: .default) { (rtmpAction) in
            if self.cameraService.isRecording {
                self.appDelegate.secondWindow?.isHidden = false
            }else{
                self.appDelegate.secondWindow?.isHidden = true
                self.isLiveStreamRTMP = self.isLiveStreamRTMP
                let overLayerView = OverLayerView()
                overLayerView.appear(sender: self)
                topWindow?.isHidden = true
                topWindow = nil
            }
        }
        
        if cameraService.isRecording {
            rtmpAction.isEnabled = false
        }else {
            rtmpAction.isEnabled = true
        }
        rtmpAction.setValue(!self.isLiveStreamRTMP, forKey: SheetKeys.isChecked.rawValue)
        sheetController.addAction(rtmpAction)
        
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

    func resetCounter(){
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
        UserDefaults.standard.set(countDictionary, forKey: "CountDictionaryRecordLive")
    }
    
    @IBAction func onUndoBtn(_ sender: UIButton) {
        MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure you want to remove the last clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
            let (undoMarker, undoTeam) = self.fanGenService.getLastClipInfo()
            self.fanGenView.undoAnimation(undoMarker, undoTeam)
            self.setUndoBtnEnabled(self.fanGenService.undoAction())
        }, onNo: nil)
    }
 
    @IBAction func onBackBtn(_ sender: Any)
    {
        
        if fanGenView.timer?.isValid == true {
            // The timer is running, so we should stop it
            self.fanGenView.onStartBtn(self.fanGenView.startBtn)
            self.saveTimerCountdownFromFanGenerationVideo()
        }
        
        self.defaults.set(self.savedLiverecap, forKey: "LiverecapLive")
        self.appDelegate.loginWindow = nil
        self.appDelegate.secondWindow = nil
        levelTimer?.invalidate()
        levelTimer = nil
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myOrientation = .portrait
        dismiss(animated: true, completion: nil)
    }
    
      
    @IBAction func onFlipCameraBtn(_ sender: Any) {
        
        if !isLiveMatch() {
            Utiles.setHUD(true, view, .extraLight, "Load camera...")
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
    
    
    func rtmpSetup() {
        
        if ( UIDevice.current.isMultitaskingSupported ) {
            self.backgroundStreamingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
                rtmpStream = RTMPStream(connection: rtmpConnection)
                rtmpStream.delegate = self
        
                if #available(iOS 13.0, *) {
                    if let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                        let videoOrientation = DeviceUtil.videoOrientation(by: orientation)
                        rtmpStream.orientation = videoOrientation!
                    }
                } else {
                    // Fallback on earlier versions
                }

                NotificationCenter.default.addObserver(self, selector: #selector(on(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)

                configureStream(preset: self.preset! , selectedFrameRate: selectedFrameRate)
//                rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
//
//                }
       
        // Configure AVCaptureVideoDataOutput
//             let videoOutput = AVCaptureVideoDataOutput()
//              videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//
//        cameraService.captureSession?.addOutput(videoOutput)
//        rtmpStream.attachCamera(DeviceUtil.device(withPosition: defaultCamera)) { error in
//            print(error.description)
//        }
//        rtmpStream.attachScreen(ScreenCaptureSession(viewToCapture: livePreview))
//        rtmpStream.attachScreen(ScreenCaptureSession(viewToCapture: livePreview))
        livePreview.attachStream(rtmpStream)
    }

    // Called when the RTMPStream or RTMPConnection changes status
  
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        print("RTMP Status Handler called.")
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
 
        
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue, RTMPStream.Code.publishStart.rawValue, RTMPStream.Code.unpublishSuccess.rawValue:
            DispatchQueue.main.async {
                self.lblCurrentStatus.text = "Success"
                self.imgCurrentStatus.image = UIImage(named: "icons8-ok")
//                MessageBarService.shared.warning("Successfully Connected !!!")
            }
        case RTMPConnection.Code.connectFailed.rawValue:
            DispatchQueue.main.async {
                self.lblCurrentStatus.text = "Failed"
                self.imgCurrentStatus.image = UIImage(named: "icons8-failed")
                MessageBarService.shared.warning("Bad Connection !!!")
            }
        case RTMPConnection.Code.connectClosed.rawValue:
            DispatchQueue.main.async {
                self.lblCurrentStatus.text = "Closed"
                self.imgCurrentStatus.image = UIImage(named: "icons8-no-video")
                self.timeLbl.text = "00:00:00"
                MessageBarService.shared.warning("Connection Closed!!!")
            }
    
        default:
            break
        }
        
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            print("RTMP Connection was successful.")
            reconnectAttempt = 0
            if liveDesired {
                publishStream()
            }
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            print("RTMP Connection was not successful.")
            
            if liveDesired {
                reconnectAttempt += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.connectRTMP()
                }
            }
        default:
            break
        }
    }



    // Called when there's an RTMP Error
    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        print("RTMP Error Handler called.")
        connectRTMP()
    }
    
    // Called when the device changes rotation
    @objc
    private func on(_ notification: Notification) {
        if #available(iOS 13.0, *) {
            if let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                let videoOrientation = DeviceUtil.videoOrientation(by: orientation)
                rtmpStream.orientation = videoOrientation!
                if liveDesired == false {
                    let profile = presetToProfile(preset: self.preset)
                    rtmpStream.videoSettings = [
                        .width: (orientation.isPortrait) ? profile.height : profile.width,
                        .height: (orientation.isPortrait) ? profile.width : profile.height
                    ]
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    // RTMPStreamDelegate callbacks
    func rtmpStreamDidClear(_ stream: RTMPStream) {
        
    }
    
    // Statistics callback
    func rtmpStream(_ stream: RTMPStream, didPublishSufficientBW connection: RTMPConnection) {
            let fpsValue = stream.currentFPS
            let fps = String(stream.currentFPS) + " fps"
            let kbpsValue = (connection.currentBytesOutPerSecond / 125)
            let kbps = String((connection.currentBytesOutPerSecond / 125)) + " kbps"
            self.lblfpskbps.text = "\(fps) \(kbps)"
        
        //FPS
        let settingValueFPS = self.selectedFrameRate
        print(fpsValue)

        let seventyPercentThresholdFPS = Double(settingValueFPS) * 0.85 //27
        let fiftyPercentThresholdFPS = Double(settingValueFPS) * 0.75 //24


//        rtmpHandlerQueue.async {
//            let settingValueKbps = self.BitrateValue/1000
//            let seventyPercentThreshold = Double(settingValueKbps) * 0.6 //2100
//            let fiftyPercentThreshold = Double(settingValueKbps) * 0.4 //1500
//
//
//                if Double(fpsValue) < fiftyPercentThresholdFPS {
//                    SwiftMessageBar.Config.Defaults.infoColor = .red
//                    print("Bad connection: FrameRate is below 80% of the setting value")
//                    DispatchQueue.main.async {
//                        MessageBarService.shared.error("Bad Connection for FPS!!!")
//                    }
//                } else if Double(fpsValue) < seventyPercentThresholdFPS {
//                    SwiftMessageBar.Config.Defaults.infoColor = .orange
//                    print("Poor connection: FrameRate is below 90% of the setting value")
//                    DispatchQueue.main.async {
//                        MessageBarService.shared.warning("Poor Connection for FPS !!!")
//                    }
//                } else if Double(kbpsValue) < fiftyPercentThreshold {
//                    SwiftMessageBar.Config.Defaults.infoColor = .red
//                    print("Bad connection: Bitrate is below 50% of the setting value")
//                    DispatchQueue.main.async {
//                        MessageBarService.shared.error("Bad Connection for Bitrate !!!")
//                    }
//                } else if Double(kbpsValue) < seventyPercentThreshold {
//                    SwiftMessageBar.Config.Defaults.infoColor = .orange
//                    // Notify bad connection for Bitrate
//                    print("Poor connection: Bitrate is below 70% of the setting value")
//                    DispatchQueue.main.async {
//                        MessageBarService.shared.warning("Poor Connection for Bitrate !!!")
//                    }
//                } else {
//                    // FPS and Bitrate are above their respective thresholds
//                    print("Good connection")
//                }
//
//        }
    }
    
    
    // Insufficient bandwidth callback
    func rtmpStream(_ stream: RTMPStream, didPublishInsufficientBW connection: RTMPConnection) {
        print("ABR: didPublishInsufficientBW")
                if (Int(NSDate().timeIntervalSince1970) - lastBwChange) > 5 {
            print("ABR: Will try to change bitrate")
            
            let b = Double(stream.videoSettings[.bitrate] as! UInt32) * Double(0.7)
            print("ABR: Proposed bandwidth: " + String(b))
            stream.videoSettings[.bitrate] = b
            lastBwChange = Int(NSDate().timeIntervalSince1970)
            
//          DispatchQueue.main.async {
//                Loaf("Insuffient Bandwidth, changing video bandwidth to: " + String(b), state: Loaf.State.warning, location: .top,  sender: self).show(.short)
//            }
        } else {
            print("ABR: Still giving grace time for last bandwidth change")
        }
    }

    

    func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer, sampleType: RPSampleBufferType) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch sampleType {
            case .video:
                // Handle video sample buffer
                DispatchQueue.main.async {
                    self.rtmpStream.videoSettings[.bitrate] = self.BitrateValue
                    self.rtmpStream.appendSampleBuffer(sampleBuffer, withType: .video)
                }
                
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
    }


    func accessSavedClip(index: Int) {
        print("process for uploading: \(currentClipUploadIndex)")
        self.videoData = nil
        do {
            let clipURL = clipUrlArray[currentClipUploadIndex]
            self.videoData = try Data(contentsOf: clipURL)
            self.uploadClip = self.fanGenService.clipsArr
       
//            self.removeFile(at: clipURL)
            print(currentClipUploadIndex)
            self.currentClipTimestamp = timestampArr[currentClipUploadIndex]
            self.sendToLiverecapVideoSelection(quality: self.isQuality, index: self.currentClipUploadIndex, ClipURL: clipURL)
            
        } catch {
            print("Error accessing video data: \(error)")
            
            self.uploadingIndexStatus = self.uploadingIndexStatus-1
            self.toggleRecordBtn.isUserInteractionEnabled = true

            print(self.uploadingIndexStatus)
            print(self.currentClipUploadIndex)

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
//                                     self.UploadVideoToServer(highBitrate, newVideo, 0, generator, false)
            }
            
        }
    }
 
    
//    func accessSavedClip(index: Int) {
//        print("process for uploading: \(currentClipUploadIndex)")
//        self.videoData = nil
//        do {
//            let clipURL = clipUrlArray[currentClipUploadIndex]
//            self.videoData = try Data(contentsOf: clipURL)
//            self.uploadClip = self.fanGenService.clipsArr
//            self.currentClipTimestamp = timestampArr[currentClipUploadIndex]
//            self.sendToLiverecapVideoSelection(quality: self.isQuality, index: 0, ClipURL: clipURL)
//
//        } catch {
//            print("Error accessing video data: \(error)")
//        }
//    }

    
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
        
    func endUpload(){
        self.toggleRecordBtn.isUserInteractionEnabled = true
        self.toggleRecordBtn.alpha = 1.0
        self.exitBtn.isUserInteractionEnabled = false
        self.exitBtn.alpha = 0.5
        
        if self.fanGenService.clipsArr.count == 0 {
            self.fanGenService.clipsArr.removeAll()
        }else {
            self.fanGenService.clipsArr.removeFirst()
        }
        
        self.fanGenView.markerView.f_new_collectiveBtn.isUserInteractionEnabled = true
        self.fanGenView.markerView.s_new_collectiveBtn.isUserInteractionEnabled = true
        if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.f_new_collectiveBtn {
            self.fanGenView.markerView.f_new_collectiveBtn.hideLoading()
  
        }
        if self.fanGenView.markerView.selectedBtn == self.fanGenView.markerView.s_new_collectiveBtn {
            self.fanGenView.markerView.s_new_collectiveBtn.hideLoading()

        }
     
        self.isUploadingClipProcess = false

    }
    

    func convertImageToBase64String (img: UIImage) -> String {
        return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }

}




extension MatchesMainVideoRecordLiveVC: UIColorPickerViewControllerDelegate {
    
    //  Called once you have finished picking the color.
    @available(iOS 14.0, *)
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.fanGenView.viewTeam1.backgroundColor = viewController.selectedColor
        
    }
    
    //  Called on every color selection done in the picker.
    @available(iOS 14.0, *)
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            self.fanGenView.viewTeam1.backgroundColor = viewController.selectedColor
    }
}


//MARK: - UIGestureRecognizerDelegate

extension MatchesMainVideoRecordLiveVC: UIGestureRecognizerDelegate {
    
}

//MARK: - CameraServiceDelegate

extension MatchesMainVideoRecordLiveVC: CameraServiceDelegate {
    
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
//                else if AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil {
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
        // For watch Need  to call here
        let messageDict : [String:Any] = ["isStart":true, "Time": self.timeLbl.text ?? "", "Title":titleForWatch]
        //  let sendingData: [String : [String : Any]] = ["Data" : ["message":"Get+startRecording", "Time":self.timeLbl.text ?? "", "Title":"AA:BB"]]
        //overheat
        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {
        }
        
//        print("Call : onRecordingAMinute")
        // -- For watch End --

//        var firstExe = 0
//        if firstExe == 0 {
//            fanGenView.setCurrentMatchTime(fanGenService.matchTime(with: currentTime))
//
//            firstExe = 1
//        }
//        fanGenView.setCurrentMatchTime(fanGenService.matchTime(with: currentTime))
//        fanGenService.matchTime(with: currentTime)
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

extension MatchesMainVideoRecordLiveVC : FannerCamWatchKitSharedDelegate {
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
                    //                self.setUndoBtnEnabled(true)+++
                }
                print(3)
            }
        }  else if controller == "TagController" {
            if isControllerActive == true {
                
                
                isFromWatch = true
                
                let selectedTag = watchMessage["SelectedTag"] as! Int
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "TapOnCollectiveTag"), object: nil, userInfo: ["SelectedTag" : selectedTag])
                
                //          DispatchQueue.main.async {
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
                        FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {}
                    }
                } else {
                    
                  DispatchQueue.main.async {
                      let messageDict : [String:Any] = ["isStart":false, "Time": self.timeLbl.text ?? "", "Title":self.titleForWatch, "StartDate":Date()]
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
    
    //MARK: - Backgrou   nd & forground notifications
    
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

extension MatchesMainVideoRecordLiveVC: FanGenerationVideoDelegate, FanGenerationVideoDataSource {

    func didSaveScoreboardSwitch(_ switchScoreboard: Bool?) {
        
        if switchScoreboard == true {
            testScore.isHidden = false
            fanGenView.topScoreView.isHidden = false
            MessageBarService.shared.notify ("Successfully saved changed setting!")
        }else {
            testScore.isHidden = true
            fanGenView.topScoreView.isHidden = true
            MessageBarService.shared.notify("Successfully saved changed setting!")
        }

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
                
        if (!fanGenView.isTimerOn)
        {
            fanGenView.DisplayInitialTime(fanGenService.selectedMatch.match.timerTime ?? appDelegate.videoTimerTime, fanGenService.selectedMatch.match.countdownTime ?? appDelegate.videoCountdownTime, fanGenService.selectedMatch.match.isTimeFromCountdown ?? appDelegate.isTimeFromCountdown)
        }
        view.bringSubviewToFront(fanGenView)
    }

    
    
    func didTapGoal(_ fanGenerationVideo: FanGenerationVideo, goals value: String, team: Team) {
        _ = fanGenService.setGoals(cameraService.currentRecordedTime, Int(value) ?? 0, team)
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
                
                MessageBarService.shared.notify("3333 Successfully saved changed setting!")
            } else {

                    if fanGenView.isHomeColorChanged == true {
                        
                    }else if fanGenView.isAwayColorChanged == true {
                        
                    }else {
                        
                        saveScoreboardData = ["\(fanGenView.isSwitchScoreboardPosition)" , "\(fanGenView.isSwitchColorPosition)" , "\(fanGenView.isSwitchTimerPosition)" , "\(String(describing: fanGenView.saveColorTeame1))" ,"\(String(describing: fanGenView.saveColorTeame2))"]

                        defaults.set(saveScoreboardData, forKey: "ScoreboardDataLive")
                        
                        if fanGenView.isSwitchScoreboardPosition == Bool(saveScoreboardData[0]) && fanGenView.isSwitchColorPosition == Bool(saveScoreboardData[1]) && fanGenView.isSwitchTimerPosition == Bool(saveScoreboardData[2]) {
               
                            if fanGenView.isTimeAnyChange == true {
                                MessageBarService.shared.notify("Successfully saved changed setting!")
                                fanGenView.isTimeAnyChange = false
                            }else {
                                MessageBarService.shared.warning("No changed setting")
                            }
                        }else {
       
                            MessageBarService.shared.notify("2222 Successfully saved changed setting!")
                        }
                        
                    }
                    ZeroCheck = 0
//                }

                self.fanGenView.isHomeColorChanged = false
                self.fanGenView.isAwayColorChanged = false
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




//    @objc func bottomLeftSingleTap(_ sender : UITapGestureRecognizer){ sf s fgsg dg f
//        print("bottom left single tap")
//        self.imgFannerView.rotate()
//        //self.rotateView(targetView: viewLogo, duration: 1.0)
//        //self.runSpinAnimation(on: viewLogo, duration: 1.0, rotations: 1, repeatCount: 1)
//    }

//    @objc func bottomLeftLongPress(_ sender : UILongPressGestureRecognizer){
//        if sender.state == .began {
//            print("bottom left long press")
//            if self.cameraService.isRecording {
//                if self.fanGenService.getFirstTeamMarkers() == nil {
//                    return
//                }
//                MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure you want to remove the last clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
//                    if self.fanGenService.getFirstTeamMarkers() != nil  {
//                        //self.fanGenView.undoAnimation(currentclip.marker, currentclip.team)
//                        self.setUndoBtnEnabled(self.fanGenService.undoAction())
//                    }
//                }, onNo: nil)
//            }
//        }
//    }

//    @objc func bottomRightSingleTap(_ sender : UITapGestureRecognizer){
//        print("bottom right single tap")
//        self.imgFannerView.rotate()
//    }
//
//    @objc func bottomRightLongPress(_ sender : UILongPressGestureRecognizer){
//        if sender.state == .began {
//            print("bottom right long press")
//            if self.cameraService.isRecording {
//                if self.fanGenService.getSecondTeamMarkers() == nil {
//                    return
//                }
//                MessageBarService.shared.alertQuestion(title: "Warning!", message: "Are you sure you want to remove the last clip?", yesString: "Yes", noString: "No", onYes: { (yesAction) in
//                    if self.fanGenService.getSecondTeamMarkers() != nil  {
//                        //self.fanGenView.undoAnimation(currentclip.marker, currentclip.team)
//                        self.setUndoBtnEnabled(self.fanGenService.undoAction())
//                    }
//
//                }, onNo: nil)
//            }
//        }
//    }

//func converterDataToClip(){
//    if let encodedData = UserDefaults.standard.data(forKey: "clipsKey") {
//        // Create an instance of PropertyListDecoder
//        let decoder = PropertyListDecoder()
//
//        do {
//            // Decode the data back into an array of clips
//            let decodedData = try decoder.decode(Clip.self, from: encodedData)
//
//            print(decodedData)
//
//            self.uploadingClip = [decodedData]
//            print(uploadingClip)
//            // Access the properties of the decoded clip object
////                let id = decodedData.id
////                let mainVideoStartTime = decodedData.mainVideoStartTime
////                let endTime = decodedData.endTime
////                // ... access other properties as needed
////
////                print(id)
////                print(mainVideoStartTime)
////                print(endTime)
//
//        } catch {
//            print("Error decoding clips: \(error)")
//        }
//    }
//
//
//}

/*
 //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
 //        let touchPer = touchPercent(touch: touches.first! as UITouch)
 //        cameraService.updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
 //    }
 //
 //    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
 //        let touchPer = touchPercent(touch: touches.first! as UITouch)
 //        cameraService.updateDeviceSettings(focusValue: Float(touchPer.x), isoValue: Float(touchPer.y))
 //    }
 
//         func supportedInterfaceOrientations() -> Int {
//            print("supportedInterfaceOrientations")
//            return Int(UIInterfaceOrientationMask.landscapeLeft.rawValue)
//        }
//    //
//         func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
//            return UIInterfaceOrientation.landscapeLeft
//        }
//
 */
