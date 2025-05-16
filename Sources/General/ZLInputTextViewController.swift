//
//  ZLInputTextViewController.swift
//  ZLImageEditor
//
//  Created by long on 2020/10/30.
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

class ZLInputTextViewController: UIViewController {
    private static let toolViewHeight: CGFloat = 250
    
    private let image: UIImage?
    
    private var text: String
    
    private var fontSize: CGFloat = ZLImageEditorConfiguration().defaultFontSize

    private var font: UIFont = .boldSystemFont(ofSize: ZLImageEditorConfiguration().defaultFontSize)
    
    private var textColor: UIColor {
        didSet {
            refreshTextViewUI()
        }
    }
    
    private var fillColor: UIColor {
        didSet {
            refreshTextViewUI()
        }
    }
    
    private var currentIsBold: Bool = false
    private var currentIsItalic: Bool = false
    private var baseFontName: String = ZLImageEditorConfiguration.default().textStickerDefaultFont?.fontName ?? UIFont.systemFont(ofSize: 1).fontName
        
    private lazy var bgImageView: UIImageView = {
        let view = UIImageView(image: image?.zl.blurImage(level: 4))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var coverView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.4
        return view
    }()
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(localLanguageTextValue(.cancel), for: .normal)
        btn.titleLabel?.font = ZLImageEditorLayout.bottomToolTitleFont
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(localLanguageTextValue(.done), for: .normal)
        btn.setTitleColor(.zl.editDoneBtnTitleColor, for: .normal)
        btn.backgroundColor = .zl.editDoneBtnBgColor
        btn.titleLabel?.font = ZLImageEditorLayout.bottomToolTitleFont
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = ZLImageEditorLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.keyboardAppearance = .dark
        textView.returnKeyType = ZLImageEditorConfiguration.default().textStickerCanLineBreak ? .continue : .default
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.tintColor = textColor
        textView.textColor = textColor
        textView.text = text
        textView.font = font
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.delegate = self
        return textView
    }()
    
    private lazy var toolView = UIView()
    
    private lazy var textColorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 36, height: 36)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let inset = (Self.toolViewHeight - layout.itemSize.height) / 2
        layout.sectionInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        ZLDrawColorCell.zl.register(collectionView)
        
        return collectionView
    }()
    
    private lazy var fillColorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 36, height: 36)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let inset = (Self.toolViewHeight - layout.itemSize.height) / 2
        layout.sectionInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        ZLDrawColorCell.zl.register(collectionView)
        
        return collectionView
    }()
    
    private var textInputStyleView: ZLTextInputStyleView = ZLTextInputStyleView()
    
    private var shouldLayout = true
    
    private lazy var textLayer = CAShapeLayer()
    
    private let textLayerRadius: CGFloat = 10
    
    private let maxTextCount = 100
    
    /// text, textColor, font, image, style
    var endInput: ((String, UIColor, UIFont, UIImage?, UIColor, CGFloat) -> Void)?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    init(image: UIImage?, text: String? = nil, font: UIFont? = nil, textColor: UIColor? = nil, fillColor: UIColor? = nil, fontSize: CGFloat? = nil) {
        self.image = image
        self.text = text ?? ""
        if let fontSize = fontSize {
            self.fontSize = fontSize
        }
        if let font = font {
            self.font = font.withSize(self.fontSize)
        }
        if let textColor = textColor {
            self.textColor = textColor
        } else {
            if !ZLImageEditorConfiguration.default().textStickerTextColors.contains(ZLImageEditorConfiguration.default().textStickerDefaultTextColor) {
                self.textColor = ZLImageEditorConfiguration.default().textStickerTextColors.first!
            } else {
                self.textColor = ZLImageEditorConfiguration.default().textStickerDefaultTextColor
            }
        }
        if let fillColor = fillColor {
            self.fillColor = fillColor
        } else {
            self.fillColor = .clear
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard shouldLayout else { return }
        
        shouldLayout = false
        bgImageView.frame = view.bounds
        
        // iPad图片由竖屏切换到横屏时候填充方式会有点异常，这里重置下
        if deviceIsiPad() {
            if UIApplication.shared.statusBarOrientation.isLandscape {
                bgImageView.contentMode = .scaleAspectFill
            } else {
                bgImageView.contentMode = .scaleAspectFit
            }
        }
        
        coverView.frame = bgImageView.bounds
        
        let btnY = max(deviceSafeAreaInsets().top, 20) + 20
        let cancelBtnW = localLanguageTextValue(.cancel).zl.boundingRect(font: ZLImageEditorLayout.bottomToolTitleFont, limitSize: CGSize(width: .greatestFiniteMagnitude, height: ZLImageEditorLayout.bottomToolBtnH)).width + 20
        cancelBtn.frame = CGRect(x: 15, y: btnY, width: cancelBtnW, height: ZLImageEditorLayout.bottomToolBtnH)
        
        let doneBtnW = localLanguageTextValue(.done).zl.boundingRect(font: ZLImageEditorLayout.bottomToolTitleFont, limitSize: CGSize(width: .greatestFiniteMagnitude, height: ZLImageEditorLayout.bottomToolBtnH)).width + 20
        doneBtn.frame = CGRect(x: view.zl.width - 20 - doneBtnW, y: btnY, width: doneBtnW, height: ZLImageEditorLayout.bottomToolBtnH)
        
        textView.frame = CGRect(x: 10, y: doneBtn.zl.bottom + 30, width: view.zl.width - 20, height: 200)
    
        textColorCollectionView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.zl.width,
            height: Self.toolViewHeight
        )
        
        if let index = ZLImageEditorConfiguration.default().textStickerTextColors.firstIndex(where: { $0 == self.textColor }) {
            textColorCollectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    func setupUI() {
        let initialFont = self.font
         let initialDescriptor = initialFont.fontDescriptor
         let initialTraits = initialDescriptor.symbolicTraits
         currentIsBold = initialTraits.contains(.traitBold)
         currentIsItalic = initialTraits.contains(.traitItalic)
        
        
        view.backgroundColor = .black
        
        view.addSubview(bgImageView)
        bgImageView.addSubview(coverView)
        
        view.addSubview(cancelBtn)
        view.addSubview(doneBtn)
        view.addSubview(textView)
        view.addSubview(toolView)
        
        textView.tintColor = textColor
                
        textInputStyleView.setInitialStyle(
            textColor: self.textColor, // Existing property
            fillColor: self.fillColor, // Existing property (from previous file)
            fontSize: self.fontSize,
            isBold: currentIsBold,
            isItalic: currentIsItalic
        )
        textInputStyleView.delegate = self
        textInputStyleView.translatesAutoresizingMaskIntoConstraints = false
        toolView.addSubview(textInputStyleView)
        
        NSLayoutConstraint.activate([
            textInputStyleView.leadingAnchor.constraint(equalTo: toolView.leadingAnchor, constant: 0),
            textInputStyleView.trailingAnchor.constraint(equalTo: toolView.trailingAnchor, constant: 0),
            textInputStyleView.topAnchor.constraint(equalTo: toolView.topAnchor, constant: 0),
            textInputStyleView.bottomAnchor.constraint(equalTo: toolView.bottomAnchor, constant: 0),
        ])
        
        textView.textAlignment = .left
        
        refreshTextViewUI()
    }
    
    private func applyFontChanges() {
        var newFontDescriptor = UIFontDescriptor(name: baseFontName, size: self.fontSize)
        var symbolicTraits = newFontDescriptor.symbolicTraits
        
        if currentIsBold {
            symbolicTraits.insert(.traitBold)
        } else {
            symbolicTraits.remove(.traitBold)
        }
        
        if currentIsItalic {
            symbolicTraits.insert(.traitItalic)
        } else {
            symbolicTraits.remove(.traitItalic)
        }
        
        if let finalDescriptor = newFontDescriptor.withSymbolicTraits(symbolicTraits) {
            self.font = UIFont(descriptor: finalDescriptor, size: self.fontSize)
        } else {
            // Fallback if descriptor with traits fails
            // Try to create a system font with traits
            var systemFont = UIFont.systemFont(ofSize: self.fontSize)
            if currentIsBold && currentIsItalic {
                 systemFont = UIFont.systemFont(ofSize: self.fontSize, weight: .bold)
                 if let descriptor = systemFont.fontDescriptor.withSymbolicTraits(.traitItalic) {
                     self.font = UIFont(descriptor: descriptor, size: self.fontSize)
                 } else {
                     self.font = systemFont // At least bold
                 }
            } else if currentIsBold {
                self.font = UIFont.systemFont(ofSize: self.fontSize, weight: .bold)
            } else if currentIsItalic {
                 if let descriptor = systemFont.fontDescriptor.withSymbolicTraits(.traitItalic) {
                     self.font = UIFont(descriptor: descriptor, size: self.fontSize)
                 } else {
                     self.font = systemFont // Plain system
                 }
            } else {
                self.font = systemFont // Plain system
            }
        }
        
        textView.font = self.font
        // If text layout might change significantly (e.g., due to bold/italic width changes)
        // you might need to call drawTextBackground() or similar layout-dependent methods.
        // For now, just updating font.
        drawTextBackground() // Re-draw background as text metrics change
    }

    
    private func refreshTextViewUI() {
        drawTextBackground()
        textView.textColor = self.textColor
    }

    @objc func cancelBtnClick() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneBtnClick() {
        textView.tintColor = .clear
        textView.resignFirstResponder()
        
        var image: UIImage?
        
        if !textView.text.isEmpty {
            for subview in textView.subviews {
                if NSStringFromClass(subview.classForCoder) == "_UITextContainerView" {
                    let size = textView.sizeThatFits(subview.frame.size)
                    image = UIGraphicsImageRenderer.zl.renderImage(size: size) { context in
                        textLayer.render(in: context)
                        subview.layer.render(in: context)
                    }
                }
            }
        }
        
        endInput?(textView.text, textColor, font, image, fillColor, fontSize)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func keyboardWillShow(_ notify: Notification) {
        let rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardH = rect?.height ?? 366
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let toolViewFrame = CGRect(
            x: 0,
            y: view.zl.height - keyboardH - Self.toolViewHeight,
            width: view.zl.width,
            height: Self.toolViewHeight
        )
        
        var textViewFrame = textView.frame
        textViewFrame.size.height = toolViewFrame.minY - textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.toolView.frame = toolViewFrame
            self.textView.frame = textViewFrame
        }
    }
    
    @objc private func keyboardWillHide(_ notify: Notification) {
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let toolViewFrame = CGRect(
            x: 0,
            y: view.zl.height - deviceSafeAreaInsets().bottom - Self.toolViewHeight,
            width: view.zl.width,
            height: Self.toolViewHeight
        )
        
        var textViewFrame = textView.frame
        textViewFrame.size.height = toolViewFrame.minY - textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.toolView.frame = toolViewFrame
            self.textView.frame = textViewFrame
        }
    }
}

