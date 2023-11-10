//
//  CameraService.swift
//  NewFannerCam
//
//  Created by Jin on 1/24/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol CameraServiceDelegate: AnyObject {
    func onChangeZoomFactor(_ zoomFactor: CGFloat?)
    func onRecordingAMinute(_ currentTime: CMTime)
    func cameraService(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection])
    func cameraService(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?)
}

class CameraService : NSObject {
    var rtmpSetting                                 : Bool = true
    var autoExposure                                : Bool = true
    var clipLiverecap                                : Bool = true
    var liverecap                                   : Bool = true
    var CountReset                                : Bool = true
    var discoverySession                            : AVCaptureDevice.DiscoverySession!
    
    //MARK: - Properties
    weak var delegate                               : CameraServiceDelegate?
    var scoreboard                                : Bool = true

    private var sessionQueue                        : DispatchQueue!
     var captureSession                      : AVCaptureSession?
     var movieFileOutput                     : AVCaptureMovieFileOutput?
    private var photoOutput                         : AVCapturePhotoOutput?
    var currentCameraInput                          : AVCaptureDeviceInput?
    private var currentCamera                       : AVCaptureDevice?
    private var rearCamera                          : AVCaptureDevice?
    private var frontCamera                         : AVCaptureDevice?
    
    private var preview                             : UIView?
    private var previewLayer                        : AVCaptureVideoPreviewLayer?
    
    private var timeLbl                             : UILabel!
    private var timer                               : Timer!
    
    private var isHD                                : Bool = true
    
    private var backgroundRecordingID               : UIBackgroundTaskIdentifier!
    
    var isRecording : Bool {
        return self.movieFileOutput?.isRecording ?? false
    }
    
    var autoFocus                                   : Bool = true
    
    //MARK: - Init Function
    init(_ preview: UIView, _ timeLabel: UILabel, _ isHDResolution: Bool) {
        self.preview = preview
        self.timeLbl = timeLabel
        isHD = isHDResolution
    }
    
    func checkDeviceAuthorizationStatus(_ completion: @escaping (Bool, String) -> Void) {
        let mediaType = AVMediaType.video
        AVCaptureDevice.requestAccess(for: mediaType) { (granted) in
            if (granted) {
                completion(true, "Granted!")
            } else {
                completion(false, "Fanner doesn't have permission to use Camera, please change privacy settings")
            }
        }
    }
    
    func prepare(isFrontCamera:Bool, completionHandler: @escaping (Error?) -> Void) {
        
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
            self.captureSession?.sessionPreset = isHD ? AVCaptureSession.Preset.hd1280x720 : AVCaptureSession.Preset.hd1920x1080
            
//            self.captureSession?.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160

            self.captureSession?.usesApplicationAudioSession = true
            self.captureSession?.automaticallyConfiguresApplicationAudioSession = false
        }
        
        func primaryVideoDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
            
            
            //For Triple camera
            if #available(iOS 13.0, *) {
                if AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .unspecified) != nil {
                    // Your iPhone has TripleCamera.
                    var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInTripleCamera]
                    deviceTypes.append(contentsOf: [.builtInTrueDepthCamera , .builtInMicrophone])
                     discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
                    return discoverySession.devices.first
                    
                }
            }
            
            //For Dual wide
//            var discoverySession : AVCaptureDevice.DiscoverySession!
            if #available(iOS 13.0, *) {
                if AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .unspecified) != nil {
                    // Your iPhone has DualWideCamera.
                    var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInDualWideCamera]
                    deviceTypes.append(contentsOf: [.builtInTrueDepthCamera , .builtInMicrophone])
                     discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
                    print("front builtInDualWideCamera")
                    return discoverySession.devices.first
                    
                }
            }
            
           
            
            //For wide and telephoto
            if #available(iOS 13.0, *) {
                if AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .unspecified) != nil {
                    // Your iPhone has dual camera.
                    var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInDualCamera]
