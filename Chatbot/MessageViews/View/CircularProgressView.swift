//
//  CircularProgressView.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 15/04/24.
//

import Foundation
import UIKit
import QuartzCore

class CircularProgressView: UIView {
    
    private var progressLayer = CAShapeLayer()
    private var tracklayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureProgressViewToBeCircular()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureProgressViewToBeCircular()
    }
    
    var setProgressColor: UIColor = UIColor.red {
        didSet {
            progressLayer.strokeColor = setProgressColor.cgColor
        }
    }
    
    var setTrackColor: UIColor = UIColor.white {
        didSet {
            tracklayer.strokeColor = setTrackColor.cgColor
        }
    }
    
    private var viewCGPath: CGPath? {
        return UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0),
                            radius: (frame.size.width - 1.5)/2,
                            startAngle: CGFloat(-0.5 * Double.pi),
                            endAngle: CGFloat(1.5 * Double.pi), clockwise: true).cgPath
    }
    
    private func configureProgressViewToBeCircular() {
        self.drawsView(using: tracklayer, startingPoint: 10.0, ending: 1.0)
        self.drawsView(using: progressLayer, startingPoint: 10.0, ending: 0.0)
    }
    
    private func drawsView(using shape: CAShapeLayer, startingPoint: CGFloat, ending: CGFloat) {
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = self.frame.size.width/2.0
        
        shape.path = self.viewCGPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = setProgressColor.cgColor
        shape.lineWidth = startingPoint
        shape.strokeEnd = ending
        
        self.layer.addSublayer(shape)
    }
    
    func setProgressWithAnimation(duration: TimeInterval, value: Float) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        
        animation.fromValue = 0
        animation.toValue = value
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        progressLayer.strokeEnd = CGFloat(value)
        progressLayer.add(animation, forKey: "animateCircle")
    }
}