extension ZLInputTextViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ZLImageEditorConfiguration.default().textStickerTextColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawColorCell.zl.identifier, for: indexPath) as! ZLDrawColorCell
        
        let c = ZLImageEditorConfiguration.default().textStickerTextColors[indexPath.row]
        cell.color = c
        if c == textColor {
            cell.bgWhiteView.layer.transform = CATransform3DMakeScale(1.33, 1.33, 1)
            cell.colorView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
        } else {
            cell.bgWhiteView.layer.transform = CATransform3DIdentity
            cell.colorView.layer.transform = CATransform3DIdentity
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        textColor = ZLImageEditorConfiguration.default().textStickerTextColors[indexPath.row]
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
    }
}

// MARK: Draw text layer

extension ZLInputTextViewController {
    private func drawTextBackground() {
        guard !textView.text.isEmpty else {
            textLayer.removeFromSuperlayer()
            return
        }
        
        let rects = calculateTextRects()
        
        let path = UIBezierPath()
        for (index, rect) in rects.enumerated() {
            if index == 0 {
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + textLayerRadius))
                path.addArc(withCenter: CGPoint(x: rect.minX + textLayerRadius, y: rect.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
                path.addLine(to: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY))
                path.addArc(withCenter: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
            } else {
                let preRect = rects[index - 1]
                if rect.maxX > preRect.maxX {
                    path.addLine(to: CGPoint(x: preRect.maxX, y: rect.minY - textLayerRadius))
                    path.addArc(withCenter: CGPoint(x: preRect.maxX + textLayerRadius, y: rect.minY - textLayerRadius), radius: textLayerRadius, startAngle: -.pi, endAngle: -.pi * 1.5, clockwise: false)
                    path.addLine(to: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY))
                    path.addArc(withCenter: CGPoint(x: rect.maxX - textLayerRadius, y: rect.minY + textLayerRadius), radius: textLayerRadius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
                } else if rect.maxX < preRect.maxX {
                    path.addLine(to: CGPoint(x: preRect.maxX, y: preRect.maxY - textLayerRadius))
                    path.addArc(withCenter: CGPoint(x: preRect.maxX - textLayerRadius, y: preRect.maxY - textLayerRadius), radius: textLayerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                    path.addLine(to: CGPoint(x: rect.maxX + textLayerRadius, y: preRect.maxY))
                    path.addArc(withCenter: CGPoint(x: rect.maxX + textLayerRadius, y: preRect.maxY + textLayerRadius), radius: textLayerRadius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
                } else {
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + textLayerRadius))
                }
            }
            
            if index == rects.count - 1 {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - textLayerRadius))
                path.addArc(withCenter: CGPoint(x: rect.maxX - textLayerRadius, y: rect.maxY - textLayerRadius), radius: textLayerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                path.addLine(to: CGPoint(x: rect.minX + textLayerRadius, y: rect.maxY))
                path.addArc(withCenter: CGPoint(x: rect.minX + textLayerRadius, y: rect.maxY - textLayerRadius), radius: textLayerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
                
                let firstRect = rects[0]
                path.addLine(to: CGPoint(x: firstRect.minX, y: firstRect.minY + textLayerRadius))
                path.close()
            }
        }
        
        textLayer.path = path.cgPath
        textLayer.fillColor = fillColor.cgColor
        if textLayer.superlayer == nil {
            textView.layer.insertSublayer(textLayer, at: 0)
        }
    }
    
