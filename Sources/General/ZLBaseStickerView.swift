//
//  ZLBaseStickerView.swift
//  ZLImageEditor
//
//  Created by long on 2023/2/6.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

protocol ZLStickerViewDelegate: NSObject {
    /// Called when scale or rotate or move.
    func stickerBeginOperation(_ sticker: ZLBaseStickerView)
    
    /// Called during scale or rotate or move.
    func stickerOnOperation(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called after scale or rotate or move.
    func stickerEndOperation(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer)
    
    /// Called when tap sticker.
    func stickerDidTap(_ sticker: ZLBaseStickerView)
    
    func sticker(_ textSticker: ZLTextStickerView, editText text: String)
}

protocol ZLStickerViewAdditional: NSObject {
    var gesIsEnabled: Bool { get set }
    
    func resetState()
    
    func remove()
    
    func addScale(_ scale: CGFloat)
}

class ZLBaseStickerView: UIView, UIGestureRecognizerDelegate {
    private enum Direction: Int {
        case up = 0
        case right = 90
        case bottom = 180
        case left = 270
    }
    
    var id: String
    
    var borderWidth = 1 / UIScreen.main.scale
    
    var firstLayout = true
    
    let originScale: CGFloat
    
    let originAngle: CGFloat
    
    var maxGesScale: CGFloat
    
    var originTransform: CGAffineTransform = .identity
        
    var totalTranslationPoint: CGPoint = .zero
    
    var gesTranslationPoint: CGPoint = .zero
    
    var gesRotation: CGFloat = 0
    
    var gesScale: CGFloat = 1
    
    var onOperation = false
    
    var gesIsEnabled = true
    
    var originFrame: CGRect
    
    lazy var tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
    
    lazy var pinchGes: UIPinchGestureRecognizer = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        pinch.delegate = self
        return pinch
    }()
    
    lazy var rotationGes: UIRotationGestureRecognizer = {
        let g = UIRotationGestureRecognizer(target: self, action: #selector(rotationAction(_:)))
        g.delegate = self
        return g
    }()
    
    lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        pan.delegate = self
        return pan
    }()
    
    var state: ZLBaseStickertState {
        fatalError()
    }
    
    var borderView: UIView {
        return self
    }
    
    weak var delegate: ZLStickerViewDelegate?

