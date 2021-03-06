//
//  CPKeezyView.swift
//  KeezyButtonDemo
//
//  Created by Parsifal on 2017/1/24.
//  Copyright © 2017年 Parsifal. All rights reserved.
//

import UIKit

public enum CPKeezyViewState {
    case normal
    case animating
    case zoomed
}

open class CPKeezyView: UIView {
    var touchStartTime: NSDate = NSDate()
    var isAnimating: Bool = false
    let containerView: UIView = UIView()
    var state: CPKeezyViewState = .normal
    let zoomInKey = "zoomin"
    let zoomOutKey = "zoomout"
    let rotateKey = "rotate"
    let reverseRotateKey = "reverserotate"
    let duration = 0.2
    let scaleFactor = 10.0
    let radius: CGFloat = 13
    
    // MARK: Initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        addSubview(containerView)
        containerView.frame = CGRect(x: 10, y: 10 ,width: bounds.width-20, height: bounds.height-20)
        containerView.alpha = 0
        
        // buttons
        let addBtn = createScalableBtn(image: UIImage(named: "petal_newBoard_100x100_"))
        let listBtn = createScalableBtn(image: UIImage(named: "petal_boardList_100x100_"))
        let settingBtn = createScalableBtn(image: UIImage(named: "petal_settings_100x100_"))
        let jamBtn = createScalableBtn(image: UIImage(named: "petal_jam_100x100_"))
        let deleteBtn = createScalableBtn(image: UIImage(named: "petal_deleteBoard_100x100_"))
        let undoBtn = createScalableBtn(image: UIImage(named: "petal_undo_100x100_"))
        
        // layout
        for btn: CPScalableButton in [addBtn, undoBtn, deleteBtn, jamBtn, settingBtn, listBtn] {
            containerView.addSubview(btn)
        }
        containerView.layoutSubviewsCircularly(radius: radius)
    }
    
    // MARK: - Action
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .zoomed {
            endAnimations()
        } else {
            startAnimations()
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endAnimations()
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endAnimations()
    }
    
    func startAnimations() {
        if state == .animating {
            return
        }
        
        layer.add(zoomInAnimation(reverse: false), forKey: zoomInKey)
        containerView.layer.add(rotateAnimation(reverse: false), forKey: rotateKey)
        touchStartTime = NSDate()
        state = .animating
    }
    
    func endAnimations() {
        let touchDuration = fabs(touchStartTime.timeIntervalSinceNow)
        switch state {
        case .animating where touchDuration<duration/2.0, .zoomed:
            let currentScale = layer.presentation()?.value(forKeyPath: "transform.scale")
            layer.removeAllAnimations()
            containerView.layer.removeAllAnimations()
            let scaleAnimation = zoomoutAnimation(fromValue: currentScale,
                                                  toValue: 1)
            layer.add(scaleAnimation, forKey: zoomOutKey)
            containerView.layer.add(rotateAnimation(reverse: true), forKey: reverseRotateKey)
            state = .normal
        case .animating where touchDuration>=duration/2.0:
            state = .zoomed
        default:
            break
        }
    }
    
    // MARK: Getter
    func zoomInAnimation(reverse: Bool) -> CAAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = reverse ? scaleFactor : 1.0
        scaleAnimation.toValue = reverse ? 1.0 : scaleFactor
        scaleAnimation.isRemovedOnCompletion = false
        scaleAnimation.fillMode = kCAFillModeForwards
        scaleAnimation.duration = duration
        scaleAnimation.repeatCount = 1
        scaleAnimation.delegate = self
        return scaleAnimation
    }
    
    func rotateAnimation(reverse: Bool) -> CAAnimation {
        // rotate 2*arc
        let arc = M_PI//(2.0*M_PI/Double(containerView.subviews.count))*2.0
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnimation.fromValue = reverse ? arc : 0
        rotateAnimation.toValue = reverse ? 0 : arc
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = reverse ? 1.0 : 0
        opacityAnimation.toValue = reverse ? 0 : 1.0
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.isRemovedOnCompletion = reverse ? true : false
        groupAnimation.fillMode = reverse ? kCAFillModeRemoved : kCAFillModeForwards
        groupAnimation.duration = duration+0.1
        groupAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        groupAnimation.animations = [rotateAnimation, opacityAnimation]
        groupAnimation.delegate = self
        return groupAnimation
    }
    
    func zoomoutAnimation(fromValue: Any?, toValue: Any?) -> CAAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = fromValue
        scaleAnimation.toValue = toValue
        scaleAnimation.isRemovedOnCompletion = true
        scaleAnimation.fillMode = kCAFillModeRemoved
        scaleAnimation.duration = duration
        scaleAnimation.delegate = self
        return scaleAnimation
    }
    
    func createScalableBtn(image: UIImage?) -> CPScalableButton {
        let btn = CPScalableButton(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        btn.setImage(image, for: .normal)
        return btn
    }
}

extension CPKeezyView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag && anim==containerView.layer.animation(forKey: rotateKey) {
            transform = CGAffineTransform(scaleX: CGFloat(scaleFactor), y: CGFloat(scaleFactor))
            containerView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
            containerView.alpha = 1
        }
    }
    
    public func animationDidStart(_ anim: CAAnimation) {
        if anim==layer.animation(forKey: zoomOutKey) {
            transform = CGAffineTransform.identity
            containerView.transform = CGAffineTransform.identity
            containerView.alpha = 0
        }
    }
}

extension UIView {
    open func layoutSubviewsCircularly(radius: CGFloat) {
        let center = CGPoint(x: bounds.width/2, y: bounds.height/2)
        let arc:CGFloat = CGFloat(M_PI)*2.0/CGFloat(subviews.count)
        
        for index in 0..<subviews.count {
            let view: UIView = subviews[index]
            let currentArc = CGFloat(index)*arc
            view.center = CGPoint(x: center.x+radius*sin(currentArc), y: center.y+radius*cos(currentArc))
        }
    }
}