    private func calculateTextRects() -> [CGRect] {
        let layoutManager = textView.layoutManager
        
        let range = layoutManager.glyphRange(forCharacterRange: NSMakeRange(0, textView.text.utf16.count), actualCharacterRange: nil)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        
        var rects: [CGRect] = []
        
        let insetLeft = textView.textContainerInset.left
        let insetTop = textView.textContainerInset.top
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, range, _ in
            rects.append(CGRect(x: usedRect.minX - 10 + insetLeft, y: usedRect.minY - 8 + insetTop, width: usedRect.width + 20, height: usedRect.height + 16))
        }
        
        guard rects.count > 1 else {
            return rects
        }
        
        for i in 1..<rects.count {
            processRects(&rects, index: i, maxIndex: i)
        }
        
        return rects
    }
    
    private func processRects(_ rects: inout [CGRect], index: Int, maxIndex: Int) {
        guard rects.count > 1, index > 0, index <= maxIndex else {
            return
        }
        
        var preRect = rects[index - 1]
        var currRect = rects[index]
        
        var preChanged = false
        var currChanged = false
        
        // 当前rect宽度大于上方的rect，但差值小于2倍圆角
        if currRect.width > preRect.width, currRect.width - preRect.width < 2 * textLayerRadius {
            var size = preRect.size
            size.width = currRect.width
            preRect = CGRect(origin: preRect.origin, size: size)
            preChanged = true
        }
        
        if currRect.width < preRect.width, preRect.width - currRect.width < 2 * textLayerRadius {
            var size = currRect.size
            size.width = preRect.width
            currRect = CGRect(origin: currRect.origin, size: size)
            currChanged = true
        }
        
        if preChanged {
            rects[index - 1] = preRect
            processRects(&rects, index: index - 1, maxIndex: maxIndex)
        }
        
        if currChanged {
            rects[index] = currRect
            processRects(&rects, index: index + 1, maxIndex: maxIndex)
        }
    }
}

