//
//  FanGenerationVideoView.swift
//  NewFannerCam
//
//  Created by Jin on 1/21/19.
//  Copyright © 2019 fannercam3. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import ReplayKit

enum FanGenMode {
    case record
    case importVideo
    case video
    case mainVideo
}

enum PickerMode {
    case timer
    case point
}

protocol FanGenerationVideoDataSource: AnyObject {
    func fanGenerationVideoMode() -> FanGenMode
    func fanGenScoreValue(_ fanGenerationVideo: FanGenerationVideo, _ team: Team) -> Int?
    
    func numberOfTags(in fanGenerationVideo: FanGenerationVideo) -> Int
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, tagCellAt index: Int) -> Marker
}

protocol FanGenerationVideoDelegate: AnyObject {
    func didTapMarker(_ markerView: MarkersView, _ marker: UIButton, _ type: FanGenMarker, _ team: Team, _ countPressed: Int)
    func didTapMarker(_ type: FanGenMarker, _ team: Team, _ countPressed: Int)
    func didTapGoal(_ fanGenerationVideo: FanGenerationVideo, goals value: String, team: Team)
    func undoScore(_ fanGenVideo: FanGenerationVideo, team: Team)
    func didTapScoreboard(_ fanGenerationVideo: FanGenerationVideo)
    func didSaveScoreboardSetting(_ period: String?, _ point1: String?, _ point2: String?, _ point3: String?)
    func didSaveScoreboardSwitch(_ switchScoreboard: Bool?)
//    func didSaveTimerSwitch(_ switchScoreboard: Bool?)
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didSelectTagAt index: Int, _ type: FanGenMarker, _ countPressed: Int)
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, heightForTagViewAt index: Int) -> CGFloat
    func fanGenerationVideo(_ fanGenerationVideo: FanGenerationVideo, didClickedTagSave button: UIButton, tagNum value: String, countPressed: Int)
    
    //savetime-countdown
    func didSaveTimerAndCountdownTime(_ timerTimer: String?, _ countdownTime: String?, _ isTimeFromTimer : Bool?)
}

extension Data {
    func object<T>() -> T { withUnsafeBytes{$0.load(as: T.self)} }
    var color: UIColor { .init(data: self) }
}

extension Numeric {
    var data: Data {
        var bytes = self
        return Data(bytes: &bytes, count: MemoryLayout<Self>.size)
    }
}


extension UIColor {
    convenience init(data: Data) {
        let size = MemoryLayout<CGFloat>.size
        self.init(red:   data.subdata(in: size*0..<size*1).object(),
                  green: data.subdata(in: size*1..<size*2).object(),
                  blue:  data.subdata(in: size*2..<size*3).object(),
                  alpha: data.subdata(in: size*3..<size*4).object())
    }
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        return getRed(&red, green: &green, blue: &blue, alpha: &alpha) ?
        (red, green, blue, alpha) : nil
    }
    var data: Data? {
        guard let rgba = rgba else { return nil }
        return rgba.red.data + rgba.green.data + rgba.blue.data + rgba.alpha.data
    }
}

extension UserDefaults {
    func set(_ color: UIColor?, forKey defaultName: String) {
        guard let data = color?.data else {
            removeObject(forKey: defaultName)
            return
        }
        set(data, forKey: defaultName)
    }
    func color(forKey defaultName: String) -> UIColor? {
        data(forKey: defaultName)?.color
    }
}
extension UserDefaults {
    var backgroundColorTeam1: UIColor? {
        get { color(forKey: "backgroundColorTeam1") }
        set { set(newValue, forKey: "backgroundColorTeam1") }
    }
    
    var backgroundColorTeam2: UIColor? {
        get { color(forKey: "backgroundColorTeam2") }
        set { set(newValue, forKey: "backgroundColorTeam2") }
    }
    
}
class FanGenerationVideo: UIView, UITextFieldDelegate  ,  UIPickerViewDataSource, UIPickerViewDelegate {
    
//    var isCountdownClick : Bool = false
    var isTimeAnyChange : Bool = false
    var selectedMinutes = 0
    var selectedSeconds = 0
    var selectedpoint = 0
    var currentPickerMode: PickerMode = .timer
    var activeTextField: UITextField?
    var selectedValuesOLD: [Int: Int] = [:]
    
    var selectedMinutesCountDown = 0
    var selectedSecondsCountDown = 0
    
    var oldValueP1 : Int = 0
    var oldValueP2 : Int = 0
    var oldValueP3 : Int = 0
    
    @IBOutlet weak var pointSpinnerView: UIPickerView!
    
    
    var isScoreboardStatus : Bool = false
    var isTimerStatus : Bool = false
    var isHomeColorChanged : Bool = false
    var isAwayColorChanged : Bool = false
    var isSwitchScoreboardPosition : Bool = true
    var isSwitchColorPosition : Bool = true
    var isSwitchTimerPosition : Bool = true
    var saveColorTeame1 : UIColor!
    var saveColorTeame2 : UIColor!
    
    @IBOutlet weak var point3View: UIView!
    @IBOutlet weak var point2View: UIView!
    @IBOutlet weak var point1View: UIView!
//    @IBOutlet weak var pointPicker: UIPickerView!
    @IBOutlet weak var setTimerView: UIView!
    class func instanceFromNib(_ frame: CGRect) -> FanGenerationVideo {
        let selfView = UINib(nibName: FanGenId.faGenerationVideo, bundle: nil).instantiate(withOwner: self, options: nil)[0] as! FanGenerationVideo
        selfView.frame = frame
        return selfView
    }
    
    func loadView() -> UIView {
        let selfView = UINib(nibName: FanGenId.faGenerationVideo, bundle: nil).instantiate(withOwner: self, options: nil)[0] as! UIView
        return selfView
    }

    var ischanged : Bool = false
    @IBAction func homeColorSelector(_ sender: UIButton) {
        mainColorPickerView.isHidden = false
        mainColorPickerView.backgroundColor = .clear
        colourPicker.isHidden = false
        colourPicker.setViewColor(selectedColor)
        teame1ColorOLD = selectedColor
        closeBtnColor.isHidden = false
        awayCloseBtn.isHidden = true
        
        colourPicker.selectedColorView.backgroundColor = UserDefaults.standard.backgroundColorTeam1
 
    }
//
//     func numberOfComponents(in pickerView: UIPickerView) -> Int {
//         return 2 // Minutes and Seconds
//     }
//
//     func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//         if component == 0 {
//             return 1000 // 0 to 999 minutes
//         } else {
//             return 61 // 0 to 60 seconds
//         }
//     }
//
//     // MARK: - UIPickerViewDelegate Methods
//
//     func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//         if component == 0 {
//             return "\(row) min"
//         } else {
//             return "\(row) sec"
//         }
//     }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        activeTextField = textField
        
        // Here, you set the currentPickerMode based on the selected text field
        if textField == minuteTF || textField == secondsTF || textField == countdownMinuteTF || textField == countdownSecondsTF {
            currentPickerMode = .timer
            reloadTimePickerView()
            
        } else if textField == point1TF || textField == point2TF || textField == point3TF {
            currentPickerMode = .point
            reloadPointPickerView()
        }
//        reloadTimePickerView()
    }
    
    
    func reloadTimePickerView() {
        timerSpinnerView.dataSource = self // Set your data source object
        timerSpinnerView.delegate = self // Set your delegate object

        // Reload the UIPickerView data (you may need to adjust this based on your specific implementation)
        timerSpinnerView.reloadAllComponents()
    }
    func reloadPointPickerView() {
        pointSpinnerView.dataSource = self // Set your data source object
        pointSpinnerView.delegate = self // Set your delegate object

        // Reload the UIPickerView data (you may need to adjust this based on your specific implementation)
        pointSpinnerView.reloadAllComponents()
    }

    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch currentPickerMode {
        case .point:
            return 1
        case .timer:
            return 2 // Return 2 components for timer mode
 
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch currentPickerMode {
        case .timer:
            return component == 0 ? 1000 : 61
        case .point:
            return 100
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch currentPickerMode {
        case .timer:
            if component == 0 {
                return "\(row) min"
            } else {
                return "\(row) sec"
            }
        case .point:
            return "\(row) min"
        }
    }

     
     func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
         
         
         switch currentPickerMode {
         case .timer:
         
             
             if component == 0 {
                 selectedMinutes = row
                
             } else {
                 selectedSeconds = row
             }
             
       
             if isCountdown {
                 
                 let formattedTime = String(format: "%03d:%02d", selectedMinutes, selectedSeconds)
    //             lblTimer.text = formattedTime

                 // Separate minutes and seconds
                 let components = formattedTime.split(separator: ":")
                 if components.count == 2 {
                     if let minutesInt = Int(components[0]), let secondsInt = Int(components[1]) {
                         let minutes = String(minutesInt)
                         let seconds = String(secondsInt)

                         self.countdownMinuteTF.text = minutes
                         self.countdownSecondsTF.text = seconds
                         
                         
                         // Now you have 'minutes' and 'seconds' as strings without leading zeros.
                         print("Minutes: \(minutes), Seconds: \(seconds)")
                         
                         self.selectedMinutesCountDown = Int(minutes)!
                         self.selectedSecondsCountDown = Int(seconds)!
                     }
                 }


                 totalCountdownMinutes = (countdownMinuteTF.text! as NSString).integerValue
                 if countdownSecondsTF.text != nil && countdownSecondsTF.text != "" {
                     totalCountdownSeconds = (countdownSecondsTF.text! as NSString).integerValue
                 }
                 countdownValue = (totalCountdownMinutes * 60) + totalCountdownSeconds
                 appDelegate.isTimeFromCountdown = true

                 NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)

                 totalCountdownSeconds = (countdownSecondsTF.text! as NSString).integerValue
                 if countdownMinuteTF.text != nil && countdownMinuteTF.text != "" {
                     totalCountdownMinutes = (countdownMinuteTF.text! as NSString).integerValue
                 }
                 countdownValue = (totalCountdownMinutes * 60) + totalCountdownSeconds
                 appDelegate.isTimeFromCountdown = true
                 NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)


             }else {
                 
                 let formattedTime = String(format: "%03d:%02d", selectedMinutes, selectedSeconds)
    //             lblTimer.text = formattedTime
                 
                 // Separate minutes and seconds
                 let components = formattedTime.split(separator: ":")
                 if components.count == 2 {
                     if let minutesInt = Int(components[0]), let secondsInt = Int(components[1]) {
                         let minutes = String(minutesInt)
                         let seconds = String(secondsInt)
                         
                         self.minuteTF.text = minutes
                         self.secondsTF.text = seconds
                         // Now you have 'minutes' and 'seconds' as strings without leading zeros.
                         self.selectedMinutes = Int(minutes)!
                         self.selectedSeconds = Int(seconds)!
                         print("Minutes: \(minutes), Seconds: \(seconds)")
                     }
                 }
                 
                 
                
                 
                 isTextfieldEdited = true
                 
                 totalTimerMinutes = (minuteTF.text! as NSString).integerValue
                 if secondsTF.text != nil && secondsTF.text != "" {
                     totalTimerSeconds = (secondsTF.text! as NSString).integerValue
                 }
                 
                 totalSecond = (totalTimerMinutes * 60) + totalTimerSeconds
                 appDelegate.isTimeFromCountdown = false
                 NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
                 
                 
                 isTextfieldEdited = true
                 totalTimerSeconds = (secondsTF.text! as NSString).integerValue
                 if minuteTF.text != nil && minuteTF.text != "" {
                     totalTimerMinutes = (minuteTF.text! as NSString).integerValue
                 }
                 
                 totalSecond = (totalTimerMinutes * 60) + totalTimerSeconds
                 appDelegate.isTimeFromCountdown = false
                 
                 NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
                 
                 
             }
             
         case .point:
             