//                    deviceTypes.append(contentsOf: [.builtInWideAngleCamera , .builtInTrueDepthCamera , .builtInMicrophone])
                    
                    if isFrontCamera{
                        print("front")
                        deviceTypes.append(contentsOf: [.builtInWideAngleCamera , .builtInTrueDepthCamera , .builtInMicrophone])
                    }else{
                        print("back")
                        deviceTypes.append(contentsOf: [.builtInTrueDepthCamera , .builtInMicrophone])
                    }
                     discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
                    print("builtInDualCamera")
                    return discoverySession.devices.first
                    
                }
            }
            // For Dual camera
             if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) != nil {
                 // Your iPhone has DualWideCamera.
                 var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
                 deviceTypes.append(contentsOf: [.builtInTrueDepthCamera , .builtInMicrophone])
                  discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
                 print("builtInWideAngleCamera")
                 return discoverySession.devices.first
                 
             }
            
           
            return discoverySession.devices.first
            
        }
        
        
        func configureCaptureDevices() throws {
            
            primaryVideoDevice(forPosition: .unspecified)
            print(discoverySession)
            
//            let supportedDeviceTypes : [AVCaptureDevice.DeviceType]?
//            if #available(iOS 13.0, *) {
//                supportedDeviceTypes =  [AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .unspecified) != nil ? .builtInDualCamera : .builtInWideAngleCamera, .builtInTripleCamera, .builtInTrueDepthCamera, .builtInMicrophone]
//            }else {
//                supportedDeviceTypes = [.builtInWideAngleCamera, .builtInMicrophone]
//            }
//            let session = AVCaptureDevice.DiscoverySession(deviceTypes: supportedDeviceTypes!, mediaType: AVMediaType.video, position: .unspecified)
//            let cameras = session.devices.compactMap({ $0 })
            let cameras = discoverySession.devices.compactMap({ $0 })
            guard cameras.count != 0, !cameras.isEmpty else {
                throw CameraServiceError.noCamerasAvailable
            }
            
            for camera in cameras {
                if camera.position == .back {
                    self.rearCamera = camera
                }else if camera.position == .front {
                    self.frontCamera = camera
                }
            }
            if isFrontCamera{
                currentCamera = self.frontCamera
            }else{
                currentCamera = self.rearCamera
            }
            delegate?.onChangeZoomFactor(getMinimumZoomFactor())
//            changeAutoFocus()
            changeAutoExposure()
        }
        
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraServiceError.captureSessionIsMissing }

            if let currentCamera = self.currentCamera {
                self.currentCameraInput = try AVCaptureDeviceInput(device: currentCamera)
                
                if captureSession.canAddInput(self.currentCameraInput!) { captureSession.addInput(self.currentCameraInput!) }
                
            } else { throw CameraServiceError.noCamerasAvailable }
        }
        
        func configureAudioCaptureDevice() throws {
            
            guard let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: AVMediaType.audio, position: .unspecified) else {
                throw CameraServiceError.noCamerasAvailable
            }
            
            let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice )
            
            guard let captureSession = self.captureSession else { throw CameraServiceError.captureSessionIsMissing }
            
            if captureSession.canAddInput(audioDeviceInput!) {
                captureSession.addInput(audioDeviceInput!)
            }
        }
        