    private let handleSize: CGFloat = 14
    private let rotateHandleSize: CGFloat = 20
    private let handleLineWidth: CGFloat = 1
    private let rotateHandleOffset: CGFloat = 24
    private lazy var handlesContainer: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = true
        v.isHidden = true
        return v
    }()
    private lazy var cornerHandles: [UIView] = {
        return (0..<4).map { _ in
            let v = ZLEnlargeButton(type: .custom)
            v.backgroundColor = .white
            v.layer.borderColor = UIColor.zl.toolTitleTintColor.cgColor
            v.layer.borderWidth = handleLineWidth
            v.layer.cornerRadius = handleSize/2
            v.layer.masksToBounds = true
            v.enlargeInset = 10
            let pan = UIPanGestureRecognizer(target: self, action: #selector(cornerPanAction(_:)))
            pan.delegate = self
            v.addGestureRecognizer(pan)
            return v
        }
    }()
    private lazy var rotateHandle: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_rotateimage"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 10
        let pan = UIPanGestureRecognizer(target: self, action: #selector(rotateHandlePan(_:)))
        btn.addGestureRecognizer(pan)
        return btn
    }()
    private var currentCornerInfo: (unit: CGPoint, baseDistance: CGFloat, centerInSuper: CGPoint, startGesScale: CGFloat)?
    private var lastRotateAngle: CGFloat?
    
    class func initWithState(_ state: ZLBaseStickertState) -> ZLBaseStickerView? {
        if let state = state as? ZLTextStickerState {
            return ZLTextStickerView(state: state)
        } else if let state = state as? ZLImageStickerState {
            return ZLImageStickerView(state: state)
        } else if let state = state as? ZLLineState { // Check this case
            return ZLLineView(state: state)          // Check return type
        } else if let state = state as? ZLArrowState { // Check this case
            return ZLArrowView(state: state)         // Check return type
        } else if let state = state as? ZLShapeState { // Check this case
            return ZLShapeView(state: state)         // Check return type
        } else if let state = state as? ZLFreehandDrawState { // Add this
            return ZLFreehandDrawView(state: state)
        } else {
            zl_debugPrint("⚠️ Unknown sticker state type encountered in initWithState: \(type(of: state))")
            return nil // Returning nil is safer than crashing if state is unknown
        }
    }
    
    init(
        id: String = UUID().uuidString,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat = 1,
        gesRotation: CGFloat = 0,
        totalTranslationPoint: CGPoint = .zero,
        showBorder: Bool = true
    ) {
        self.id = id
        self.originScale = originScale
        self.originAngle = originAngle
        self.originFrame = originFrame
        maxGesScale = 4 / originScale
        super.init(frame: .zero)

        self.gesScale = gesScale
        self.gesRotation = gesRotation
        self.totalTranslationPoint = totalTranslationPoint
        
        borderView.layer.borderWidth = borderWidth
        hideBorder()
        
        addGestureRecognizer(tapGes)
        addGestureRecognizer(pinchGes)
        
        addGestureRecognizer(rotationGes)
        
        addGestureRecognizer(panGes)
        tapGes.require(toFail: panGes)

        cornerHandles.forEach { handlesContainer.addSubview($0) }
        handlesContainer.addSubview(rotateHandle)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        guard firstLayout else {
            return
        }
        
        // Rotate must be first when first layout.
        transform = transform.rotated(by: originAngle.zl.toPi)
        
        if totalTranslationPoint != .zero {
            let direction = direction(for: originAngle)
            if direction == .right {
                transform = transform.translatedBy(x: totalTranslationPoint.y, y: -totalTranslationPoint.x)
            } else if direction == .bottom {
                transform = transform.translatedBy(x: -totalTranslationPoint.x, y: -totalTranslationPoint.y)
            } else if direction == .left {
                transform = transform.translatedBy(x: -totalTranslationPoint.y, y: totalTranslationPoint.x)
            } else {
                transform = transform.translatedBy(x: totalTranslationPoint.x, y: totalTranslationPoint.y)
            }
        }
        
        transform = transform.scaledBy(x: originScale, y: originScale)
        
        originTransform = transform
        
        if gesScale != 1 {
            transform = transform.scaledBy(x: gesScale, y: gesScale)
        }
        if gesRotation != 0 {
            transform = transform.rotated(by: gesRotation)
        }
        
        firstLayout = false
        setupUIFrameWhenFirstLayout()

        layoutHandles()
    }
    
    func setupUIFrameWhenFirstLayout() {}

    private func layoutHandles() {
        guard let sp = superview else { return }
        if handlesContainer.superview !== sp {
            handlesContainer.removeFromSuperview()
            sp.addSubview(handlesContainer)
            sp.bringSubviewToFront(handlesContainer)
        }
        handlesContainer.frame = sp.bounds

        let tl = convert(CGPoint(x: 0, y: 0), to: sp)
        let tr = convert(CGPoint(x: bounds.width, y: 0), to: sp)
        let bl = convert(CGPoint(x: 0, y: bounds.height), to: sp)
        let br = convert(CGPoint(x: bounds.width, y: bounds.height), to: sp)
        let topMid = convert(CGPoint(x: bounds.midX, y: 0), to: sp)
        let center = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: sp)

        let size = CGSize(width: handleSize, height: handleSize)
        cornerHandles[0].frame = CGRect(x: tl.x - handleSize/2, y: tl.y - handleSize/2, width: size.width, height: size.height)
        cornerHandles[1].frame = CGRect(x: tr.x - handleSize/2, y: tr.y - handleSize/2, width: size.width, height: size.height)
        cornerHandles[2].frame = CGRect(x: bl.x - handleSize/2, y: bl.y - handleSize/2, width: size.width, height: size.height)
        cornerHandles[3].frame = CGRect(x: br.x - handleSize/2, y: br.y - handleSize/2, width: size.width, height: size.height)

        var dir = CGPoint(x: topMid.x - center.x, y: topMid.y - center.y)
        let len = max(0.0001, sqrt(dir.x*dir.x + dir.y*dir.y))
        dir.x /= len; dir.y /= len
        let pos = CGPoint(x: topMid.x + dir.x * rotateHandleOffset, y: topMid.y + dir.y * rotateHandleOffset)
        rotateHandle.frame = CGRect(x: pos.x - rotateHandleSize/2, y: pos.y - rotateHandleSize/2, width: rotateHandleSize, height: rotateHandleSize)
    }

    private func currentVisualScale() -> (x: CGFloat, y: CGFloat) {
        let t = self.transform
        let sx = sqrt(t.a * t.a + t.c * t.c)
        let sy = sqrt(t.b * t.b + t.d * t.d)
        return (sx, sy)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return super.point(inside: point, with: event)
    }
    
    private func direction(for angle: CGFloat) -> ZLBaseStickerView.Direction {
        // 将角度转换为0~360，并对360取余
        let angle = ((Int(angle) % 360) + 360) % 360
        return ZLBaseStickerView.Direction(rawValue: angle) ?? .up
    }
    
    @objc func tapAction(_ ges: UITapGestureRecognizer) {
        guard gesIsEnabled else { return }
        showBorder()
        delegate?.stickerDidTap(self)
    }
    
    @objc func pinchAction(_ ges: UIPinchGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        let scale = min(maxGesScale, gesScale * ges.scale)
        ges.scale = 1
        
        var scaleChanged = false
        if scale != gesScale {
            gesScale = scale
            scaleChanged = true
        }
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            if scaleChanged {
                updateTransform()
            }
        } else if ges.state == .ended || ges.state == .cancelled {
            // 当有拖动时，在panAction中执行setOperation(false)
            if gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func rotationAction(_ ges: UIRotationGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        gesRotation += ges.rotation
        ges.rotation = 0
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            updateTransform()
        } else if ges.state == .ended || ges.state == .cancelled {
            if gesTranslationPoint == .zero {
                setOperation(false)
            }
        }
    }
    
    @objc func panAction(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled else { return }
        
        let point = ges.translation(in: superview)
        gesTranslationPoint = CGPoint(x: point.x / originScale, y: point.y / originScale)
        
        if ges.state == .began {
            setOperation(true)
        } else if ges.state == .changed {
            updateTransform()
        } else if ges.state == .ended || ges.state == .cancelled {
            totalTranslationPoint.x += point.x
            totalTranslationPoint.y += point.y
            setOperation(false)
            let direction = direction(for: originAngle)
            if direction == .right {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.y, y: -gesTranslationPoint.x)
            } else if direction == .bottom {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.x, y: -gesTranslationPoint.y)
            } else if direction == .left {
                originTransform = originTransform.translatedBy(x: -gesTranslationPoint.y, y: gesTranslationPoint.x)
            } else {
                originTransform = originTransform.translatedBy(x: gesTranslationPoint.x, y: gesTranslationPoint.y)
            }
            gesTranslationPoint = .zero
        }
    }
    
    func setOperation(_ isOn: Bool) {
        if isOn, !onOperation {
            onOperation = true
            borderView.layer.borderColor = UIColor.white.cgColor
            delegate?.stickerBeginOperation(self)
        } else if !isOn, onOperation {
            onOperation = false
            delegate?.stickerEndOperation(self, panGes: panGes)
        }
    }
    
    func updateTransform() {
        var transform = originTransform

        let direction = direction(for: originAngle)
        if direction == .right {
            transform = transform.translatedBy(x: gesTranslationPoint.y, y: -gesTranslationPoint.x)
        } else if direction == .bottom {
            transform = transform.translatedBy(x: -gesTranslationPoint.x, y: -gesTranslationPoint.y)
        } else if direction == .left {
            transform = transform.translatedBy(x: -gesTranslationPoint.y, y: gesTranslationPoint.x)
        } else {
            transform = transform.translatedBy(x: gesTranslationPoint.x, y: gesTranslationPoint.y)
        }
        // Scale must after translate.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Rotate must after scale.
        transform = transform.rotated(by: gesRotation)
        self.transform = transform
        
        delegate?.stickerOnOperation(self, panGes: panGes)
        layoutHandles()
    }
    
    @objc public func showBorder() {
        borderView.layer.borderColor = UIColor.white.cgColor
        handlesContainer.isHidden = false
    }
    
    @objc public func hideBorder() {
        borderView.layer.borderColor = UIColor.clear.cgColor
        handlesContainer.isHidden = true
    }
    
    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let isHandleGes = cornerHandles.contains(where: { $0.gestureRecognizers?.contains(gestureRecognizer) == true }) || rotateHandle.gestureRecognizers?.contains(gestureRecognizer) == true
        let isOtherHandleGes = cornerHandles.contains(where: { $0.gestureRecognizers?.contains(otherGestureRecognizer) == true }) || rotateHandle.gestureRecognizers?.contains(otherGestureRecognizer) == true
        if isHandleGes || isOtherHandleGes {
            return false
        }
        return true
    }
}