//             self.pointPicker.isHidden = true
             
             guard let activeTextField = activeTextField else {
                  return // No active text field to associate with the picker view
              }
             
             if component == 0 {
                 selectedpoint = row
             }
             
             
             
             // Check the activeTextField to determine which UITextField's data is being selected
             if activeTextField == point1TF {
                 
                 self.oldValueP1 = selectedpoint
                 // Handle the selection for point1TF
//                 guard ValidationService.validateNumSize(compareVal:  point1TF.text!, vVal: 15) else {
//                     MessageBarService.shared.warning("The 1st score point should be less than 15.")
//                     return
//                 }
                 self.point1TF.text = "\(selectedpoint)"
               
                 sfcoreBtn.setTitle(point1TF.text, for: .normal)
                 ffscoreBtn.setTitle(point1TF.text, for: .normal)
                 
             } else if activeTextField == point2TF {
                 self.oldValueP2 = selectedpoint
                 // Handle the selection for point2TF
//                 guard ValidationService.validateNumSize(compareVal: point2TF.text!, vVal: 30) else {
//                     MessageBarService.shared.warning("The 2nd score point should be less than 30.")
//                     return
//                 }
                 self.point2TF.text = "\(selectedpoint)"
                 ssscoreBtn.setTitle(point2TF.text, for: .normal)
                 fsscoreBtn.setTitle(point2TF.text, for: .normal)
             } else if activeTextField == point3TF {
                 self.oldValueP3 = selectedpoint
                 // Handle the selection for point3TF
//                 guard ValidationService.validateNumSize(compareVal: point3TF.text!, vVal: 45) else {
//                     MessageBarService.shared.warning("The 3rd score point should be less than 45.")
//                     return
//                 }
                 self.point3TF.text = "\(selectedpoint)"
                 stscoreBtn.setTitle(point3TF.text, for: .normal)
                 ftscoreBtn.setTitle(point3TF.text, for: .normal)
             } else {
                 // Handle the selection for other text fields (if needed)
             }
             point1TF.resignFirstResponder()
         }
       
         
         DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
             self.setTimerView.isHidden = true
         
             
             self.point1View.isHidden = false
             self.point2View.isHidden = false
             self.point3View.isHidden = false
             
             self.topScoreboardView.isUserInteractionEnabled = true
          
             self.topScoreboardView.alpha = 1.0
             self.colourPickerView.alpha = 1.0
             self.viewMainTimer.alpha = 1.0
             self.scorePointView.alpha = 1.0

             self.colourPickerView.isUserInteractionEnabled = true
             self.viewMainTimer.isUserInteractionEnabled = true
             self.scorePointView.isUserInteractionEnabled = true
     
         }
     }
     
    @IBAction func saveScoreboardData(_ sender: UIButton) {
        
        scoreboardSettingView.isHidden = true
        
        let point1 = point1TF.text!
        let point2 = point2TF.text!
        let point3 = point3TF.text!
        let period = periodTF.text!
        
        let checkedStrs = [
            point1, point2, point3, period
        ]
        
        guard ValidationService.validateEmptyStrs(checkedStrs) else {
            MessageBarService.shared.warning("Input all setting information!")
            return
        }
        guard ValidationService.validateStringLength(str: period, lengCount: 4) else {
            MessageBarService.shared.warning("Period text length should be less than 4.")
            return
        }
        guard ValidationService.validateNumSize(compareVal: point1, vVal: 15) else {
            MessageBarService.shared.warning("The 1st score point should be less than 15.")
            return
        }
        guard ValidationService.validateNumSize(compareVal: point2, vVal: 30) else {
            MessageBarService.shared.warning("The 2nd score point should be less than 30.")
            return
        }
        guard ValidationService.validateNumSize(compareVal: point3, vVal: 45) else {
            MessageBarService.shared.warning("The 3rd score point should be less than 45.")
            return
        }

        
        
        saveColorTeame1 = UserDefaults.standard.backgroundColorTeam1
        saveColorTeame2 = UserDefaults.standard.backgroundColorTeam2
        
        delegate?.didSaveScoreboardSetting(period, point1, point2, point3)

        isTimerStatus = false

    }
    // MARK: - IBAction
    
    @IBAction func awayColorSelector(_ sender: UIButton) {
        mainColorPickerView.isHidden = false
        mainColorPickerView.backgroundColor = .clear
        colourPicker.isHidden = false
        colourPicker.setViewColor(selectedColor)
        closeBtnColor.isHidden = true
        awayCloseBtn.isHidden = false
        teame2ColorOLD = selectedColor

        colourPicker.selectedColorView.backgroundColor = UserDefaults.standard.backgroundColorTeam2
 
    }
    
    @IBOutlet weak var awayColorView: UIView!
    @IBOutlet weak var homeColorView: UIView!
    @IBOutlet weak var awayCloseBtn: UIButton!
    
    @IBAction func closeBtn(_ sender: Any) {
        colourPicker.isHidden = true
        mainColorPickerView.isHidden = true
        
        // Save the old color in case it needs to be restored
        let oldColor = viewTeam1.backgroundColor
        
        viewTeam1.backgroundColor = colourPicker.selectedColorView.backgroundColor
        homeColorView.backgroundColor = colourPicker.selectedColorView.backgroundColor
        
        print(colourPicker.selectedColorView.backgroundColor)
        
        if let backgroundColor = viewTeam1.backgroundColor {
            if backgroundColor.isEqual(teame1ColorOLD) {
                // No crash, and you can access backgroundColor safely
                self.isHomeColorChanged = false
            } else {
                MessageBarService.shared.notify("Home Team Color changed successfully")
                self.isHomeColorChanged = true
            }
        } else {
            // Handle the case where backgroundColor is nil
            // You can set a default value for isHomeColorChanged or handle it accordingly
            // For example: self.isHomeColorChanged = false
            
            // Set the background color to the old color
            viewTeam1.backgroundColor = oldColor
        }
        
        UserDefaults.standard.backgroundColorTeam1 = colourPicker.selectedColorView.backgroundColor

        saveColorTeame1 = UserDefaults.standard.backgroundColorTeam1
        saveColorTeame2 = UserDefaults.standard.backgroundColorTeam2
    }

    
    
    @IBAction func closeBtnAway(_ sender: UIButton) {
            colourPicker.isHidden = true
            mainColorPickerView.isHidden = true
            
            // Save the old color in case it needs to be restored
            let oldColor = viewTeam2.backgroundColor
            
            viewTeam2.backgroundColor = colourPicker.selectedColorView.backgroundColor
            awayColorView.backgroundColor = colourPicker.selectedColorView.backgroundColor
            
            if let backgroundColor = viewTeam2.backgroundColor {
                if backgroundColor.isEqual(teame2ColorOLD) {
                    // No crash, and you can access backgroundColor safely
                    self.isAwayColorChanged = false
                } else {
                    MessageBarService.shared.notify("Away Team Color changed successfully")
                    self.isAwayColorChanged = true
                }
            } else {
                // Handle the case where backgroundColor is nil
                // You can set a default value for isAwayColorChanged or handle it accordingly
                // For example: self.isAwayColorChanged = false
                
                // Set the background color to the old color
                viewTeam2.backgroundColor = oldColor
            }
            
            UserDefaults.standard.backgroundColorTeam2 = colourPicker.selectedColorView.backgroundColor
            
            saveColorTeame1 = UserDefaults.standard.backgroundColorTeam1
            saveColorTeame2 = UserDefaults.standard.backgroundColorTeam2
        }


    
    @IBOutlet weak var internalStackScorboardView: UIStackView!
    @IBOutlet weak var topScoreboardView: UIView!
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var isstremingPage : Bool = false
    @IBOutlet weak var scoreShowView: UIView!
    @IBOutlet weak var scoreView: UIStackView!
    var player: AVPlayer?
    var avpController = AVPlayerViewController()
    var selectedColor: UIColor = UIColor.white
    
    @IBOutlet weak var flipTimerCountdown: UIView!
    
    @IBOutlet weak var closeBtnColor: UIButton!
    @IBOutlet weak var team1BG: UIView!
    @IBOutlet weak var team2BG: UIView!
 
    @IBOutlet weak var switchTeamColor: UISwitch!
    @IBOutlet weak var viewTeam1: UIView!
    @IBOutlet weak var viewTeam2: UIView!
    @IBOutlet weak var viewTimeSB: UIView!
    @IBOutlet weak var viewPeriodSB: UIView!
    @IBOutlet weak var scoreboardDismissBtn: UIButton!
    @IBOutlet weak var startBtn                     : UIButton!
    @IBOutlet weak var periodView                   : UIView!
    @IBOutlet weak var timerLineView                : UIView!
    @IBOutlet weak var internalStackView            : UIStackView!
    @IBOutlet weak var countdownView                : UIView!
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var topScoreView: UIView!
    //MARK: - IBOutlets
    @IBOutlet weak var middleView                   : UIView!
    @IBOutlet weak var gridView                     : UIView!
    @IBOutlet weak var mainColorPickerView: UIView!
    
    // score points views
    @IBOutlet weak var ffscoreBtn                   : UIButton!
    @IBOutlet weak var fsscoreBtn                   : UIButton!
    @IBOutlet weak var ftscoreBtn                   : UIButton!
    @IBOutlet weak var fScoreUndoBtn                : UIButton!
    
    @IBOutlet weak var ffscoreView                   : UIView!
    @IBOutlet weak var fsscoreView                   : UIView!
    @IBOutlet weak var ftscoreView                   : UIView!
    
    @IBOutlet weak var sfscoreView                   : UIView!
    @IBOutlet weak var ssscoreView                   : UIView!
    @IBOutlet weak var stscoreView                   : UIView!
    
    @IBOutlet weak var sfcoreBtn                    : UIButton!
    @IBOutlet weak var ssscoreBtn                   : UIButton!
    @IBOutlet weak var stscoreBtn                   : UIButton!
    @IBOutlet weak var sScoreUndoBtn                : UIButton!
    
    @IBOutlet weak var colourPicker: SwiftHSVColorPicker!
    //score board
    @IBOutlet weak var fGoalsLbl                    : UILabel!
    @IBOutlet weak var fPeriodLbl                   : UILabel!
    @IBOutlet weak var fTeamNameLbl                 : UILabel!
    
    @IBOutlet weak var sGoalsLbl                    : UILabel!
    @IBOutlet weak var sTeamNameLbl                 : UILabel!
    @IBOutlet weak var timeMatchLbl                 : UILabel!
    
    @IBOutlet weak var timerSpinnerView: UIPickerView!
    // scoreboard setting view
    @IBOutlet weak var scoreboardSettingView        : UIView!
    @IBOutlet weak var periodTF                     : UITextField!
    @IBOutlet weak var scoreTF1                     : UITextField!
    @IBOutlet weak var scoreTF2                     : UITextField!
    @IBOutlet weak var scoreTF3                     : UITextField!
    
    //constraints
    @IBOutlet weak var periodMainView: UIView!
    @IBOutlet weak var scoreBtnsHeight              : NSLayoutConstraint!