//        func configureMovieOutput() throws {
//
//            guard let captureSession = self.captureSession else { throw CameraServiceError.captureSessionIsMissing }
//
//            self.movieFileOutput = AVCaptureMovieFileOutput()
//
//            if captureSession.canAddOutput(self.movieFileOutput!) {
//                captureSession.addOutput(self.movieFileOutput!)
//
//                let connection = self.movieFileOutput?.connection(with: AVMediaType.video )
//
//                if ( connection?.isVideoStabilizationSupported )! {
//                    if #available(iOS 13.0, *) {
//                        connection?.preferredVideoStabilizationMode = .cinematic
//                    } else {
//                        connection?.preferredVideoStabilizationMode = .auto
//                    }
//                }
//                captureSession.commitConfiguration()
//            }
//        }
        
        func configureMovieOutput() throws {
            guard let captureSession = self.captureSession else { throw CameraServiceError.captureSessionIsMissing }
            
            self.movieFileOutput = AVCaptureMovieFileOutput()
            
            if captureSession.canAddOutput(self.movieFileOutput!) {
                captureSession.addOutput(self.movieFileOutput!)
                
                if let connection = self.movieFileOutput?.connection(with: AVMediaType.video) {
                    if connection.isVideoStabilizationSupported {
                        if let device = AVCaptureDevice.default(for: .video) {
                            if device.isSmoothAutoFocusSupported {
                                try device.lockForConfiguration()
                                device.isSmoothAutoFocusEnabled = true
                                device.unlockForConfiguration()
                            }
                        }
                        
                        if #available(iOS 14.0, *) {
                            if currentCamera!.isLowLightBoostSupported {
                                try currentCamera?.lockForConfiguration()
                                currentCamera?.automaticallyEnablesLowLightBoostWhenAvailable = true
                                currentCamera?.unlockForConfiguration()
                            }
                        }
                        
                        if connection.isVideoStabilizationEnabled {
                            if #available(iOS 13.0, *) {
                                connection.preferredVideoStabilizationMode = .cinematic
                            } else {
                                connection.preferredVideoStabilizationMode = .auto
                            }
                        }
                    }
                }
                
                captureSession.commitConfiguration()
            }
        }

        
        func configurePhotoOutput() throws {
            guard let captureSession = self.captureSession else { throw CameraServiceError.captureSessionIsMissing }
            
            self.photoOutput = AVCapturePhotoOutput()
            if #available(iOS 11.0, *) {
                self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
              
            } else {
                // Fallback on earlier versions
            }
            if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) }
            captureSession.startRunning()
        }
        
        func setAudioSession() throws {
            let sampleRate:Double = 48_000 // or 44_100
            
              
            // //try audioSession.setCategory(.multiRoute, mode: .default, options: [.defaultToSpeaker, .duckOthers])
                
                let audioSession = AVAudioSession.sharedInstance()
                
                do {
                    
                    try audioSession.setActive(false)
                    try AVAudioSession.sharedInstance().setPreferredSampleRate(sampleRate)
    //                try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
    //                                             mode: AVAudioSession.Mode.default,
    //                                             options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay, .mixWithOthers]) //.mixWithOthers, .defaultToSpeaker,
//                    try  audioSession.setCategory(.playAndRecord, options: [.allowBluetooth])
                    try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
    // audioSession.setCategory(.playAndRecord, mode: .moviePlayback, options: [.allowBluetooth])
                    try audioSession.setActive(true)
                } catch {
                    print("Can't Start Audio Session: \(error)")
                    throw CameraServiceError.cannotSetAudioSession
                }
            }
        /*
        func setAudioSession() throws {
            
            let session = AVAudioSession.sharedInstance()

            do {
                // https://stackoverflow.com/questions/51010390/avaudiosession-setcategory-swift-4-2-ios-12-play-sound-on-silent
                if #available(iOS 10.0, *) {
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                } else {
                    session.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: AVAudioSession.Category.playAndRecord, with: [
                        AVAudioSession.CategoryOptions.allowBluetooth,
                        AVAudioSession.CategoryOptions.defaultToSpeaker]
                    )
                    try session.setMode(.default)
                }
                try session.setActive(true)
            } catch {
                print(error)
            }
         
        
        */
        self.sessionQueue = DispatchQueue(label: "PrepareForCamera")
        self.sessionQueue.async {
            do {
                self.backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                createCaptureSession()
                try configureCaptureDevices()
                if self.checkMicAvailable() {
                    try setAudioSession()
                    try configureAudioCaptureDevice() }
                try configureDeviceInputs()
                try configureMovieOutput()
                try configurePhotoOutput()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func checkIfConnectedWithHeadset() -> Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        for description in route.outputs {
            if description.portType == AVAudioSession.Port.bluetoothA2DP || description.portType == AVAudioSession.Port.headphones {
                return true
            }
        }
        return false
    }
    
    func checkMicAvailable() -> Bool {
        if AVCaptureDevice.default(.builtInMicrophone, for: AVMediaType.audio, position: .unspecified) == nil {
            return false
        } else {
            return true
        }
    }
    
    func removeAddedInputs(){
        for lastInputs in (self.captureSession?.inputs)!{
            self.captureSession?.removeInput(lastInputs)
        }
        self.captureSession = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }catch{
            print(error)
        }
    }
    
    func displayPreview() throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraServiceError.captureSessionIsMissing }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = .resizeAspect

        
        let rootLayer = preview?.layer
        rootLayer?.masksToBounds = true
        previewLayer?.frame = rootLayer?.bounds ?? CGRect.zero
        rootLayer?.addSublayer(previewLayer!)
        updatePreviewOrientation()
        
        
    }
    
    func updatePreviewOrientation(){
        DispatchQueue.main.async {
            let orientation: AVCaptureVideoOrientation?
            switch UIApplication.shared.statusBarOrientation
            {
            case .landscapeLeft:
                orientation = .landscapeLeft
            case .landscapeRight:
                orientation = .landscapeRight
            case .portrait:
                orientation = .portrait
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
            case .unknown:
                orientation = nil
            @unknown default:
                orientation = nil
            }
            
            if let orientation = orientation {
                self.previewLayer?.connection?.videoOrientation = orientation
            }
            
        }
    }
    
    func changeAutoFocus() {
        if (currentCamera!.position == .back){
            ((try? currentCamera?.lockForConfiguration()) as ()??)
            if autoFocus {
                currentCamera?.focusMode = .continuousAutoFocus
                currentCamera?.exposureMode = .continuousAutoExposure
            } else {
                currentCamera?.focusMode = .locked
                currentCamera?.exposureMode = .locked
            }
            currentCamera?.unlockForConfiguration()
        }
    }
     
    func changeAutoExposure() {
        if (currentCamera!.position == .back) {
            ((try? currentCamera?.lockForConfiguration()) as ()??)
            if autoExposure {
//                currentCamera?.isSubjectAreaChangeMonitoringEnabled = true
                currentCamera?.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                currentCamera?.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            } else {
//                currentCamera?.isSubjectAreaChangeMonitoringEnabled = true
                currentCamera?.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                currentCamera?.exposureMode = AVCaptureDevice.ExposureMode.locked
            }
            currentCamera?.unlockForConfiguration()
        }
    }
    
    func changefps(fps : Int) {

             if let dv = currentCamera {
                 // configure
                 do {
                     try dv.lockForConfiguration()
                  
                     dv.activeVideoMinFrameDuration = CMTimeMake(value: 100, timescale: Int32(100 * fps))
                     dv.activeVideoMaxFrameDuration = CMTimeMake(value: 100, timescale: Int32(100 * fps))
//                     CMTimeMake(value: 1, timescale: Int32(fps))
                     try dv.unlockForConfiguration()
                 } catch _ {
                     print("failed locking device")
                 }
             }
    }
    
    func updateDeviceSettings(focusValue : Float, isoValue : Float) {
        if let device = currentCamera {
            do {
                try currentCamera!.lockForConfiguration()
            } catch{
                print(error)
            }
            
            device.setFocusModeLocked(lensPosition: focusValue, completionHandler: { (time) -> Void in
                //
            })
            
            // Adjust the iso to clamp between minIso and maxIso based on the active format
            let minISO = device.activeFormat.minISO
            let maxISO = device.activeFormat.maxISO
            let clampedISO = isoValue * (maxISO - minISO) + minISO
            
            device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: clampedISO) { (time) in
                
            }
            device.unlockForConfiguration()
        }
    }
    
    func focusAndExposeTap(gestureRecognizer: UIGestureRecognizer) {
        
        let pt = gestureRecognizer.location(in: gestureRecognizer.view)
        let size = UIScreen.main.bounds.size
        let width = size.width
        let height = size.height
        let deltaX = width * 120.0 / 1024.0
        let deltaY = height * 98.0 / 768.0
        
        if pt.x > deltaX && pt.x < (width - 2 * deltaX) && pt.y > deltaY && pt.y < (height - 2 * deltaY) {
            let devicePoint = previewLayer?.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
            focusWithMode(focusMode: AVCaptureDevice.FocusMode.autoFocus, exposeWithMode: AVCaptureDevice.ExposureMode.continuousAutoExposure, atDevicePoint: devicePoint!, monitorSubjectAreaChange: true)
        }
    }
    
    func subjectAreaDidChange(notification: NSNotification) {
        if(autoFocus){
            let devicePoint = CGPoint(x: 0.5, y: 0.5)
        self.focusWithMode(focusMode: AVCaptureDevice.FocusMode.continuousAutoFocus, exposeWithMode: AVCaptureDevice.ExposureMode.continuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: false)
        }
    }
    
    func pinchToZoom(_ pinchRecognizer: UIPinchGestureRecognizer, _ pinchVelocityDividerFactor: Float) {
        do {
            try currentCamera?.lockForConfiguration()
            guard self.currentCamera == nil else {
                let vZoomFactor = currentCamera?.videoZoomFactor
                if(vZoomFactor! <= currentCamera!.activeFormat.videoMaxZoomFactor){
                    let desiredZoomFactor = Float(vZoomFactor!) + atan2f(Float(pinchRecognizer.velocity), pinchVelocityDividerFactor)
                    
                    let zoom = max(Float(getMinimumZoomFactor()!), min(desiredZoomFactor, Float((currentCamera?.activeFormat.videoMaxZoomFactor)!)))
                    if(zoom <= 10){                                                
                        currentCamera?.videoZoomFactor = CGFloat(zoom)
                        delegate?.onChangeZoomFactor(currentCamera?.videoZoomFactor)
                    }
                } else{ print("Unable to set videoZoom: (max \(currentCamera!.activeFormat.videoMaxZoomFactor), asked \(vZoomFactor!)") }
                currentCamera?.unlockForConfiguration()
                return
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getMinimumZoomFactor()->CGFloat? {
        var minimumZoom : CGFloat?
        if #available(iOS 11.0, *) {
            minimumZoom = currentCamera?.minAvailableVideoZoomFactor
        }
        return minimumZoom
    }
    
    func focusWithMode(focusMode: AVCaptureDevice.FocusMode, exposeWithMode exposureMode: AVCaptureDevice.ExposureMode, atDevicePoint point:CGPoint, monitorSubjectAreaChange: Bool)  {
        self.sessionQueue.async {
            let device  = self.currentCameraInput!.device
            if device.position == .back{
                try! device.lockForConfiguration()
                
                //device.autoFocusRangeRestriction = .far
                if ( device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) ) {
                    device.focusMode = focusMode
                    device.focusPointOfInterest = point
                }
                if ( device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) ) {
                    device.exposureMode = exposureMode
                    device.exposurePointOfInterest = point
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            }
        }
    }
    
    func startRecording(_ outputURL: URL) {
        sessionQueue.async {
            if ( UIDevice.current.isMultitaskingSupported ) {
                self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            self.movieFileOutput?.movieFragmentInterval = CMTime.invalid
            self.movieFileOutput?.connection(with: AVMediaType.video)?.videoOrientation = (self.previewLayer?.connection?.videoOrientation)!
            self.movieFileOutput?.startRecording(to: outputURL, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
        }
    }
    
    func stopRecording() {
        movieFileOutput?.stopRecording()
    }
    
    private func endBackgroundRecording() {
         if backgroundRecordingID != .invalid {
             UIApplication.shared.endBackgroundTask(backgroundRecordingID)
             backgroundRecordingID = .invalid
         }
     }
}

//MARK: - AVCaptureFileOutputRecordingDelegate
extension CameraService : AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
                   
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.setTimer(timer:)), userInfo: nil, repeats: true )
            delegate?.cameraService(output, didStartRecordingTo: fileURL, from: connections)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let selfTimer = timer {
            selfTimer.invalidate()
            timer = nil
        }
        
        delegate?.cameraService(output, didFinishRecordingTo: outputFileURL, from: connections, error: error)
        endBackgroundRecording()
    }
}

//MARK: - Other Functions
extension CameraService {
    @objc private func setTimer( timer : Timer) {
        let duration = CMTimeGetSeconds(movieFileOutput?.recordedDuration ?? CMTime.zero)
        delegate?.onRecordingAMinute(movieFileOutput?.recordedDuration ?? CMTime.zero)
        let timeNow = String( format :"%02d:%02d:%02d", Int(duration)/3600, (Int(duration)%3600)/60, Int(duration)%60)
        
        self.timeLbl.text = timeNow
        
        if isReachedLimitation() {
            movieFileOutput?.stopRecording()
        }
    }
    
    func isReachedLimitation(_ limitDuration: Float64? = nil, _ currentAllTime: Float64? = nil) -> Bool {
        let storageLimited = Utiles.battery() < 7 && Utiles.batteryStatus() != 2
        return storageLimited
    }
    
    var currentRecordedTime : CMTime {
        return movieFileOutput?.recordedDuration ?? CMTime.zero
    }
}

extension CameraService {
    enum CameraServiceError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case cannotSetAudioSession
        case unknown
    }
}