extension ZLBaseStickerView: ZLStickerViewAdditional {
    func resetState() {
        onOperation = false
        hideBorder()
    }
    
    func remove() {
        handlesContainer.removeFromSuperview()
        removeFromSuperview()
    }
    
    func updateScale(_ scale: CGFloat) {
        var origin = frame.origin
        origin.x *= scale
        origin.y *= scale
        
        let newSize = CGSize(width: frame.width * scale, height: frame.height * scale)
        let diffX: CGFloat = (origin.x - frame.origin.x)
        let diffY: CGFloat = (origin.y - frame.origin.y)
                
        transform = transform.scaledBy(x: scale, y: scale)
        transform = transform.translatedBy(x: diffX, y: diffY)
        frame.origin = origin
        frame.size = newSize
    }

    func addScale(_ scale: CGFloat) {
        // Revert zoom scale.
        transform = transform.scaledBy(x: 1 / originScale, y: 1 / originScale)
        // Revert ges scale.
        transform = transform.scaledBy(x: 1 / gesScale, y: 1 / gesScale)
        // Revert ges rotation.
        transform = transform.rotated(by: -gesRotation)
        
        var origin = frame.origin
        origin.x *= scale
        origin.y *= scale
        
        let newSize = CGSize(width: frame.width * scale, height: frame.height * scale)
        let newOrigin = CGPoint(x: frame.minX + (frame.width - newSize.width) / 2, y: frame.minY + (frame.height - newSize.height) / 2)
        let diffX: CGFloat = (origin.x - newOrigin.x)
        let diffY: CGFloat = (origin.y - newOrigin.y)
        
        let direction = direction(for: originAngle)
        if direction == .right {
            transform = transform.translatedBy(x: diffY, y: -diffX)
            originTransform = originTransform.translatedBy(x: diffY / originScale, y: -diffX / originScale)
        } else if direction == .bottom {
            transform = transform.translatedBy(x: -diffX, y: -diffY)
            originTransform = originTransform.translatedBy(x: -diffX / originScale, y: -diffY / originScale)
        } else if direction == .left {
            transform = transform.translatedBy(x: -diffY, y: diffX)
            originTransform = originTransform.translatedBy(x: -diffY / originScale, y: diffX / originScale)
        } else {
            transform = transform.translatedBy(x: diffX, y: diffY)
            originTransform = originTransform.translatedBy(x: diffX / originScale, y: diffY / originScale)
        }
        totalTranslationPoint.x += diffX
        totalTranslationPoint.y += diffY
        
        transform = transform.scaledBy(x: scale, y: scale)
        
        // Readd zoom scale.
        transform = transform.scaledBy(x: originScale, y: originScale)
        // Readd ges scale.
        transform = transform.scaledBy(x: gesScale, y: gesScale)
        // Readd ges rotation.
        transform = transform.rotated(by: gesRotation)
        
        gesScale *= scale
        maxGesScale *= scale
    }