//    @IBOutlet weak var scoreboardHeight             : NSLayoutConstraint!
    @IBOutlet weak var timerScoreMainView: UIView!
    
    @IBOutlet weak var timerBGView: UIView!
    //    @IBOutlet weak var lblTimer: UILabel!
    //gesture Views
    @IBOutlet weak var topLeftView                     : UIView!
    @IBOutlet weak var topRightView                    : UIView!
    @IBOutlet weak var bottomLeftView                  : UIView!
    @IBOutlet weak var bottomRightView                 : UIView!
    @IBOutlet weak var bottomCenterView                : UIView!
    @IBOutlet weak var imgViewImageArchive             : UIImageView!
    
    var imageArchiveSelected1 = -1
    var imageArchiveSelected2 = -1
    
    @IBOutlet weak var timerBtn                     : UIButton!
    @IBOutlet weak var countdownBtn                 : UIButton!
    
    @IBOutlet weak var point1TF                     : UITextField!
    @IBOutlet weak var point2TF                     : UITextField!
    @IBOutlet weak var point3TF                     : UITextField!
    @IBOutlet weak var minuteTF                     : UITextField!
    @IBOutlet weak var secondsTF                    : UITextField!
    @IBOutlet weak var countdownMinuteTF            : UITextField!
    @IBOutlet weak var countdownSecondsTF           : UITextField!
    
    @IBOutlet weak var scorePointView               : UIView!
    @IBOutlet weak var colourPickerView             : UIView!
    @IBOutlet weak var timerMainView                : UIView!
    @IBOutlet weak var switchTimer                  : UISwitch!
    @IBOutlet weak var lblScoreboardTitle           : UILabel!
    @IBOutlet weak var switchScoreboard             : UISwitch!
    
    @IBOutlet weak var timerTitleLbl                : UILabel!
    @IBOutlet weak var countdownTitleLbl            : UILabel!
    @IBOutlet weak var countdownLineView            : UIView!
    
    @IBOutlet weak var resetBtn                     : UIButton!

//    @IBOutlet weak var mainPointPickerView: UIView!
    @IBOutlet weak var viewMainTimer: UIView!
//MARK: - properties
    weak var delegate       : FanGenerationVideoDelegate?
    weak var dataSource     : FanGenerationVideoDataSource?
    
    private var genMode             = FanGenMode.record
    let defaults = UserDefaults.standard
    var teame1ColorOLD : UIColor! = UIColor.white
    var teame2ColorOLD : UIColor! = UIColor.white
    
    // sub views
    var markerView          : MarkersView!
    var tagsView            : TagsView!
    
    private var currentCountPressed : Int!
    
    // access properties
    var isDisplayedSubViews : Bool = false
    
    // access properties
    var timer:Timer?

    var isCountdown             : Bool = false
    var isTimerOn               : Bool = false
    var isTextfieldEdited       : Bool = false
    
    var totalSecond             = Int()
    var countdownValue          = Int()
    var totalTimerHour          = Int()
    var totalTimerMinutes       = Int()
    var totalTimerSeconds       = Int()
    var totalCountdownMinutes   = Int()
    var totalCountdownSeconds   = Int()
    var totalTimeInSecondsLimit = Int()
    
    var scoreBoarddata : ScoreboardSetting!
    
    private var fanGenService           : FanGenerationService!
    var selectedMatch                   : SelectedMatch!

    @IBOutlet weak var homeSelectColorBtn: UIButton!
    @IBOutlet weak var awaySelectColorBtn: UIButton!
    
    //MARK: - Override function
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
//MARK: - Main functions
    private func onGoalsBtn(on btn: UIButton, team: Team) {
        let value = btn.titleLabel?.text ?? FanGenTitles.empty.rawValue
        set(goalsLbl: value, team)
        delegate?.didTapGoal(self, goals: value, team: team)
    }
    
    private func set(goalsLbl val: String, _ team: Team) {
        func setGoalData(_ lbl: UILabel) {
            var num = Int(lbl.text!) ?? 0
            num += Int(val) ?? 0
            lbl.text = "\(num)"
        }
        if team == .first {
            setGoalData(fGoalsLbl)
        } else {
            setGoalData(sGoalsLbl)
        }
    }
    
    private func setEnabled(of btn: UIButton, to val: Bool) {
        btn.isEnabled = val
        btn.alpha = val ? 1 : 0.5
    }
    
    @IBAction func switchColorDidChange(_ sender: UISwitch) {
        if switchScoreboard.isOn{
            print("")
            if sender.isOn {
                switchTeamColor.isUserInteractionEnabled = true
                homeSelectColorBtn.isUserInteractionEnabled = true
                awaySelectColorBtn.isUserInteractionEnabled = true
                viewTeam1.isHidden = false
                viewTeam2.isHidden = false
                self.isSwitchColorPosition = true
                
                
//                viewTeam1.backgroundColor = UserDefaults.standard.backgroundColorTeam1
//                viewTeam2.backgroundColor = UserDefaults.standard.backgroundColorTeam2
//                print(UserDefaults.standard.backgroundColorTeam2)
//
                if UserDefaults.standard.backgroundColorTeam1 == nil {
                    viewTeam1.backgroundColor = .systemGreen
                }else {
                    viewTeam1.backgroundColor = UserDefaults.standard.backgroundColorTeam1
                }
                if UserDefaults.standard.backgroundColorTeam2 == nil {
                    viewTeam2.backgroundColor = .systemRed
                }else{
                    viewTeam2.backgroundColor = UserDefaults.standard.backgroundColorTeam2
                }
            }else {
                switchTeamColor.isUserInteractionEnabled = true
                homeSelectColorBtn.isUserInteractionEnabled = false
                awaySelectColorBtn.isUserInteractionEnabled = false
                viewTeam1.isHidden = true
                viewTeam2.isHidden = true
                self.isSwitchColorPosition = false
                print(UserDefaults.standard.backgroundColorTeam1)
            }
        }else {
            switchTeamColor.isUserInteractionEnabled = false
        }
    }
    
//    func uiColorFromHex(rgbValue: Int) -> UIColor {
//
//         let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
//         let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
//         let blue =  CGFloat(rgbValue & 0x0000FF) / 0xFF
//         let alpha = CGFloat(1.0)
//
//         return UIColor(red: red, green: green, blue: blue, alpha: alpha)
//     }

    @IBAction func timerDidChangeSwitcher(_ sender: UISwitch) {
        if switchScoreboard.isOn {
            if sender.isOn {
                switchTimer.isUserInteractionEnabled = true
                viewPeriodSB.backgroundColor = .darkGray
                viewTimeSB.backgroundColor = .darkGray
                fPeriodLbl.isHidden = false
                timeMatchLbl.isHidden = false
                
//                flipTimerCountdown.isUserInteractionEnabled = true
//                timerMainView.isUserInteractionEnabled = true
//                startBtn.isUserInteractionEnabled = true
//                resetBtn.isUserInteractionEnabled = true
//                periodView.isUserInteractionEnabled = true
                timerUI(state: true, alpha: 1.0)
                self.isSwitchTimerPosition = true
            }else {
                switchTimer.isUserInteractionEnabled = true
                viewPeriodSB.backgroundColor = .clear
                viewTimeSB.backgroundColor = .clear
                fPeriodLbl.isHidden = true
                timeMatchLbl.isHidden = true
                
//                flipTimerCountdown.isUserInteractionEnabled = false
//                timerMainView.isUserInteractionEnabled = false
//                startBtn.isUserInteractionEnabled = false
//                resetBtn.isUserInteractionEnabled = false
//                periodView.isUserInteractionEnabled = false
                
                timerUI(state: false, alpha: 0.5)
                
                setStartTextOnButton()
                stopTimer()
                
                self.isSwitchTimerPosition = false
            }
        }else {
            switchTimer.isUserInteractionEnabled = false
        }
    }
    
    func timerUI(state : Bool , alpha : CGFloat){
        flipTimerCountdown.isUserInteractionEnabled = state
        timerMainView.isUserInteractionEnabled = state
        startBtn.isUserInteractionEnabled = state
        resetBtn.isUserInteractionEnabled = state
        periodView.isUserInteractionEnabled = state
        
        flipTimerCountdown.alpha = alpha
        timerMainView.alpha = alpha
        startBtn.alpha = alpha
        resetBtn.alpha = alpha
        periodView.alpha = alpha
        
    }
    
    @IBAction func onScoreboardSwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn
        {
            switchTimer.isUserInteractionEnabled = true
            switchTeamColor.isUserInteractionEnabled = true
            homeSelectColorBtn.isUserInteractionEnabled = true
            awaySelectColorBtn.isUserInteractionEnabled = true
            topScoreView.alpha = 1
            self.enableScoreboardView()
            delegate?.didSaveScoreboardSwitch(true)
            self.isSwitchScoreboardPosition = true
//            fPeriodLbl.isHidden = false
//            timeMatchLbl.isHidden = false
            self.switchTimer.isOn = true
            self.switchTeamColor.isOn = true
            
            viewTeam1.isHidden = false
            viewTeam2.isHidden = false
            self.isSwitchTimerPosition = true
            self.isSwitchColorPosition = true
            
            switchColorDidChange(switchTeamColor)
            timerDidChangeSwitcher(switchTimer)
            scoreShowView.isHidden = false
            topScoreView.isHidden = false
            isScoreboardStatus = true
        } else {
            switchTimer.isUserInteractionEnabled = false
            switchTeamColor.isUserInteractionEnabled = false
            homeSelectColorBtn.isUserInteractionEnabled = false
            awaySelectColorBtn.isUserInteractionEnabled = false
            delegate?.didSaveScoreboardSwitch(false)
            topScoreView.alpha = 0.3
            self.disableScoreboardView()
            resetTimer()
            self.isSwitchScoreboardPosition = false
            self.isSwitchTimerPosition = false
            self.isSwitchColorPosition = false
            
            self.switchTimer.isOn = false
            self.switchTeamColor.isOn = false
            topScoreView.isHidden = true
            scoreShowView.isHidden = true
            isScoreboardStatus = true
        }
    }
}


//MARK: - Access functions
extension FanGenerationVideo {
    
