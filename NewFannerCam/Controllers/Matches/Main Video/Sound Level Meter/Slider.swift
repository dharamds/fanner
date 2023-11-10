//
//  Slider.swift
//  SummerSlider
//
//  Created by derrick on 26/09/2017.
//  Copyright © 2017 SuperbDerrick. All rights reserved.
//

import Foundation
import UIKit

struct Slider{
	var iMarkColor : UIColor
	var iSelectedBarColor : UIColor
	var iUnSelectedBarColor : UIColor
	var iMarkWidth : Float
	var iMarkPositions : Array<Float>
	var iDrawingMode : DrawingMode
	var style: SliderStyle
}



public enum DrawingMode {
    case BothSides
    case UnselectedOnly
    case SelectedOnly
    case WithoutMarks
}

public enum SliderStyle {
    case Horizontal
    case Vertical
}