extension ZLInputTextViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let markedTextRange = textView.markedTextRange
        guard markedTextRange == nil || (markedTextRange?.isEmpty ?? true) else {
            return
        }
        
        let text = textView.text ?? ""
        if text.count > maxTextCount {
            let endIndex = text.index(text.startIndex, offsetBy: maxTextCount)
            textView.text = String(text[..<endIndex])
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !ZLImageEditorConfiguration.default().textStickerCanLineBreak && text == "\n" {
            doneBtnClick()
            return false
        }
        return true
    }
}

extension ZLInputTextViewController: NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard layoutFinishedFlag else {
            return
        }
        
        drawTextBackground()
    }
}

extension ZLInputTextViewController: ZLTextInputStyleViewDelegate {
    func didSelectFontStyle(isBold: Bool, isItalic: Bool) {
        self.currentIsBold = isBold
         self.currentIsItalic = isItalic
         applyFontChanges()
    }
    
    func didSelectTextColor(_ color: UIColor) {
        self.textColor = color
        self.textView.tintColor = color
        refreshTextViewUI()
    }
    
    func didSelectFillColor(_ color: UIColor) {
        self.fillColor = color
        refreshTextViewUI()
    }
    
    func didSelectFontSize(_ fontSize: CGFloat) {
        self.fontSize = fontSize
        applyFontChanges()
    }
    
    
}