    func setScoreboardUI(withSetting data: ScoreboardSetting, _ period: String?, _ fAbbName: String, _ sAbbName: String) {
        ffscoreBtn.setTitle("\(data.point1)", for: .normal)
        sfcoreBtn.setTitle("\(data.point1)", for: .normal)
        
        fsscoreBtn.setTitle("\(data.point2)", for: .normal)
        ssscoreBtn.setTitle("\(data.point2)", for: .normal)
        
        ftscoreBtn.setTitle("\(data.point3)", for: .normal)
        stscoreBtn.setTitle("\(data.point3)", for: .normal)
        
        if let periodStr = period {
            fPeriodLbl.text = periodStr
        } else {
            fPeriodLbl.text = data.period
        }
        fTeamNameLbl.text = fAbbName
        sTeamNameLbl.text = sAbbName
        
        /*
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(leftTopSingleTap(_:)))
        tap1.numberOfTapsRequired = 1
        tap1.numberOfTouchesRequired = 1
        topLeftView.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(leftTopDoubleTap(_:)))
        tap2.numberOfTapsRequired = 2
        tap2.numberOfTouchesRequired = 1
        topLeftView.addGestureRecognizer(tap2)
        
        tap1.require(toFail: tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(leftTopSingleTapTwoFinger(_:)))
        tap3.numberOfTapsRequired = 1
        tap3.numberOfTouchesRequired = 2
        topLeftView.addGestureRecognizer(tap3)
        
        let tap4 = UISwipeGestureRecognizer(target: self, action: #selector(leftTopSwipeRightToLeft(gesture:)))
        tap4.direction = .left
        topLeftView.addGestureRecognizer(tap4)
        
        let tap5 = UILongPressGestureRecognizer(target: self, action: #selector(leftTopLongPress(_:)))
        tap5.minimumPressDuration = 1
        topLeftView.addGestureRecognizer(tap5)
        
        let tap6 = UITapGestureRecognizer(target: self, action: #selector(rightTopSingleTap(_:)))
        tap6.numberOfTapsRequired = 1
        tap6.numberOfTouchesRequired = 1
        topRightView.addGestureRecognizer(tap6)
        
        let tap7 = UITapGestureRecognizer(target: self, action: #selector(rightTopDoubleTap(_:)))
        tap7.numberOfTapsRequired = 2
        tap7.numberOfTouchesRequired = 1
        topRightView.addGestureRecognizer(tap7)
        
        tap6.require(toFail: tap7)
        
        let tap8 = UITapGestureRecognizer(target: self, action: #selector(rightTopSingleTapTwoFinger(_:)))
        tap8.numberOfTapsRequired = 1
        tap8.numberOfTouchesRequired = 2
        topRightView.addGestureRecognizer(tap8)
        
        let tap9 = UISwipeGestureRecognizer(target: self, action: #selector(rightTopSwipeRightToLeft(gesture:)))
        tap9.direction = .right
        topRightView.addGestureRecognizer(tap9)
        
        let tap10 = UILongPressGestureRecognizer(target: self, action: #selector(rightTopLongPress(_:)))
        tap10.minimumPressDuration = 1
        topRightView.addGestureRecognizer(tap10)
        
        let tap11 = UITapGestureRecognizer(target: self, action: #selector(bottomCenterSingleTap(_:)))
        tap11.numberOfTapsRequired = 1
        tap11.numberOfTouchesRequired = 1
        bottomCenterView.addGestureRecognizer(tap11)
        
        let tap12 = UITapGestureRecognizer(target: self, action: #selector(bottomCenterDoubleTap(_:)))
        tap12.numberOfTapsRequired = 2
        tap12.numberOfTouchesRequired = 1
        bottomCenterView.addGestureRecognizer(tap12)
        
        tap11.require(toFail: tap12)
        
        let tap13 = UILongPressGestureRecognizer(target: self, action: #selector(bottomCenterLongPress(_:)))
        tap13.minimumPressDuration = 1
        bottomCenterView.addGestureRecognizer(tap13)
        
        let tap14 = UITapGestureRecognizer(target: self, action: #selector(bottomLeftSingleTap(_:)))
        tap14.numberOfTapsRequired = 1
        tap14.numberOfTouchesRequired = 1
        bottomLeftView.addGestureRecognizer(tap14)
//
//        let tap12 = UILongPressGestureRecognizer(target: self, action: #selector(bottomLeftLongPress(_:)))
//        tap12.minimumPressDuration = 1
//        bottomLeftView.addGestureRecognizer(tap12)
//
        let tap15 = UITapGestureRecognizer(target: self, action: #selector(bottomRightSingleTap(_:)))
        tap15.numberOfTapsRequired = 1
        tap15.numberOfTouchesRequired = 1
        bottomRightView.addGestureRecognizer(tap15)
//
//        let tap14 = UILongPressGestureRecognizer(target: self, action: #selector(bottomRightLongPress(_:)))
//        tap14.minimumPressDuration = 1
//        bottomRightView.addGestureRecognizer(tap14)
        
        */
    }
    
    @objc func leftTopSingleTap(_ sender : UITapGestureRecognizer){
        print("left top single tap")
        //let value = btn.titleLabel?.text ?? FanGenTitles.empty.rawValue
        set(goalsLbl: "1", .first)
        delegate?.didTapGoal(self, goals: "1", team: .first)
        //set(goalsLbl: "1", .first)
        //delegate?.didTapGoal(self, goals: "1", team: .first)
    }
    
    @objc func leftTopDoubleTap(_ sender : UITapGestureRecognizer){
        print("left top double tap")
        set(goalsLbl: "2", .first)
        delegate?.didTapGoal(self, goals: "2", team: .first)
    }
    
    @objc func leftTopSingleTapTwoFinger(_ sender : UITapGestureRecognizer){
        print("left top single tap two finger")
        set(goalsLbl: "3", .first)
        delegate?.didTapGoal(self, goals: "3", team: .first)
    }
    
    @objc func leftTopSwipeRightToLeft(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == .left {
                if fGoalsLbl.text != "0" {
                    set(goalsLbl: "-1", .first)
                    delegate?.didTapGoal(self, goals: "-1", team: .first)
                }
                print("left top swipe right to left")
            }
        }
    }
    
    @objc func leftTopLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("left top long press")
            if fScoreUndoBtn.isEnabled == true {
                delegate?.undoScore(self, team: .first)
            }
        }
    }
    
    @objc func rightTopSingleTap(_ sender : UITapGestureRecognizer){
        print("right top single tap")
        set(goalsLbl: "1", .second)
        delegate?.didTapGoal(self, goals: "1", team: .second)
    }
    
    @objc func rightTopDoubleTap(_ sender : UITapGestureRecognizer){
        print("right top double tap")
        set(goalsLbl: "2", .second)
        delegate?.didTapGoal(self, goals: "2", team: .second)
    }
    
    @objc func rightTopSingleTapTwoFinger(_ sender : UITapGestureRecognizer){
        print("left top single tap two finger")
        set(goalsLbl: "3", .second)
        delegate?.didTapGoal(self, goals: "3", team: .second)
    }
    
    @objc func rightTopSwipeRightToLeft(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            if swipeGesture.direction == .right {
                if sGoalsLbl.text != "0" {
                    set(goalsLbl: "-1", .second)
                    delegate?.didTapGoal(self, goals: "-1", team: .second)
                }
                
                print("left top swipe right to left")
            }
        }
    }
    
    @objc func rightTopLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("left top long press")
            if sScoreUndoBtn.isEnabled == true {
                delegate?.undoScore(self, team: .second)
            }
        }
    }
    
    @objc func bottomLeftSingleTap(_ sender : UITapGestureRecognizer){
        print("bottom left single tap")
        //self.viewLogo.isHidden = false
        //self.viewLogo.rotate()
        //self.rotateView(targetView: viewLogo, duration: 1.0)
        //self.runSpinAnimation(on: viewLogo, duration: 1.0, rotations: 1, repeatCount: 1)
        NotificationCenter.default.post(name: NSNotification.Name("LogoAnimationNotification"), object: nil)
        delegate?.didTapMarker(FanGenMarker.generic, Team.first, 1)
    }
    
    @objc func bottomLeftLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("bottom left long press")
            
        }
    }
    
    @objc func bottomRightSingleTap(_ sender : UITapGestureRecognizer){
        print("bottom right single tap")         //self.viewLogo.isHidden = false
        //self.rotateView(targetView: viewLogo, duration: 1.0)
        NotificationCenter.default.post(name: NSNotification.Name("LogoAnimationNotification"), object: nil)
        delegate?.didTapMarker(FanGenMarker.generic, Team.second, 1)
    }
    
    @objc func bottomRightLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            print("bottom right long press")
        }
    }
