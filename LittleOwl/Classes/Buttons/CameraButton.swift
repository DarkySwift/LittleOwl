//
//  CameraButton.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation

class CameraButton: UIButton {
    
    // MARK: - Properties
    
    var type: CameraType = .photo
    
    var maxDuration: Int = 10
    
    private var circleRadius: CGFloat = 0.0
    private var timer: Timer?
    
    private var circlePath: UIBezierPath {
        let startAngle: CGFloat = .pi + (.pi / 2)
        let endAngle: CGFloat = .pi * 3 + (.pi / 2)
        let centerPoint = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        return UIBezierPath(arcCenter: centerPoint, radius: frame.size.width / 2 - 2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    }
    
    private var containerLayer: CAShapeLayer?
    private var borderLayer: CAShapeLayer?
    private var borderFillLayer: CAShapeLayer?
    private var circleLayer: CAShapeLayer?
    
    var didReachMaximumDuration: (() -> Void)?
    var didBeginLongPress: (() -> Void)?
    var didEndLongPress: (() -> Void)?
    var didTap: (() -> Void)?
    
    // MARK: - Initialize
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
        setupGestures()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
    }
    
    // MARK: - Override
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer?.frame = bounds
        borderLayer?.path = circlePath.cgPath
        borderFillLayer?.frame = bounds
        borderFillLayer?.path = circlePath.cgPath
    }
    
    // MARK: - Actions
    
    @objc func longPressEvent(_ gesture: UILongPressGestureRecognizer) {
        guard case .video = type else { return }
        
        if gesture.state == .began {
            startTimer()
            startRecordingAnimation()
            didBeginLongPress?()
            
        } else if gesture.state == .ended {
            timerFinishedEvent()
            endRecordingAnimation()
            didEndLongPress?()
        }
    }
    
    @objc func tapEvent(_ gesture: UITapGestureRecognizer) {
        guard case .photo = type else { return }
        didTap?()
    }
    
    // MARK: - Methods
    
    private func setupView() {
        setupLayers()
        circleRadius = bounds.size.width * 0.5
        backgroundColor = UIColor.clear
        
        guard let borderLayer = self.borderLayer else { return }
        guard let borderFillLayer = self.borderFillLayer else { return }
        guard let containerLayer = self.containerLayer else { return }
        guard let circleLayer = self.circleLayer else { return }
        
        containerLayer.insertSublayer(borderLayer, at: 0)
        containerLayer.insertSublayer(borderFillLayer, above: borderLayer)
        layer.insertSublayer(containerLayer, at: 0)
        layer.insertSublayer(circleLayer, above: containerLayer)
    }
    
    private func setupLayers() {
        let containerLayer = CAShapeLayer()
        containerLayer.frame = bounds
        containerLayer.lineWidth = 7
        containerLayer.fillColor = UIColor.clear.cgColor
        containerLayer.strokeColor = UIColor.white.cgColor
        self.containerLayer = containerLayer
        
        let borderLayer = CAShapeLayer()
        borderLayer.frame = bounds
        borderLayer.lineWidth = 4
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        self.borderLayer = borderLayer
        
        let borderFillLayer = CAShapeLayer()
        borderFillLayer.frame = bounds
        borderFillLayer.lineWidth = 4
        borderFillLayer.fillColor = UIColor.clear.cgColor
        borderFillLayer.strokeColor = UIColor.red.cgColor
        borderFillLayer.strokeEnd = 0.0
        self.borderFillLayer = borderFillLayer
        
        let width: CGFloat = 1.0
        let height: CGFloat = width
        let circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: height), cornerRadius: 0.5).cgPath
        circleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        circleLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        circleLayer.position = CGPoint(x: frame.size.width * 0.5, y: frame.size.height * 0.5)
        circleLayer.fillColor = UIColor.red.cgColor
        self.circleLayer = circleLayer
    }
    
    private func setupGestures() {
        let longGesture = UILongPressGestureRecognizer()
        longGesture.addTarget(self, action: #selector(longPressEvent(_:)))
        addGestureRecognizer(longGesture)
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(tapEvent(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(maxDuration),
                                     target: self,
                                     selector: #selector(timerFinishedEvent),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    @objc private func timerFinishedEvent() {
        invalidateTimer()
        endRecordingAnimation()
        didReachMaximumDuration?()
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    public func startRecordingAnimation() {
        let scaleContainerAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleContainerAnimation.fromValue = 1.0
        scaleContainerAnimation.toValue = 1.37
        scaleContainerAnimation.duration = 1.4
        scaleContainerAnimation.isRemovedOnCompletion = false
        scaleContainerAnimation.fillMode = kCAFillModeForwards
        scaleContainerAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        containerLayer?.add(scaleContainerAnimation, forKey: "scaleParentAnimation")
        
        let newCircleBounds = CGRect(x: 0, y: 0, width: 2 * circleRadius * 0.82, height: 2 * circleRadius * 0.82)
        let newPath = UIBezierPath(roundedRect: newCircleBounds, cornerRadius: circleRadius)
        let circlePathAnim = CABasicAnimation(keyPath: "path")
        circlePathAnim.toValue = newPath.cgPath
        let circleBoundsAnim = CABasicAnimation(keyPath: "bounds")
        circleBoundsAnim.toValue = NSValue(cgRect: newCircleBounds)
        
        let circleGroupAnimations = CAAnimationGroup()
        circleGroupAnimations.animations = [circlePathAnim, circleBoundsAnim]
        circleGroupAnimations.isRemovedOnCompletion = false
        circleGroupAnimations.duration = 1.4
        circleGroupAnimations.fillMode = kCAFillModeForwards
        circleGroupAnimations.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        circleLayer?.add(circleGroupAnimations, forKey: "scaleCircleAnimation")
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0.0
        strokeAnimation.toValue = 1.0
        strokeAnimation.duration = CFTimeInterval(maxDuration)
        strokeAnimation.isRemovedOnCompletion = false
        strokeAnimation.fillMode = kCAFillModeForwards
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        borderFillLayer?.strokeEnd = 1.0
        borderFillLayer?.add(strokeAnimation, forKey: "strokeAnimation")
    }
    
    func endRecordingAnimation() {
        containerLayer?.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
        circleLayer?.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
        borderFillLayer?.strokeEnd = 0.0
        borderFillLayer?.pause()
        containerLayer?.pause()
        circleLayer?.pause()
    }
    
    // MARK: - Public
    
    func reset() {
        containerLayer?.removeFromSuperlayer()
        circleLayer?.removeFromSuperlayer()
        containerLayer = nil
        circleLayer = nil
        borderFillLayer = nil
        borderLayer = nil
        setupView()
    }
    
}