    @objc private func cornerPanAction(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled else { return }
        let superV = superview ?? self
        if ges.state == .began {
            setOperation(true)
            let center = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: superV)
            var corner = center
            if let idx = cornerHandles.firstIndex(where: { $0 === ges.view }) {
                switch idx {
                case 0: corner = convert(CGPoint(x: 0, y: 0), to: superV)
                case 1: corner = convert(CGPoint(x: bounds.width, y: 0), to: superV)
                case 2: corner = convert(CGPoint(x: 0, y: bounds.height), to: superV)
                default: corner = convert(CGPoint(x: bounds.width, y: bounds.height), to: superV)
                }
            } else {
                corner = ges.view.map { convert(CGPoint(x: $0.frame.midX, y: $0.frame.midY), to: superV) } ?? center
            }
            var u = CGPoint(x: corner.x - center.x, y: corner.y - center.y)
            let d = max(1, sqrt(u.x*u.x + u.y*u.y))
            u.x /= d; u.y /= d
            currentCornerInfo = (u, d, center, gesScale)
        } else if ges.state == .changed {
            guard let info = currentCornerInfo else { return }
            let t = ges.translation(in: superV)
            let dot = info.unit.x * t.x + info.unit.y * t.y
            let factor = 1 + dot / max(20, info.baseDistance)
            let targetScale = min(maxGesScale, max(0.2, gesScale * factor))
            if targetScale != gesScale {
                gesScale = targetScale
                updateTransform()
                layoutHandles()
            }
            ges.setTranslation(.zero, in: superV)
        } else if ges.state == .ended || ges.state == .cancelled {
            setOperation(false)
            currentCornerInfo = nil
        }
    }

    @objc private func rotateHandlePan(_ ges: UIPanGestureRecognizer) {
        guard gesIsEnabled else { return }
        let superV = superview ?? self
        let centerInSuper = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: superV)
        let loc = ges.location(in: superV)
        let angle = atan2(loc.y - centerInSuper.y, loc.x - centerInSuper.x)
        if ges.state == .began {
            setOperation(true)
            lastRotateAngle = angle
        } else if ges.state == .changed {
            guard let last = lastRotateAngle else { return }
            var delta = angle - last
            // Normalize delta to [-pi, pi]
            if delta > .pi { delta -= 2 * .pi } else if delta < -.pi { delta += 2 * .pi }
            gesRotation += delta
            lastRotateAngle = angle
            updateTransform()
        } else if ges.state == .ended || ges.state == .cancelled {
            setOperation(false)
            lastRotateAngle = nil
        }
    }
}