//    
    @objc func bottomCenterSingleTap(_ sender : UITapGestureRecognizer){
        
        self.imgViewImageArchive.willRemoveSubview(avpController.view)
        player?.replaceCurrentItem(with: nil)
        print("bottom Center single tap")
        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                viewWithTag.removeFromSuperview()
            }
        let imagesArchive1 = DataManager.shared.imgArchives
        if imageArchiveSelected1 == -1 {
            if imagesArchive1.count > 0 {
                imageArchiveSelected1 =  0
                imgViewImageArchive.isHidden = false
                
                if imagesArchive1[0].fileName.contains(".gif") {
                    
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                    let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                } else if imagesArchive1[0].fileName.contains(".mov") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                    
                    let url = URL(fileURLWithPath: imagesArchive1[imageArchiveSelected1].filePath().path)
                
                    self.avplayerView(url: url, tag: 100)
                    
                }else {
//                    1img
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive1[0].filePath().path)
                }
            }
        } else {
            if (imageArchiveSelected1 + 1) == imagesArchive1.count {
                imageArchiveSelected1 =  0
                imgViewImageArchive.isHidden = false
                if imagesArchive1[0].fileName.contains(".gif") {
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                    
                    let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                } else if imagesArchive1[0].fileName.contains(".mov") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive1[0].filePath().path)
                    let url = URL(fileURLWithPath: imagesArchive1[imageArchiveSelected1].filePath().path)
                
                    self.avplayerView(url: url, tag: 100)
                }else {
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive1[0].filePath().path)
                }
            } else {
                imageArchiveSelected1 += 1
                imgViewImageArchive.isHidden = false
                
                if imagesArchive1[imageArchiveSelected1].fileName.contains(".gif") {
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                    
                    let data = FileManager.default.contents(atPath: imagesArchive1[imageArchiveSelected1].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else if imagesArchive1[imageArchiveSelected1].fileName.contains(".mov") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive1[imageArchiveSelected1].filePath().path)

                    let url = URL(fileURLWithPath: imagesArchive1[imageArchiveSelected1].filePath().path)
                
                    self.avplayerView(url: url, tag: 100)

                }else {
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive1[imageArchiveSelected1].filePath().path)
                }
            }
        }
        
        
    }

    
    func avplayerView(url: URL , tag : Int)  {
            self.player = AVPlayer(url: url)
            self.avpController = AVPlayerViewController()
            self.avpController.player = self.player
            avpController.view.tag = tag
            avpController.showsPlaybackControls = false
            self.imgViewImageArchive.frame = avpController.view.bounds
            self.imgViewImageArchive.addSubview(avpController.view)
            player?.play()
    }


       
    @objc func bottomCenterDoubleTap(_ sender : UITapGestureRecognizer){
        print("bottom Center double tap")
    
        self.imgViewImageArchive.willRemoveSubview(avpController.view)
        player?.replaceCurrentItem(with: nil)
        if let viewWithTag = self.avpController.view.viewWithTag(100) {
                viewWithTag.removeFromSuperview()
            }
        
        let imagesArchive2 = DataManager.shared.imgArchives2
        if imageArchiveSelected2 == -1 {
            if imagesArchive2.count > 0 {
                imageArchiveSelected2 =  0
                imgViewImageArchive.isHidden = false
                
                if imagesArchive2[0].fileName.contains(".gif") {
                    
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                    
                    let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }
                else if imagesArchive2[0].fileName.contains(".mov") {
                                         
                    let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                    
                    let url = URL(fileURLWithPath: imagesArchive2[imageArchiveSelected2].filePath().path)
                
                    self.avplayerView(url: url, tag: 100)
                    
                }else {
//                    1img
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive2[0].filePath().path)
                }
            }
        } else {
            if (imageArchiveSelected2 + 1) == imagesArchive2.count {
                imageArchiveSelected2 =  0
                imgViewImageArchive.isHidden = false
                
                if imagesArchive2[0].fileName.contains(".gif") {
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                    
                    let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else if imagesArchive2[0].fileName.contains(".mov") {
                                     
                    let data = FileManager.default.contents(atPath: imagesArchive2[0].filePath().path)
                    let url = URL(fileURLWithPath: imagesArchive2[imageArchiveSelected2].filePath().path)
                
                    self.avplayerView(url: url, tag: 100)
//                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }else {
                    //repeat 1img
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive2[0].filePath().path)
                }
            } else {
                imageArchiveSelected2 += 1
                imgViewImageArchive.isHidden = false

                
                if imagesArchive2[imageArchiveSelected2].fileName.contains(".gif") {
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                    
                    let data = FileManager.default.contents(atPath: imagesArchive2[imageArchiveSelected2].filePath().path)
                    
                    imgViewImageArchive.image = UIImage.gifImageWithData(data!)
                }
                else if imagesArchive2[imageArchiveSelected2].fileName.contains(".mov") {
                     
                    let data = FileManager.default.contents(atPath: imagesArchive2[imageArchiveSelected2].filePath().path)

                    let url = URL(fileURLWithPath: imagesArchive2[imageArchiveSelected2].filePath().path)
                
                    self.avplayerView(url: url, tag: 100)

                }else {
                    if let viewWithTag = self.avpController.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                imgViewImageArchive.image = UIImage(contentsOfFile: imagesArchive2[imageArchiveSelected2].filePath().path)
                }
            }
        }
        
    }
    
    func avPlayerSetup() {
        var audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
               try audioSession.setActive(true)
                try audioSession.overrideOutputAudioPort(.speaker)
           } catch {
               print("AVPlayer setup error \(error.localizedDescription)")
           }

       }
    
    @objc func bottomCenterLongPress(_ sender : UILongPressGestureRecognizer){
        if sender.state == .began {
            player?.replaceCurrentItem(with: nil)
            print("bottom center long press")
            imgViewImageArchive.isHidden = true
        }
    }
    
    private func rotateView(targetView: UIView, duration: Double = 1.0) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            targetView.transform = targetView.transform.rotated(by: CGFloat(Double.pi))
            targetView.transform = targetView.transform.rotated(by: CGFloat(Double.pi))
        }) { finished in
            //self.viewLogo.isHidden = true
            //self.rotateView(targetView: targetView, duration: duration)
        }
    }
    
    func runSpinAnimation(on view: UIView?, duration: CGFloat, rotations: CGFloat, repeatCount: Float) {
        view?.isHidden = false
        var rotationAnimation: CABasicAnimation?
        rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation?.toValue = NSNumber(value: Float(.pi * 2.0 /* full rotation*/ * rotations * duration))
        rotationAnimation?.duration = CFTimeInterval(duration)
        rotationAnimation?.isCumulative = true
        rotationAnimation?.repeatCount = repeatCount

        view?.layer.add(rotationAnimation!, forKey: "rotationAnimation")
        view?.isHidden = true
    }
    
    func setUndoBtn(enabled: Bool, team: Team) {
        if team == .first {
            fScoreUndoBtn.isEnabled = enabled
            fScoreUndoBtn.alpha = enabled ? 1 : 0.5
        } else {
            sScoreUndoBtn.isEnabled = enabled
            sScoreUndoBtn.alpha = enabled ? 1 : 0.5
        }
    }
    
    func setCurrentMatchTime(_ val: String) {
        timeMatchLbl.text = val
    }
    
    func setGrid(hide: Bool) {
        gridView.isHidden = hide
    }
    
    func setIndColMarkers(hide: Bool) {
        markerView.setIndColMarkerBtns(hide: hide) 
    }
    
    func set(goal val: Int, _ team: Team) {
        if team == .first, fGoalsLbl.text != "\(val)" {
            fGoalsLbl.text = "\(val)"
        } else {
            sGoalsLbl.text = "\(val)"
        }
    }
    
    func setFangenViewElements(enabled val: Bool) {
        markerView.setMarkerBtns(enabled: val)
        setEnabled(of: ffscoreBtn, to: val)
        setEnabled(of: fsscoreBtn, to: val)
        setEnabled(of: ftscoreBtn, to: val)
        setEnabled(of: sfcoreBtn, to: val)
        setEnabled(of: ssscoreBtn, to: val)
        setEnabled(of: stscoreBtn, to: val)
    }
    
    func isDisplayedGrid() -> Bool {
        return !gridView.isHidden
    }
    
    func isDisplayedIndColMarkers() -> Bool {
        return !markerView.f_individualBtn.isHidden
    }
    
    func undoAnimation(_ marker: Marker, _ team: Team) {
        markerView.undoMarkerAnimation(marker, team)
    }
    
    func disableScoreboardView() {
        point1TF.isUserInteractionEnabled = false
        point2TF.isUserInteractionEnabled = false
        point3TF.isUserInteractionEnabled = false
        timerBtn.isUserInteractionEnabled = false
        countdownBtn.isUserInteractionEnabled = false
        timerBtn.isUserInteractionEnabled = false
        periodTF.isUserInteractionEnabled = false
        disableTimer()
    }
    
    // scoreboard setting
//    func displayScoreboardSettingView(_ data: ScoreboardSetting)
    func displayScoreboardSettingView(_ data: ScoreboardSetting, selectedMatch : SelectedMatch) {

        scoreboardSettingView.isHidden = false
        
        if switchScoreboard.isOn && switchTimer.isOn  {
            enableScoreboardView()
            viewPeriodSB.backgroundColor = .darkGray
            viewTimeSB.backgroundColor = .darkGray
           
        } else {
            disableScoreboardView()
            viewPeriodSB.backgroundColor = .clear
            viewTimeSB.backgroundColor = .clear
            
        }
        scoreBoarddata = data
        point1TF.text = "\(data.point1)"
        point2TF.text = "\(data.point2)"
        point3TF.text = "\(data.point3)"
        periodTF.text = "\(data.period)"
        
        self.selectedMatch = selectedMatch
        fanGenService = FanGenerationService(self.selectedMatch, .record)

    }
//    {
////        bringSubviewToFront(scoreboardSettingView)
//        scoreboardSettingView.isHidden = false
//        scoreTF1.text = "\(data.point1)"
//        scoreTF2.text = "\(data.point2)"
//        scoreTF3.text = "\(data.point3)"
//        periodTF.text = "\(data.period)"
//    }
}

//MARK: - IBAction functions
extension FanGenerationVideo {
    
    @IBAction func onScoreBoardSettingBtn(_ sender: UIButton) {
        delegate?.didTapScoreboard(self)
    }
    
    @IBAction func onFTeamGoalBtn(_ sender: UIButton) {
        onGoalsBtn(on: sender, team: .first)
    }
    
    @IBAction func onScoreUndoBtn(_ sender: UIButton) {
        if sender == fScoreUndoBtn {
            delegate?.undoScore(self, team: .first)
        } else {
            delegate?.undoScore(self, team: .second)
        }
    }
    
    @IBAction func onSTeamGoalBtn(_ sender: UIButton) {
        onGoalsBtn(on: sender, team: .second)
    }
    
    @IBAction func onCloseScoreboardSettingBtn(_ sender: UIButton) {
        scoreboardSettingView.isHidden = true
        delegate?.didSaveScoreboardSetting(nil, nil, nil, nil)
    }
    
    @IBAction func onSaveScoreboardSettingBtn(_ sender: UIButton) {
//
//        let point1 = scoreTF1.text!
//        let point2 = scoreTF2.text!
//        let point3 = scoreTF3.text!
//        let period = periodTF.text!
//
//        let checkedStrs = [
//            point1, point2, point3, period
//        ]
//
//        guard ValidationService.validateEmptyStrs(checkedStrs) else {
//            MessageBarService.shared.warning("Input all setting information!")
//            return
//        }
//        guard ValidationService.validateStringLength(str: period, lengCount: 4) else {
//            MessageBarService.shared.warning("Period text length should be less than 4.")
//            return
//        }
//        guard ValidationService.validateNumSize(compareVal: point1, vVal: 15) else {
//            MessageBarService.shared.warning("The 1st score point should be less than 15.")
//            return
//        }
//        guard ValidationService.validateNumSize(compareVal: point2, vVal: 30) else {
//            MessageBarService.shared.warning("The 2nd score point should be less than 30.")
//            return
//        }
//        guard ValidationService.validateNumSize(compareVal: point3, vVal: 45) else {
//            MessageBarService.shared.warning("The 3rd score point should be less than 45.")
//            return
//        }
//
//        delegate?.didSaveScoreboardSetting(period, point1, point2, point3)
        scoreboardSettingView.isHidden = true
    }
    
    
    @IBAction func onTimerBtnTap(_ sender: Any) {
        showTimerSelected()
//        isCountdownClick = false
        let  minutes = (totalSecond) / 60
        let  seconds = (totalSecond) % 60
        if String(minutes).count == 3 {
            setCurrentMatchTime(String.init(format: "%03d'%02d", minutes,seconds))
        }
        else {
            setCurrentMatchTime(String.init(format: "%02d'%02d", minutes,seconds))
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
    }
 
    @IBAction func onCountdownBtnTap(_ sender: Any) {
        showCountdownSelected()
//        isCountdownClick = true
        let  minutes = (countdownValue) / 60
        let  seconds = (countdownValue) % 60
        if String(minutes).count == 3 {
            setCurrentMatchTime(String.init(format: "%03d'%02d", minutes,seconds))
        }
        else {
            setCurrentMatchTime(String.init(format: "%02d'%02d", minutes,seconds))
            //1
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
    }
    
    //fileprivate
    func showTimerSelected() {
        timerLineView.backgroundColor = UIColor.white
        countdownLineView.backgroundColor = UIColor.clear
        isCountdown = false
        countdownView.isHidden = true
        timerView.isHidden = false
    }
    
    fileprivate func showCountdownSelected() {
        timerLineView.backgroundColor = UIColor.clear
        countdownLineView.backgroundColor = UIColor.white
        isCountdown = true
        countdownView.isHidden = false
        timerView.isHidden = true
    }
    
    fileprivate func setStopTextOnButton() {
        startBtn.backgroundColor = UIColor.red
        startBtn.setTitle("Stop", for: .normal)
        
      
    }
    
    func timerStartNotify(){
//        if isCountdown{
//            MessageBarService.shared.notify("Countdown start Successfully!")
//        }else {
//            MessageBarService.shared.notify("Timer start Successfully!")
//        }
        
        isTimerStatus = true
    }
    
    func timerStopNotify(){
      
//        if isCountdown{
//            MessageBarService.shared.warning("Countdown stop Successfully!")
//        }else {
//            MessageBarService.shared.warning("Timer stop Successfully!")
//        }
        isTimerStatus = true
    }
    
    //fileprivate
    func setStartTextOnButton() {
        startBtn.backgroundColor = UIColor.green
        startBtn.setTitle("Start", for: .normal)

    }
    
    
@IBAction func onStartBtn(_ sender: Any) {
    UserDefaults.standard.set(true, forKey: "VideoTimeFromTimer")
    UserDefaults.standard.synchronize()
    
    if (startBtn.titleLabel?.text?.lowercased() == "Start".lowercased())
    {
        setStopTextOnButton()
        print(isCountdown)
        if isCountdown
        {
            if (countdownMinuteTF.text != "00" || countdownSecondsTF.text != "00")
            {
                if (countdownMinuteTF.text != "00")
                {
                    totalCountdownMinutes = (countdownMinuteTF.text! as NSString).integerValue
                }
                if (countdownSecondsTF.text != "00")
                {
                    totalCountdownSeconds = (countdownSecondsTF.text! as NSString).integerValue
                }
                countdownValue = (totalCountdownMinutes * 60) + totalCountdownSeconds
            }
            else
            {
                countdownValue = (appDelegate.videoCountdownTime as NSString).integerValue * 60
            }
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.countdownUpdate), userInfo: nil, repeats: true)
            
        }
        else
        {
            startTimer()
        }
        
        timerStartNotify()
        
        isTimeAnyChange = true
    }
    else
    {
        setStartTextOnButton()
        stopTimer()
        timerStopNotify()
        isTimeAnyChange = true
    }

   
}
    
//    @IBAction func point1TFDidEnd(_ sender: Any) {
//
//        guard ValidationService.validateNumSize(compareVal:  point1TF.text!, vVal: 15) else {
//            MessageBarService.shared.warning("The 1st score point should be less than 15.")
//            return
//        }
//
//        sfcoreBtn.setTitle(point1TF.text, for: .normal)
//        ffscoreBtn.setTitle(point1TF.text, for: .normal)
//    }
//
//    @IBAction func point2TFDidEnd(_ sender: Any) {
//
//        guard ValidationService.validateNumSize(compareVal: point2TF.text!, vVal: 30) else {
//            MessageBarService.shared.warning("The 2nd score point should be less than 30.")
//            return
//        }
//
//        ssscoreBtn.setTitle(point2TF.text, for: .normal)
//        fsscoreBtn.setTitle(point2TF.text, for: .normal)
//    }
//
//    @IBAction func point3TFDidEnd(_ sender: Any) {
//
//        guard ValidationService.validateNumSize(compareVal: point3TF.text!, vVal: 45) else {
//            MessageBarService.shared.warning("The 3rd score point should be less than 45.")
//            return
//        }
//
//        stscoreBtn.setTitle(point3TF.text, for: .normal)
//        ftscoreBtn.setTitle(point3TF.text, for: .normal)
//    }

    
    @objc func countdownUpdate() {
        self.ischanged = true
//        appDelegate.isTimeFromCountdown = true
        minuteTF.isUserInteractionEnabled = false
        secondsTF.isUserInteractionEnabled = false
        countdownSecondsTF.isUserInteractionEnabled = false
        countdownMinuteTF.isUserInteractionEnabled = false
        timerBtn.isUserInteractionEnabled = false
        countdownBtn.isUserInteractionEnabled = false
        resetBtn.isUserInteractionEnabled = false
        
        resetBtn.backgroundColor = UIColor.lightGray
        
        isTimerOn = true
        
        var minutes: Int
        var seconds: Int
        if(countdownValue > 0) {
            
            countdownValue = countdownValue - 1
            minutes = (countdownValue) / 60  // (countdownValue ) / 60 //5
            seconds = (countdownValue) % 60 // (countdownValue) % 60
            displayCountdownValue(minutes, seconds)
           
            let strMinutes = String(minutes)
            if strMinutes.count >= 3 {
                if minutes == 999 {
                    stopTimer()
                    resetTimer()
                    MessageBarService.shared.warning("countdown max setted from 999:00")
                    return
                }
            }
            if (countdownValue == 0)
            {
                stopTimer()
            }
        }
  
    }

@IBAction func onResetBtn(_ sender: Any) {
    resetTimer()
}

    
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
    }
    
    func DisplayInitialTime( _ timerTime: String, _ countdownTime: String, _ isTimeFromCountdown : Bool) {
        self.setTimerView.isHidden = true
        let separators = CharacterSet(charactersIn: "\':")
        let myStringArrTimer = timerTime.components(separatedBy: separators)
        let myStringArrCountdown = countdownTime.components(separatedBy: separators)

        let strMinTimer: String = myStringArrTimer [0]
        let strSecondTimer: String = myStringArrTimer [1]
        
        let strMinCountdown: String = myStringArrCountdown [0]
        let strSecondCountdown: String = myStringArrCountdown [1]
        
        minuteTF.text = strMinTimer
        secondsTF.text = strSecondTimer
        self.totalSecond = (strMinTimer as NSString).integerValue * 60 + (strSecondTimer as NSString).integerValue
                
        countdownMinuteTF.text = strMinCountdown// String((strMin as NSString).integerValue / 60)
        countdownMinuteTF.text = strMinCountdown// String((strMin as NSString).integerValue / 60)
        countdownSecondsTF.text = strSecondCountdown // String((strSecond as NSString).integerValue % 60)
        self.countdownValue = (strMinCountdown as NSString).integerValue * 60 + (strSecondCountdown as NSString).integerValue
        
        if (isTimeFromCountdown) {
            showCountdownSelected()
            displayCountdownValue((strMinCountdown as NSString).integerValue, (strSecondCountdown as NSString).integerValue)
            
        }
        else {
            showTimerSelected()
//            displayTimerValue((strMinTimer as NSString).integerValue, (strSecondTimer as NSString).integerValue)
            
//            if isCountdownClick == true {
//                displayCountdownValue((strMinCountdown as NSString).integerValue, (strSecondCountdown as NSString).integerValue)
//            }else {
//                displayTimerValue((strMinTimer as NSString).integerValue, (strSecondTimer as NSString).integerValue)
//            }
        }
    }
    
    
    @objc func timerUpdate() {
        
        self.ischanged = true
//        appDelegate.isTimeFromCountdown = false

        minuteTF.isUserInteractionEnabled = false
        secondsTF.isUserInteractionEnabled = false
        countdownSecondsTF.isUserInteractionEnabled = false
        countdownMinuteTF.isUserInteractionEnabled = false
        timerBtn.isUserInteractionEnabled = false
        countdownBtn.isUserInteractionEnabled = false
        resetBtn.isUserInteractionEnabled = false
        resetBtn.backgroundColor = UIColor.lightGray
                
        isTimerOn = true
        
        var minutes: Int
        var seconds: Int
 
        setTimerLimit()
        totalSecond += 1
        minutes = (totalSecond) / 60
        seconds = (totalSecond) % 60
        displayTimerValue(minutes, seconds)
        let strMinutes = String(minutes)
        
        if strMinutes.count >= 3 {
            if minutes == 999 {
                MessageBarService.shared.warning("timer can reach 999:00")
                stopTimer()
                resetTimer()
                return
            }
        }

    }
    
    
    fileprivate func setTimerLimit() {
        if (minuteTF.text != "00" &&  minuteTF.text != "")
        {
            totalTimerMinutes = (minuteTF.text! as NSString).integerValue
        }
        if (secondsTF.text != "00" &&  secondsTF.text != "")
        {
            totalTimerSeconds = (secondsTF.text! as NSString).integerValue
        }
        
        if isTextfieldEdited {
            isTextfieldEdited = false
            totalSecond = (totalTimerMinutes * 60) + totalTimerSeconds
        }
    }
    
    func stopTimer() {
        isTimerOn = false
        setStartTextOnButton()
        timer?.invalidate()
//        timer = nil
        if isCountdown
        {
            let   minutes = (countdownValue) / 60
            let   seconds = (countdownValue) % 60
            checkAndSetTopTime(minutes, seconds)
        }
        else
        {
            let   minutes = (totalSecond) / 60
            let   seconds = (totalSecond) % 60
            checkAndSetTopTime(minutes, seconds)
        }
        
        resetBtn.isUserInteractionEnabled = true
        minuteTF.isUserInteractionEnabled = true
        secondsTF.isUserInteractionEnabled = true
        countdownMinuteTF.isUserInteractionEnabled = true
        countdownSecondsTF.isUserInteractionEnabled = true
        countdownBtn.isUserInteractionEnabled = true
        timerBtn.isUserInteractionEnabled = true
        
        resetBtn.backgroundColor = UIColor.white
        
        if ischanged {
            print(ischanged)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
        }else {
            print(ischanged)
            //false
            
        }
        self.ischanged = false
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
    }
    
    func resetTimer() {
        isTimerOn = false
        setStartTextOnButton()
        timer?.invalidate()
        totalSecond = 0
        totalTimeInSecondsLimit = 0
        totalTimerSeconds = 0
        totalTimerMinutes = 0
        totalTimerHour = (appDelegate.videoTimerTime as NSString).integerValue
        countdownValue = (appDelegate.videoCountdownTime as NSString).integerValue * 60
        
        if isCountdown
        {
            let   seconds = (countdownValue) % 60
            displayCountdownValue(15, seconds)
            
            self.selectedMinutesCountDown = 15
            self.selectedSecondsCountDown = seconds
            
            self.timerSpinnerView.selectRow(15, inComponent: 0, animated: true)
            self.timerSpinnerView.selectRow(seconds, inComponent: 1, animated: true)
            timerSpinnerView.reloadAllComponents()
            
            
        }
        else
        {
            let   minutes = (totalSecond) / 60
            let   seconds = (totalSecond) % 60
            displayTimerValue(minutes, seconds)
            
            self.selectedMinutes = minutes
            self.selectedSeconds = seconds
            self.timerSpinnerView.selectRow(minutes, inComponent: 0, animated: true)
            self.timerSpinnerView.selectRow(seconds, inComponent: 1, animated: true)
            timerSpinnerView.reloadAllComponents()
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
    }
}

//MARK: - MarkersViewDelegate
extension FanGenerationVideo: MarkersViewDelegate {
    
    func didTap(on view: MarkersView, btn: UIButton, type: FanGenMarker, team: Team, countPressed: Int) {
        
        currentCountPressed = countPressed
        
        delegate?.didTapMarker(view, btn, type, team, countPressed)
        
        print(type)
        print(countPressed)
        if type == .individual || type == .collective {
            DispatchQueue.main.async {
                self.addTagsView()
                self.tagsView.set(type)
                
                if type == .collective{
                    let collectiveData = DataManager.shared.settingsMarkers[ MarkerType.collective.rawValue]
                    let jsonData = try! JSONEncoder().encode(collectiveData)
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    
                    print(collectiveData)
                    print(jsonData)
                    print(jsonString)
                     let messageDict = ["CollectiveData":jsonString]
                    
                    FannerCamWatchKitShared.sendMessageToWatchWithData(message: messageDict) {
                    }
                }
                
                
            }
        }
    }
    
}

//MARK: - TagsView delegate & data source
extension FanGenerationVideo: TagsViewDelegate, TagsViewDataSource {
    
    func tagsView(_ tagNumView: TagNumView, didClickedSave button: UIButton, tagNum value: String) {
        delegate?.fanGenerationVideo(self, didClickedTagSave: button, tagNum: value, countPressed: currentCountPressed)
        tagsView.removeFromSuperview()
        isDisplayedSubViews = false
        markerView.markerEndAnimation()
    }
    
    func tagsView(_ tagsView: TagsView, didSelectTagAt index: Int, _ type: FanGenMarker) {
        delegate?.fanGenerationVideo(self, didSelectTagAt: index, type, currentCountPressed)
        if type == .collective {
            
            DispatchQueue.main.async {
                tagsView.removeFromSuperview()
                self.isDisplayedSubViews = false
                self.markerView.markerEndAnimation()
            }
        }
    }
    
    func tagsView(_ tagsView: TagsView, heightForTagViewAt index: Int) -> CGFloat {
        return delegate?.fanGenerationVideo(self, heightForTagViewAt: index) ?? 44
    }
    
    // TagsViewDataSource
    func numberOfTags(in tagView: TagsView) -> Int {
        return dataSource?.numberOfTags(in: self) ?? 0
    }
    
    func tagsView(_ tagsView: TagsView, tagMarkerAt index: Int) -> Marker {
        return (dataSource?.fanGenerationVideo(self, tagCellAt: index))!
    }
    
}

//MARK: - data for UI set functions
extension FanGenerationVideo {
    func initNib() {
        func initData() {
            genMode = dataSource?.fanGenerationVideoMode() ?? FanGenMode.record
            if let fScore = dataSource?.fanGenScoreValue(self, .first) {
                fGoalsLbl.text = "\(fScore)"
            }
            if let sScore = dataSource?.fanGenScoreValue(self, .second) {
                sGoalsLbl.text = "\(sScore)"
            }
        }
        
        func initLayout()
//        {
//            markerView = MarkersView.instanceFormNib()
//            markerView.delegate = self
//            markerView.frame = middleView.bounds
//            middleView.addSubview(markerView)
//        }
        {
  
            awayCloseBtn.setTitle("", for: .normal)
            closeBtnColor.setTitle("", for: .normal)
            mainColorPickerView.isHidden  = true
            
            
            markerView = MarkersView.instanceFormNib()
            markerView.delegate = self
            markerView.frame = middleView.bounds
            middleView.addSubview(markerView)
            
            internalStackView.backgroundColor = UIColor.clear
            timerLineView.backgroundColor = UIColor.white
            countdownLineView.backgroundColor = UIColor.clear
            startBtn.backgroundColor = UIColor.green
            
            timerMainView.layer.borderWidth = 1
            timerMainView.layer.borderColor = UIColor.white.cgColor
            timerMainView.layer.cornerRadius = 5
            periodView.layer.borderWidth = 1
            periodView.layer.borderColor = UIColor.white.cgColor
            periodView.layer.cornerRadius = 5
            
            startBtn.layer.cornerRadius = startBtn.frame.height/2
            resetBtn.layer.cornerRadius = resetBtn.frame.height/2
            
//            let dismissScoreboardTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissScoreboardTap(_:)))
//            dismissScoreboardTapGesture.numberOfTapsRequired = 1
//            dismissScoreboardTapGesture.numberOfTouchesRequired = 1
//            scoreboardDismissBtn.addGestureRecognizer(dismissScoreboardTapGesture)
            
            countdownView.isHidden = appDelegate.isTimeFromCountdown
            timerView.isHidden = !appDelegate.isTimeFromCountdown
            isCountdown = appDelegate.isTimeFromCountdown
            isCountdown = false
            let separators = CharacterSet(charactersIn: "\':")
            let myStringArrTimer = appDelegate.videoTimerTime.components(separatedBy: separators)
            print(myStringArrTimer)
            let myStringArrCountdown = appDelegate.videoCountdownTime.components(separatedBy: separators)

            let strMinTimer: String = myStringArrTimer [0]
            let strSecondTimer: String = myStringArrTimer [1]
            
            let strMinCountdown: String = myStringArrCountdown [0]
            let strSecondCountdown: String = myStringArrCountdown [1]
            
            displayTimerValue((strMinTimer as NSString).integerValue, (strSecondTimer as NSString).integerValue)
            displayCountdownValue((strMinCountdown as NSString).integerValue, (strSecondCountdown as NSString).integerValue)
            
            minuteTF.delegate = self
            secondsTF.delegate = self
            countdownMinuteTF.delegate = self
            countdownSecondsTF.delegate = self
            
            point1TF.delegate = self
            point2TF.delegate = self
            point3TF.delegate = self
          
            periodTF.tag = 1
            
            point2TF.tag = 2
            point3TF.tag = 3
            
            self.enableScoreboardView()
            
            minuteTF.addTarget(self, action: #selector(minuteTFDidBeginEditing(_:)), for: .editingDidBegin)
//            minuteTF.addTarget(self, action: #selector(minuteTFEditingChanged(_:)), for: .editingChanged)
//            minuteTF.addTarget(self, action: #selector(timerMinuteTFDidEnd(_:)), for: .editingDidEnd)
            
            secondsTF.addTarget(self, action: #selector(secondsTFDidBeginEditing(_:)), for: .editingDidBegin)
//            secondsTF.addTarget(self, action: #selector(secondTfEditingChanged(_:)), for: .editingChanged)
//            secondsTF.addTarget(self, action: #selector(timerSecondsTFDidEnd(_:)), for: .editingDidEnd)
            
            
            countdownMinuteTF.addTarget(self, action: #selector(countdownMinutesTFDidBeginEditing(_:)), for: .editingDidBegin)
//            countdownMinuteTF.addTarget(self, action: #selector(countdownMinuteTfEditingChanged(_:)), for: .editingChanged)
//            countdownMinuteTF.addTarget(self, action: #selector(countdownMinuteTFDidEnd(_:)), for: .editingDidEnd)
            
            countdownSecondsTF.addTarget(self, action: #selector(countdownSecondsTFDidBeginEditing(_:)), for: .editingDidBegin)
//            countdownSecondsTF.addTarget(self, action: #selector(countdownSeconTfEditingChanged(_:)), for: .editingChanged)
//            countdownSecondsTF.addTarget(self, action: #selector(countdownSecondsTFDidEnd(_:)), for: .editingDidEnd)
            
            
            point1TF.addTarget(self, action: #selector(point1TFDidBeginEditing(_:)), for: .editingDidBegin)
            point2TF.addTarget(self, action: #selector(point2TFDidBeginEditing(_:)), for: .editingDidBegin)
            point3TF.addTarget(self, action: #selector(point3TFDidBeginEditing(_:)), for: .editingDidBegin)
            
            timerSpinnerView.delegate = self
            timerSpinnerView.dataSource = self
            
            timerSpinnerView.setValue(UIColor.white, forKeyPath: "textColor")
            
            
            pointSpinnerView.delegate = self
            pointSpinnerView.dataSource = self
            
            pointSpinnerView.setValue(UIColor.white, forKeyPath: "textColor")
            
//            timerSpinnerView.backgroundColor = .darkGray
            setupLiveButton()
            
        }
        
        initLayout()
        initData()
        
        //constratins fitting
        func initConstraintForiPad() {
            if UI_USER_INTERFACE_IDIOM() != .phone {
                scoreBtnsHeight.constant = 60
                //ipad app crash
//                scoreboardHeight.constant = 50
                let padFont = UIFont.systemFont(ofSize: 18)
                ffscoreBtn.titleLabel?.font = padFont
                fsscoreBtn.titleLabel?.font = padFont
                ftscoreBtn.titleLabel?.font = padFont
                sfcoreBtn.titleLabel?.font = padFont
                ssscoreBtn.titleLabel?.font = padFont
                stscoreBtn.titleLabel?.font = padFont
                
                fGoalsLbl.font = padFont
                fPeriodLbl.font = padFont
                fTeamNameLbl.font = padFont 
                
                sGoalsLbl.font = padFont
                sTeamNameLbl.font = padFont
                timeMatchLbl.font = padFont
            }
        }
        initConstraintForiPad()
    }
    
    @objc func point1TFDidBeginEditing(_ textField: UITextField) {
        self.timerSpinnerView.isHidden = true
        self.pointSpinnerView.isHidden = false
        
        self.pointSpinnerView.selectRow(oldValueP1, inComponent: 0, animated: true)
        self.pointSpinnerView.reloadAllComponents()
        self.setTimerView.isHidden = false
        point1View.isHidden = true
        point2View.isHidden = true
        point3View.isHidden = true
        point1TF.resignFirstResponder()
        disablePointInteraction()
    }
    
    @objc func point2TFDidBeginEditing(_ textField: UITextField) {
        self.pointSpinnerView.selectRow(oldValueP2, inComponent: 0, animated: true)
        self.pointSpinnerView.reloadAllComponents()
        self.timerSpinnerView.isHidden = true
        self.pointSpinnerView.isHidden = false
        
//        self.mainPointPickerView.isHidden = false
        self.setTimerView.isHidden = false
        disablePointInteraction()
        point1View.isHidden = true
        point2View.isHidden = true
        point3View.isHidden = true
        point2TF.resignFirstResponder()
    }
    
    @objc func point3TFDidBeginEditing(_ textField: UITextField) {
        self.pointSpinnerView.selectRow(oldValueP3, inComponent: 0, animated: true)
        self.pointSpinnerView.reloadAllComponents()
        self.setTimerView.isHidden = false
//        self.mainPointPickerView.isHidden = false
        self.timerSpinnerView.isHidden = true
        self.pointSpinnerView.isHidden = false
        
        point3TF.resignFirstResponder()
        disablePointInteraction()
        point1View.isHidden = true
        point2View.isHidden = true
        point3View.isHidden = true
    }
    
    
    func setupLiveButton(){
        
        let inset: CGFloat = 70.0 // You can adjust this value as needed
        markerView.f_new_collectiveBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: 0)
        markerView.s_new_collectiveBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left:0, bottom: 0, right: -inset)
        
        markerView.f_individualBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: 0)
        markerView.f_genericBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: 0)
        markerView.f_collectiveBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: 0)
        
        markerView.s_individualBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left:0, bottom: 0, right: -inset)
        markerView.s_genericBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left:0, bottom: 0, right: -inset)
        markerView.s_collectiveBtn.imageEdgeInsets = UIEdgeInsets(top: 0, left:0, bottom: 0, right: -inset)
    }
//    @objc func dismissScoreboardTap(_ sender : UITapGestureRecognizer){
//        scoreboardSettingView.isHidden = true
//
//        let point1 = point1TF.text!
//        let point2 = point2TF.text!
//        let point3 = point3TF.text!
//        let period = periodTF.text!
//
//        let checkedStrs = [
//            point1, point2, point3, period
//        ]
//
//        guard ValidationService.validateEmptyStrs(checkedStrs) else {
//            MessageBarService.shared.warning("Input all setting information!")
//            return
//        }
//        guard ValidationService.validateStringLength(str: period, lengCount: 4) else {
//            MessageBarService.shared.warning("Period text length should be less than 4.")
//            return
//        }
//        guard ValidationService.validateNumSize(compareVal: point1, vVal: 15) else {
//            MessageBarService.shared.warning("The 1st score point should be less than 15.")
//            return
//        }
//        guard ValidationService.validateNumSize(compareVal: point2, vVal: 30) else {
//            MessageBarService.shared.warning("The 2nd score point should be less than 30.")
//            return
//        }
//        guard ValidationService.validateNumSize(compareVal: point3, vVal: 45) else {
//            MessageBarService.shared.warning("The 3rd score point should be less than 45.")
//            return
//        }
//
//
//        saveColorTeame1 = UserDefaults.standard.backgroundColorTeam1
//        saveColorTeame2 = UserDefaults.standard.backgroundColorTeam2
//
//        delegate?.didSaveScoreboardSetting(period, point1, point2, point3)
//
//        isTimerStatus = false
//    }
    
    func addTagsView() {
        tagsView = TagsView.instanceFromNib()
        tagsView.dataSource = self
        tagsView.delegate = self
//        tagsView.frame = bounds
//        addSubview(tagsView)
        isDisplayedSubViews = true
        if isstremingPage {
            tagsView.frame = appDelegate.secondWindow!.bounds
            appDelegate.secondWindow?.addSubview(tagsView)
            appDelegate.secondWindow?.bringSubviewToFront(tagsView)
        }else {
            tagsView.frame = bounds
            addSubview(tagsView)
        }
    }
    
        
    fileprivate func displayTimerValue(_ minutes: Int, _ seconds: Int) {
        secondsTF.text = String(format: "%02d", seconds)
        if (String(minutes).count > 2 && String(minutes).count == 3)
        {
            minuteTF.text = String(format: "%03d", minutes)
            appDelegate.videoTimerTime = String.init(format: "%03d'%02d", minutes,seconds)
        }
        else
        {
            minuteTF.text = String(format: "%02d", minutes)
            appDelegate.videoTimerTime = String.init(format: "%02d'%02d", minutes,seconds)
        }
        checkAndSetTopTime(minutes, seconds)
    }
     
    fileprivate func checkAndSetTopTime(_ minutes: Int, _ seconds: Int) {
        if (String(minutes).count > 2 && String(minutes).count == 3)
        {
            setCurrentMatchTime(String.init(format: "%03d'%02d", minutes,seconds))
        }
        else
        {
            setCurrentMatchTime(String.init(format: "%02d'%02d", minutes,seconds))
        }
    }
     
    fileprivate func displayCountdownValue(_ minutes: Int, _ seconds: Int) {
        countdownMinuteTF.text = String(format: "%02d", minutes)
        countdownSecondsTF.text = String(format: "%02d", seconds)
        setCurrentMatchTime(String.init(format: "%02d'%02d", minutes,seconds)) //4
        appDelegate.videoCountdownTime = String.init(format: "%02d'%02d", minutes,seconds)
    }
    
    func enableScoreboardView() {
        point1TF.isUserInteractionEnabled = true
        point2TF.isUserInteractionEnabled = true
        point3TF.isUserInteractionEnabled = true
        timerBtn.isUserInteractionEnabled = true
        countdownBtn.isUserInteractionEnabled = true
        periodTF.isUserInteractionEnabled = true
//        switchTimer.isUserInteractionEnabled = true
        startBtn.isUserInteractionEnabled = true
        
        if switchTimer.isOn {
            enableTimer()
        }
        else {
            disableTimer()
        }
    }
    
    fileprivate func disableTimer() {
        minuteTF.isUserInteractionEnabled = false
        secondsTF.isUserInteractionEnabled = false
        countdownSecondsTF.isUserInteractionEnabled = false
        countdownMinuteTF.isUserInteractionEnabled = false
        timerBtn.isUserInteractionEnabled = false
        countdownBtn.isUserInteractionEnabled = false
        startBtn.isUserInteractionEnabled = false
        resetBtn.isUserInteractionEnabled = false
        
        resetBtn.backgroundColor = UIColor.lightGray
    }
    
    fileprivate func enableTimer() {
        minuteTF.isUserInteractionEnabled = true
        secondsTF.isUserInteractionEnabled = true
        countdownSecondsTF.isUserInteractionEnabled = true
        countdownMinuteTF.isUserInteractionEnabled = true
        timerBtn.isUserInteractionEnabled = true
        countdownBtn.isUserInteractionEnabled = true
        startBtn.isUserInteractionEnabled = true
        resetBtn.isUserInteractionEnabled = true
        resetBtn.backgroundColor = UIColor.white
    }
    
    
    func disableInteraction(){
        
        
        self.topScoreboardView.isUserInteractionEnabled = false
        self.topScoreboardView.alpha = 0.3
        
        self.colourPickerView.alpha = 0.3
        self.viewMainTimer.alpha = 0.3
        self.scorePointView.alpha = 0.3

        
        self.colourPickerView.isUserInteractionEnabled = false
        self.viewMainTimer.isUserInteractionEnabled = false
        self.scorePointView.isUserInteractionEnabled = false
    }
    
    func disablePointInteraction(){
        self.topScoreboardView.isUserInteractionEnabled = false
        self.topScoreboardView.alpha = 0.3
        
        self.colourPickerView.alpha = 0.3
        self.viewMainTimer.alpha = 0.3
//        self.scorePointView.alpha = 0.3

        
        self.colourPickerView.isUserInteractionEnabled = false
        self.viewMainTimer.isUserInteractionEnabled = false
//        self.scorePointView.isUserInteractionEnabled = false
    }
    

    
    @objc func countdownMinutesTFDidBeginEditing(_ textField: UITextField) {
        // Perform your action here when the user clicks on the UITextField
        self.setTimerView.isHidden = false
        self.timerSpinnerView.isHidden = false
        self.pointSpinnerView.isHidden = true
        disableInteraction()
        countdownMinuteTF.resignFirstResponder()
        timerSpinnerView.selectRow(selectedMinutesCountDown, inComponent: 0, animated: true)
        timerSpinnerView.selectRow(selectedSecondsCountDown, inComponent: 1, animated: true)
        self.timerSpinnerView.reloadAllComponents()
    }
    
    
    @objc func countdownSecondsTFDidBeginEditing(_ textField: UITextField) {
        // Perform your action here when the user clicks on the UITextField
        self.setTimerView.isHidden = false
        self.timerSpinnerView.isHidden = false
        self.pointSpinnerView.isHidden = true
        countdownSecondsTF.resignFirstResponder()
        disableInteraction()
        timerSpinnerView.selectRow(selectedMinutesCountDown, inComponent: 0, animated: true)
        timerSpinnerView.selectRow(selectedSecondsCountDown, inComponent: 1, animated: true)
        self.timerSpinnerView.reloadAllComponents()
    }
    
    
    @objc func minuteTFDidBeginEditing(_ textField: UITextField) {
        // Perform your action here when the user clicks on the UITextField
        self.setTimerView.isHidden = false
        self.timerSpinnerView.isHidden = false
        self.pointSpinnerView.isHidden = true
        minuteTF.resignFirstResponder()
        disableInteraction()
        // Assuming pickerView is your UIPickerView instance

        timerSpinnerView.selectRow(selectedMinutes, inComponent: 0, animated: true)
        timerSpinnerView.selectRow(selectedSeconds, inComponent: 1, animated: true)

        self.timerSpinnerView.reloadAllComponents()
    }
    
    @objc func secondsTFDidBeginEditing(_ textField: UITextField) {
        // Perform your action here when the user clicks on the UITextField
        self.setTimerView.isHidden = false
        self.timerSpinnerView.isHidden = false
        self.pointSpinnerView.isHidden = true
        secondsTF.resignFirstResponder()
        disableInteraction()
        timerSpinnerView.selectRow(selectedMinutes, inComponent: 0, animated: true)
        timerSpinnerView.selectRow(selectedSeconds, inComponent: 1, animated: true)
        self.timerSpinnerView.reloadAllComponents()
    }

    
//    @objc func minuteTFEditingChanged(_ textField: UITextField) {
//
//        if (textField.text!.count >= 3)
//        {
//            minuteTF.resignFirstResponder()
//        }
//    }

//    @objc func timerMinuteTFDidEnd(_ textField: UITextField) {
//        isTextfieldEdited = true
//
//        totalTimerMinutes = (minuteTF.text! as NSString).integerValue
//        if secondsTF.text != nil && secondsTF.text != "" {
//            totalTimerSeconds = (secondsTF.text! as NSString).integerValue
//        }
//
//        totalSecond = (totalTimerMinutes * 60) + totalTimerSeconds
//        appDelegate.isTimeFromCountdown = false
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
//
////        saveTimerCountdownValues()
//    }
    
    
//    @objc func secondTfEditingChanged(_ textField: UITextField) {
//
//    }

//    @objc func timerSecondsTFDidEnd(_ textField: UITextField) {
//        isTextfieldEdited = true
//        totalTimerSeconds = (secondsTF.text! as NSString).integerValue
//        if minuteTF.text != nil && minuteTF.text != "" {
//            totalTimerMinutes = (minuteTF.text! as NSString).integerValue
//        }
//
//        totalSecond = (totalTimerMinutes * 60) + totalTimerSeconds
//        appDelegate.isTimeFromCountdown = false
//
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
////        saveTimerCountdownValues()
//    }
 
    
    

    
//    @objc func countdownMinuteTfEditingChanged(_ textField: UITextField) {
//        if (textField.text!.count >= 2)
//        {
//            countdownMinuteTF.resignFirstResponder()
//        }
//    }

//    @objc func countdownMinuteTFDidEnd(_ textField: UITextField) {
//        totalCountdownMinutes = (countdownMinuteTF.text! as NSString).integerValue
//        if countdownSecondsTF.text != nil && countdownSecondsTF.text != "" {
//            totalCountdownSeconds = (countdownSecondsTF.text! as NSString).integerValue
//        }
//        countdownValue = (totalCountdownMinutes * 60) + totalCountdownSeconds
//        appDelegate.isTimeFromCountdown = true
//
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
////        saveTimerCountdownValues()
//    }
    
    
//    @objc func countdownSeconTfEditingChanged(_ textField: UITextField) {
//
//    }

//    @objc func countdownSecondsTFDidEnd(_ textField: UITextField) {
//
//
//
//        totalCountdownSeconds = (countdownSecondsTF.text! as NSString).integerValue
//        if countdownMinuteTF.text != nil && countdownMinuteTF.text != "" {
//            totalCountdownMinutes = (countdownMinuteTF.text! as NSString).integerValue
//        }
//        countdownValue = (totalCountdownMinutes * 60) + totalCountdownSeconds
//        appDelegate.isTimeFromCountdown = true
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerCountdownValueChanged"), object: nil)
////        saveTimerCountdownValues()
//    }

    
}

extension UIView{
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = 1
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}

extension FileManager {
    func urls(for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true ) -> [URL]? {
        let documentsURL = urls(for: directory, in: .userDomainMask)[0]
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}


    
/*
 videoSize :: (896.0, 414.0)
 videoAspectRatio :: 2.1642512077294684
 heightScreen :: 414.0
 desiredWidth :: 895.9999999999999
 desiredHeight :: 414.0
 screenHeight :: 414.0
 screenWidth :: 896.0
 xupdate : 80.0
 */


/*
 videoAspectRatio :: 2.1653333333333333
 heightScreen :: 375.0
 desiredWidth :: 812.0
 desiredHeight :: 375.0
 Optional("00:00:16")
 screenHeight :: 375.0
 screenWidth :: 812.0

 xupdate : 72.66666666666669
 */
