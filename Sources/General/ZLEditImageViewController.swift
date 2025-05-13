//
//  ZLEditImageViewController.swift
//  ZLImageEditor
//
//  Created by long on 2020/8/26.
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

public struct ZLClipStatus {
    var editRect: CGRect
    var angle: CGFloat = 0
    var ratio: ZLImageClipRatio?
    
    public init(
        editRect: CGRect,
        angle: CGFloat = 0,
        ratio: ZLImageClipRatio? = nil
    ) {
        self.editRect = editRect
        self.angle = angle
        self.ratio = ratio
    }
}

public struct ZLAdjustStatus {
    var brightness: Float = 0
    var contrast: Float = 0
    var saturation: Float = 0

    var allValueIsZero: Bool {
        brightness == 0 && contrast == 0 && saturation == 0
    }
    
    public init(
        brightness: Float = 0,
        contrast: Float = 0,
        saturation: Float = 0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
    }
}

public class ZLEditImageModel: NSObject {
    public let drawPaths: [ZLDrawPath]
    
    public let mosaicPaths: [ZLMosaicPath]
    
    public let clipStatus: ZLClipStatus?
    
    public let adjustStatus: ZLAdjustStatus?
    
    public let selectFilter: ZLFilter?
    
    public let stickers: [ZLBaseStickertState]
    
    public let actions: [ZLEditorAction]
        
    public init(
        drawPaths: [ZLDrawPath] = [],
        mosaicPaths: [ZLMosaicPath] = [],
        clipStatus: ZLClipStatus? = nil,
        adjustStatus: ZLAdjustStatus? = nil,
        selectFilter: ZLFilter? = nil,
        stickers: [ZLBaseStickertState] = [],
        actions: [ZLEditorAction] = []
    ) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.clipStatus = clipStatus
        self.adjustStatus = adjustStatus
        self.selectFilter = selectFilter
        self.stickers = stickers
        self.actions = actions
        super.init()
    }
}

open class ZLEditImageViewController: UIViewController {
    static let maxDrawLineImageWidth: CGFloat = 600
    
    static let shadowColorFrom = UIColor.black.withAlphaComponent(0.35).cgColor
    
    static let shadowColorTo = UIColor.clear.cgColor
    
    public var drawColViewH: CGFloat = 50
    
    public var filterColViewH: CGFloat = 90
    
    public var adjustColViewH: CGFloat = 60
        
    open lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = 1
        view.maximumZoomScale = 3
        view.delegate = self
        return view
    }()
    
    open lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    // Show image.
    open lazy var imageView: UIImageView = {
        let view = UIImageView(image: originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .black
        return view
    }()
    
    open lazy var topShadowView: ZLPassThroughView = {
        let shadowView = ZLPassThroughView()
        shadowView.findResponderSticker = findResponderSticker(_:)
        return shadowView
    }()
    
    open lazy var topShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [ZLEditImageViewController.shadowColorFrom, ZLEditImageViewController.shadowColorTo]
        layer.locations = [0, 1]
        return layer
    }()
     
    open lazy var bottomShadowView: ZLPassThroughView = {
        let shadowView = ZLPassThroughView()
        shadowView.findResponderSticker = findResponderSticker(_:)
        return shadowView
    }()
    
    open lazy var bottomShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [ZLEditImageViewController.shadowColorTo, ZLEditImageViewController.shadowColorFrom]
        layer.locations = [0, 1]
        return layer
    }()
    
    open lazy var cancelBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.titleLabel?.font = ZLImageEditorLayout.bottomToolTitleFont
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(localLanguageTextValue(.cancel), for: .normal)
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        btn.enlargeInset = 30
        return btn
    }()
    
    open lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = ZLImageEditorLayout.bottomToolTitleFont
        btn.backgroundColor = .zl.editDoneBtnBgColor
        btn.setTitle(localLanguageTextValue(.editFinish), for: .normal)
        btn.setTitleColor(.zl.editDoneBtnTitleColor, for: .normal)
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = ZLImageEditorLayout.bottomToolBtnCornerRadius
        return btn
    }()
    
    open lazy var undoBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
//        btn.setImage(.zl.getImage("zl_undo_disable"), for: .disabled)
        btn.setImage(.zl.getImage("zl_undo"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = !editorManager.actions.isEmpty
        btn.enlargeInset = 8
        btn.addTarget(self, action: #selector(undoBtnClick), for: .touchUpInside)
        return btn
    }()
    
    open lazy var redoBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_redo"), for: .normal)
//        btn.setImage(.zl.getImage("zl_redo_disable"), for: .disabled)
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = editorManager.actions.count != editorManager.redoActions.count
        btn.enlargeInset = 8
        btn.addTarget(self, action: #selector(redoBtnClick), for: .touchUpInside)
        return btn
    }()
    
    open lazy var removeBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_remove"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 8
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(removeBtnClick), for: .touchUpInside)
        return btn
    }()
    
    open lazy var duplicateBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_duplicate"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 8
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(duplicateBtnClick), for: .touchUpInside)
        return btn
    }()
    
    open lazy var editBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(.zl.getImage("zl_pallete"), for: .normal)
        btn.setImage(.zl.getImage("zl_pallete_selected"), for: .selected)
        btn.adjustsImageWhenHighlighted = true
        btn.enlargeInset = 8
        btn.isEnabled = false
        btn.isSelected = false
        btn.addTarget(self, action: #selector(editBtnClick), for: .touchUpInside)
        return btn
    }()
    
    open lazy var editToolCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        ZLEditToolCell.zl.register(view)
        
        return view
    }()
    
    open var drawColorCollectionView: UICollectionView?
    
    open var filterCollectionView: UICollectionView?
    
    open var adjustCollectionView: UICollectionView?
    
    open var drawShapeCollectionView: UICollectionView?
        
    var currentSticker: ZLBaseStickerView?
    
    var shapeStyleSelectorView: ShapeStyleSelectorView!
    
    var adjustSlider: ZLAdjustSlider?
    
    var animateDismiss = true
    
    var originalImage: UIImage
    
    // The frame after first layout, used in dismiss animation.
    var originalFrame: CGRect = .zero
    
    var tools: [ZLImageEditorConfiguration.EditTool]
    
    let adjustTools: [ZLImageEditorConfiguration.AdjustTool]
    
    var editImage: UIImage
    
    var editImageWithoutAdjust: UIImage
    
    var editImageAdjustRef: UIImage?
    
    // Show draw lines.
    lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    // Show text and image stickers.
    lazy var stickersContainer = UIView()
    
    private var currentDrawingLivePath: UIBezierPath?
    private var currentDrawingLivePoints: [CGPoint] = []
    private var currentDrawingPreviewLayer: CAShapeLayer?
    
    var mosaicImage: UIImage?
    
    // Show mosaic image
    var mosaicImageLayer: CALayer?
    
    // The mask layer of mosaicImageLayer
    var mosaicImageLayerMaskLayer: CAShapeLayer?
    
    var selectedTool: ZLImageEditorConfiguration.EditTool = .select
    
    var selectedAdjustTool: ZLImageEditorConfiguration.AdjustTool?
    
    let drawColors: [UIColor]
    
    var shapeOptions: [DrawShapeType]
    
    var currentDrawColor = ZLImageEditorConfiguration.default().defaultDrawColor
    
    var currentDrawShape: DrawShapeType? = nil
    
    var drawPaths: [ZLDrawPath]
    
    var drawLineWidth: CGFloat = ZLStrokeWidthConstants.medium
    
    var drawLineStyle: String = "solid"
    
    var mosaicPaths: [ZLMosaicPath]
    
    var mosaicLineWidth: CGFloat = 25
    
    var thumbnailFilterImages: [UIImage] = []
    
    // Cache the filter image of original image
    var filterImages: [String: UIImage] = [:]
    
    var currentFilter: ZLFilter
    
    var stickers: [ZLBaseStickerView] = []
    
    var isScrolling = false
    
    var shouldLayout = true
    
    var imageStickerContainerIsHidden = true

    var fontChooserContainerIsHidden = true
    
    var currentClipStatus: ZLClipStatus

    public var preClipStatus: ZLClipStatus

    public var preStickerState: ZLBaseStickertState?

    public var currentAdjustStatus: ZLAdjustStatus

    public var preAdjustStatus: ZLAdjustStatus

    var editorManager: ZLEditorManager
    
    public lazy var deleteDrawPaths: [ZLDrawPath] = []
    
    public var defaultDrawPathWidth: CGFloat = 0
    
    private var impactFeedback: UIImpactFeedbackGenerator?
    
    public lazy var panGes: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(drawAction(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        return pan
    }()
    
    /// 是否允许交换图片宽高
    private var shouldSwapSize: Bool {
        currentClipStatus.angle.zl.toPi.truncatingRemainder(dividingBy: .pi) != 0
    }
    
    var imageSize: CGSize {
        if shouldSwapSize {
            return CGSize(width: originalImage.size.height, height: originalImage.size.width)
        } else {
            return originalImage.size
        }
    }
    
    var toolViewStateTimer: Timer?
    
    var hasAdjustedImage = false
    
    @objc public var editFinishBlock: ((UIImage, ZLEditImageModel?) -> Void)?
    
    @objc public var cancelBlock: (() -> Void)?
    
    override open var prefersStatusBarHidden: Bool { true }
    
    override open var prefersHomeIndicatorAutoHidden: Bool { true }
    
    /// 延缓屏幕上下方通知栏弹出，避免手势冲突
    override open var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { [.top, .bottom] }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        deviceIsiPhone() ? .portrait : .all
    }
    
    var previewLayer: CAShapeLayer? // For temporary drawing preview
    var creationStartPoint: CGPoint?
    
    deinit {
        cleanToolViewStateTimer()
    }
    
    @objc public class func showEditImageVC(
        parentVC: UIViewController?,
        animate: Bool = true,
        image: UIImage,
        editModel: ZLEditImageModel? = nil,
        completion: ((UIImage, ZLEditImageModel?) -> Void)?,
        cancelBlock: (() -> Void)? = nil
    ) {
        var tools = ZLImageEditorConfiguration.default().tools.filter { tool in
            tool != .draw && tool != .arrow && tool != .circle && tool != .line && tool != .square
        }
        if ZLImageEditorConfiguration.default().showClipDirectlyIfOnlyHasClipTool, tools.count == 1, tools.contains(.clip) {
            let vc = ZLClipImageViewController(
                image: image,
                status: editModel?.clipStatus ?? ZLClipStatus(editRect: CGRect(origin: .zero, size: image.size))
            )
            
            vc.clipDoneBlock = { angle, editRect, ratio in
                let m = ZLEditImageModel(
                    clipStatus: ZLClipStatus(editRect: editRect, angle: angle, ratio: ratio)
                )
                completion?(image.zl.clipImage(angle: angle, editRect: editRect, isCircle: ratio.isCircle) ?? image, m)
            }
            vc.cancelClipBlock = {
                cancelBlock?()
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        } else {
            let vc = ZLEditImageViewController(image: image, editModel: editModel)
            vc.editFinishBlock = { ei, editImageModel in
                completion?(ei, editImageModel)
            }
            vc.cancelBlock = {
                cancelBlock?()
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        }
    }
    
    @objc public init(image: UIImage, editModel: ZLEditImageModel? = nil) {
        var image = image
        if image.scale != 1,
           let cgImage = image.cgImage {
            image = image.zl.resize_vI(
                CGSize(width: cgImage.width, height: cgImage.height),
                scale: 1
            ) ?? image
        }
        
        originalImage = image.zl.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        currentClipStatus = editModel?.clipStatus ?? ZLClipStatus(editRect: CGRect(origin: .zero, size: image.size))
        preClipStatus = currentClipStatus
        drawColors = ZLImageEditorConfiguration.default().drawColors
        currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        mosaicPaths = editModel?.mosaicPaths ?? []
        currentAdjustStatus = editModel?.adjustStatus ?? ZLAdjustStatus()
        preAdjustStatus = currentAdjustStatus
        var ts = ZLImageEditorConfiguration.default().tools.filter { tool in
            tool != .draw && tool != .arrow && tool != .circle && tool != .line && tool != .square
        }
        if ts.contains(.imageSticker), ZLImageEditorConfiguration.default().imageStickerContainerView == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        tools = ts
        adjustTools = ZLImageEditorConfiguration.default().adjustTools
        selectedAdjustTool = adjustTools.first
        editorManager = ZLEditorManager(actions: editModel?.actions ?? [])
        shapeOptions = [.freehand, .arrow, .ellipse, .rectangle, .line]
        
        super.init(nibName: nil, bundle: nil)
        
        let toolsShape = ZLImageEditorConfiguration.default().tools.filter { tool in
            tool == .draw || tool == .arrow || tool == .circle || tool == .line || tool == .square
        }
        
        tools.insert(.select, at: 0)
        if (toolsShape.count > 0) {
            shapeOptions = []
            tools.insert(.shape, at: 1)
            toolsShape.forEach { t in
                switch t {
                case .draw:
                    shapeOptions.append(.freehand)
                case .arrow:
                    shapeOptions.append(.arrow)
                case .circle:
                    shapeOptions.append(.ellipse)
                case .square:
                    shapeOptions.append(.rectangle)
                case .line:
                    shapeOptions.append(.line)
                default:
                    break
                }
            }
        }
        
        if (shapeOptions.count > 0) {
            currentDrawShape = shapeOptions[0]
        }

        
        editorManager.delegate = self
        
        if !drawColors.contains(currentDrawColor) {
            currentDrawColor = drawColors.first!
        }
        
        stickers = editModel?.stickers.compactMap {
            ZLBaseStickerView.initWithState($0)
        } ?? []
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        rotationImageView()
        if tools.contains(.filter) {
            generateFilterImages()
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard tools.contains(.draw) else { return }
        
        var size = drawingImageView.frame.size
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        
        let width = drawLineWidth / mainScrollView.zoomScale * toImageScale
        defaultDrawPathWidth = width
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else {
            return
        }
        
        shouldLayout = false
        var insets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            insets = self.view.safeAreaInsets
        }
        insets.top = max(insets.top, 20)
        
        mainScrollView.frame = view.bounds
        resetContainerViewFrame()
        
        topShadowView.frame = CGRect(x: 0, y: 0, width: view.zl.width, height: 50 + insets.top)
        topShadowLayer.frame = topShadowView.bounds
        
        bottomShadowView.frame = CGRect(x: 0, y: view.zl.height - 150 - insets.bottom, width: view.zl.width, height: 150 + insets.bottom)
        bottomShadowLayer.frame = bottomShadowView.bounds
        
        let cancelBtnW = localLanguageTextValue(.cancel)
            .zl.boundingRect(
                font: ZLImageEditorLayout.bottomToolTitleFont,
                limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 28)
            ).width
        cancelBtn.frame = CGRect(x: 20, y: insets.top, width: cancelBtnW, height: 30)
        redoBtn.frame = CGRect(x: view.zl.width - 15 - 30, y: insets.top, width: 30, height: 30)
        undoBtn.frame = CGRect(x: redoBtn.zl.left - 15 - 30, y: insets.top, width: 30, height: 30)
        removeBtn.frame = CGRect(x: undoBtn.zl.left - 15 - 30, y: insets.top, width: 30, height: 30)
        duplicateBtn.frame = CGRect(x: removeBtn.zl.left - 15 - 30, y: insets.top, width: 30, height: 30)
        editBtn.frame = CGRect(x: duplicateBtn.zl.left - 15 - 30, y: insets.top, width: 30, height: 30)
        
        shapeStyleSelectorView = ShapeStyleSelectorView()
        shapeStyleSelectorView.delegate = self
        shapeStyleSelectorView.translatesAutoresizingMaskIntoConstraints = false
        shapeStyleSelectorView.isHidden = true
        view.addSubview(shapeStyleSelectorView)

        NSLayoutConstraint.activate([
            shapeStyleSelectorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            shapeStyleSelectorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            shapeStyleSelectorView.topAnchor.constraint(equalTo: topShadowView.bottomAnchor, constant: 0),
//            shapeStyleSelectorView.heightAnchor.constraint(equalToConstant: 250)
        ])

//        shapeStyleSelectorView.isHidden = true // Default hidden
        
        drawColorCollectionView?.frame = CGRect(x: 11, y: 30, width: view.zl.width, height: drawColViewH)
        
        adjustCollectionView?.frame = CGRect(x: 20, y: 20, width: view.zl.width - 40, height: adjustColViewH)
        if ZLImageEditorUIConfiguration.default().adjustSliderType == .vertical {
            adjustSlider?.frame = CGRect(x: view.zl.width - 60, y: view.zl.height / 2 - 100, width: 60, height: 200)
        } else {
            let sliderHeight: CGFloat = 60
            let sliderWidth = UIDevice.current.userInterfaceIdiom == .phone ? view.zl.width - 100 : view.zl.width / 2
            adjustSlider?.frame = CGRect(
                x: (view.zl.width - sliderWidth) / 2,
                y: bottomShadowView.zl.top - sliderHeight,
                width: sliderWidth,
                height: sliderHeight
            )
        }
        
        filterCollectionView?.frame = CGRect(x: 20, y: 0, width: view.zl.width - 40, height: filterColViewH)
        
        let toolY: CGFloat = 95
        
        let doneBtnH = ZLImageEditorLayout.bottomToolBtnH
        let doneBtnW = localLanguageTextValue(.editFinish).zl.boundingRect(font: ZLImageEditorLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: doneBtnH)).width + 20
        doneBtn.frame = CGRect(x: view.zl.width - 20 - doneBtnW, y: toolY - 2, width: doneBtnW, height: doneBtnH)
        
        editToolCollectionView.frame = CGRect(x: 20, y: toolY, width: view.zl.width - 20 - 20 - doneBtnW - 20, height: 30)
        
        if !drawPaths.isEmpty {
            drawLine()
        }
        if !mosaicPaths.isEmpty {
            generateNewMosaicImage()
        }
        
        if let index = drawColors.firstIndex(where: { $0 == self.currentDrawColor }) {
            drawColorCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }
    
    func generateFilterImages() {
        let size: CGSize
        let ratio = (originalImage.size.width / originalImage.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = originalImage.zl.resize(size) ?? originalImage
        
        DispatchQueue.global().async {
            self.thumbnailFilterImages = ZLImageEditorConfiguration.default().filters.map { $0.applier?(thumbnailImage) ?? thumbnailImage }
            
            DispatchQueue.main.async {
                self.filterCollectionView?.reloadData()
                self.filterCollectionView?.performBatchUpdates {} completion: { _ in
                    if let index = ZLImageEditorConfiguration.default().filters.firstIndex(where: { $0 == self.currentFilter }) {
                        self.filterCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
                    }
                }
            }
        }
    }
    
    func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editImage
        let editRect = currentClipStatus.editRect
        
        let editSize = editRect.size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2), y: max(0, (scrollViewSize.height - h) / 2), width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size
        
        if currentClipStatus.ratio?.isCircle == true {
            let mask = CAShapeLayer()
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            mask.path = path.cgPath
            containerView.layer.mask = mask
        } else {
            containerView.layer.mask = nil
        }
        
        let scaleImageOrigin = CGPoint(x: -editRect.origin.x * ratio, y: -editRect.origin.y * ratio)
        let scaleImageSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayerMaskLayer?.frame = imageView.bounds
        drawingImageView.frame = imageView.frame
        stickersContainer.frame = imageView.frame
        
        // Optimization for long pictures.
        if (editRect.height / editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let widthScale = view.frame.width / w
            mainScrollView.maximumZoomScale = widthScale
            mainScrollView.zoomScale = widthScale
            mainScrollView.contentOffset = .zero
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / h)
        }
        
        originalFrame = view.convert(containerView.frame, from: mainScrollView)
        isScrolling = false
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(drawingImageView)
        containerView.addSubview(stickersContainer)
        
        view.addSubview(topShadowView)
        topShadowView.layer.addSublayer(topShadowLayer)
        topShadowView.addSubview(cancelBtn)
        topShadowView.addSubview(undoBtn)
        topShadowView.addSubview(redoBtn)
        topShadowView.addSubview(removeBtn)
        topShadowView.addSubview(duplicateBtn)
        topShadowView.addSubview(editBtn)
        
        view.addSubview(bottomShadowView)
        bottomShadowView.layer.addSublayer(bottomShadowLayer)
        bottomShadowView.addSubview(editToolCollectionView)
        bottomShadowView.addSubview(doneBtn)
        
        if tools.contains(.shape) {
            impactFeedback = UIImpactFeedbackGenerator(style: .light)

            let drawColorLayout = UICollectionViewFlowLayout()
            let drawColorItemWidth: CGFloat = 36
            drawColorLayout.itemSize = CGSize(width: drawColorItemWidth, height: drawColorItemWidth)
            drawColorLayout.minimumLineSpacing = 0
            drawColorLayout.minimumInteritemSpacing = 0
            drawColorLayout.scrollDirection = .horizontal
            let drawColorTopBottomInset = (drawColViewH - drawColorItemWidth) / 2
            drawColorLayout.sectionInset = UIEdgeInsets(top: drawColorTopBottomInset, left: 0, bottom: drawColorTopBottomInset, right: 0)
            
            let drawCV = UICollectionView(frame: .zero, collectionViewLayout: drawColorLayout)
            drawCV.backgroundColor = .clear
            drawCV.delegate = self
            drawCV.dataSource = self
            drawCV.isHidden = true
            
            bottomShadowView.addSubview(drawCV)
            ZLDrawColorCell.zl.register(drawCV)
            drawColorCollectionView = drawCV
        
            
            let shapeLayout = UICollectionViewFlowLayout()
            shapeLayout.scrollDirection = .horizontal
            shapeLayout.itemSize = CGSize(width: 40, height: 40) // Adjust size
            shapeLayout.minimumInteritemSpacing = 10
            shapeLayout.sectionInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            
            let shapeCV = UICollectionView(frame: .zero, collectionViewLayout: shapeLayout)
            shapeCV.backgroundColor = .clear
            shapeCV.showsHorizontalScrollIndicator = false
            shapeCV.delegate = self
            shapeCV.dataSource = self
            shapeCV.isHidden = true // Initially hidden
            
            bottomShadowView.addSubview(shapeCV)
            ZLDrawShapeCell.zl.register(shapeCV) // Register the new cell
            drawShapeCollectionView = shapeCV
        }
        
        if tools.contains(.filter) {
            if let applier = currentFilter.applier {
                let image = applier(originalImage)
                editImage = image
                editImageWithoutAdjust = image
                filterImages[currentFilter.name] = image
            }
            
            let filterLayout = UICollectionViewFlowLayout()
            filterLayout.itemSize = CGSize(width: filterColViewH - 30, height: filterColViewH - 10)
            filterLayout.minimumLineSpacing = 15
            filterLayout.minimumInteritemSpacing = 15
            filterLayout.scrollDirection = .horizontal
            filterLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
            
            let filterCV = UICollectionView(frame: .zero, collectionViewLayout: filterLayout)
            filterCV.backgroundColor = .clear
            filterCV.delegate = self
            filterCV.dataSource = self
            filterCV.isHidden = true
            bottomShadowView.addSubview(filterCV)
            
            ZLFilterImageCell.zl.register(filterCV)
            filterCollectionView = filterCV
        }
        
        if tools.contains(.adjust) {
            editImage = editImage.zl.adjust(
                brightness: currentAdjustStatus.brightness,
                contrast: currentAdjustStatus.contrast,
                saturation: currentAdjustStatus.saturation
            ) ?? editImage
            
            let adjustLayout = UICollectionViewFlowLayout()
            adjustLayout.itemSize = CGSize(width: adjustColViewH, height: adjustColViewH)
            adjustLayout.minimumLineSpacing = 10
            adjustLayout.minimumInteritemSpacing = 10
            adjustLayout.scrollDirection = .horizontal
            
            let adjustCV = UICollectionView(frame: .zero, collectionViewLayout: adjustLayout)
            
            adjustCV.backgroundColor = .clear
            adjustCV.delegate = self
            adjustCV.dataSource = self
            adjustCV.isHidden = true
            adjustCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(adjustCV)
            
            ZLAdjustToolCell.zl.register(adjustCV)
            adjustCollectionView = adjustCV
            
            adjustSlider = ZLAdjustSlider()
            if let selectedAdjustTool = selectedAdjustTool {
                changeAdjustTool(selectedAdjustTool)
            }
            adjustSlider?.beginAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.preAdjustStatus = self.currentAdjustStatus
            }
            adjustSlider?.valueChanged = { [weak self] value in
                self?.adjustValueChanged(value)
            }
            adjustSlider?.endAdjust = { [weak self] in
                guard let `self` = self else { return }
                self.editorManager.storeAction(
                    .adjust(oldStatus: self.preAdjustStatus, newStatus: self.currentAdjustStatus)
                )
                self.hasAdjustedImage = true
            }
            adjustSlider?.isHidden = true
            view.addSubview(adjustSlider!)
        }

        
        if tools.contains(.mosaic) {
            mosaicImage = editImage.zl.mosaicImage()
            
            mosaicImageLayer = CALayer()
            mosaicImageLayer?.contents = mosaicImage?.cgImage
            imageView.layer.addSublayer(mosaicImageLayer!)
            
            mosaicImageLayerMaskLayer = CAShapeLayer()
            mosaicImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
            mosaicImageLayerMaskLayer?.fillColor = nil
            mosaicImageLayerMaskLayer?.lineCap = .round
            mosaicImageLayerMaskLayer?.lineJoin = .round
            imageView.layer.addSublayer(mosaicImageLayerMaskLayer!)
            
            mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
        }
        
        if tools.contains(.imageSticker) {
            ZLImageEditorConfiguration.default().imageStickerContainerView?.hideBlock = { [weak self] in
                self?.setToolView(show: true)
                self?.imageStickerContainerIsHidden = true
            }
            
            ZLImageEditorConfiguration.default().imageStickerContainerView?.selectImageBlock = { [weak self] image in
                self?.addImageStickerView(image)
            }
        }

        if tools.contains(.textSticker) {
            ZLImageEditorConfiguration.default().fontChooserContainerView?.hideBlock = { [weak self] in
                self?.setToolView(show: true)
                self?.fontChooserContainerIsHidden = true
            }

            ZLImageEditorConfiguration.default().fontChooserContainerView?.selectFontBlock = { [weak self] font in
                self?.showInputTextVC(font: font, completion: { [weak self] text, textColor, font, image, style in
                    self?.addTextStickersView(text, textColor: textColor, font: font, image: image, style: style)
                })
            }
        }
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGes.delegate = self
        view.addGestureRecognizer(tapGes)
        
        view.addGestureRecognizer(panGes)
        mainScrollView.panGestureRecognizer.require(toFail: panGes)
        
        stickers.forEach { self.addSticker($0) }
    }
    
    /// 根据point查找可响应的sticker
    func findResponderSticker(_ point: CGPoint) -> UIView? {
        // 倒序查找subview
        for sticker in stickersContainer.subviews.reversed() {
            let rect = stickersContainer.convert(sticker.frame, to: view)
            if rect.contains(point) {
                return sticker
            }
        }
        
        return nil
    }
    
    func rotationImageView() {
        let transform = CGAffineTransform(rotationAngle: currentClipStatus.angle.zl.toPi)
        imageView.transform = transform
        drawingImageView.transform = transform
        stickersContainer.transform = transform
    }
    
    @objc func cancelBtnClick() {
        dismiss(animated: animateDismiss) {
            self.cancelBlock?()
        }
    }
    
    func selectBtnClick() {
        selectedTool = .select
        
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    func shapeBtnClick() {
        let isSelected = (selectedTool != .shape || selectedTool != .arrow || selectedTool != .circle || selectedTool != .draw || selectedTool != .line || selectedTool != .square)
       
        if isSelected {
            switch (currentDrawShape) {
            case .arrow:
                selectedTool = .arrow
            case .ellipse:
                selectedTool = .circle
            case .freehand:
                selectedTool = .draw
            case .line:
                selectedTool = .line
            case .rectangle:
                selectedTool = .square
            case .none:
                selectedTool = .shape
            }
        }
        
        setDrawViews(hidden: false)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    func clipBtnClick() {
        preClipStatus = currentClipStatus
        
        var currentEditImage = editImage
        autoreleasepool {
            currentEditImage = buildImage()
        }
        
        let vc = ZLClipImageViewController(image: currentEditImage, status: currentClipStatus)
        let rect = mainScrollView.convert(containerView.frame, to: view)
        vc.presentAnimateFrame = rect
        vc.presentAnimateImage = currentEditImage.zl
            .clipImage(
                angle: currentClipStatus.angle,
                editRect: currentClipStatus.editRect,
                isCircle: currentClipStatus.ratio?.isCircle ?? false
            )
        vc.modalPresentationStyle = .fullScreen
        
        vc.clipDoneBlock = { [weak self] angle, editRect, selectRatio in
            guard let `self` = self else { return }
            
            self.clipImage(status: ZLClipStatus(editRect: editRect, angle: angle, ratio: selectRatio))
            self.editorManager.storeAction(.clip(oldStatus: self.preClipStatus, newStatus: self.currentClipStatus))
        }
        
        vc.cancelClipBlock = { [weak self] () in
            self?.resetContainerViewFrame()
        }
        
        present(vc, animated: false) {
            self.mainScrollView.alpha = 0
            self.topShadowView.alpha = 0
            self.bottomShadowView.alpha = 0
            self.adjustSlider?.alpha = 0
        }
        
        selectedTool = .select
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    public func clipImage(status: ZLClipStatus) {
        let oldAngle = currentClipStatus.angle
        let oldContainerSize = stickersContainer.frame.size
        if oldAngle != status.angle {
            currentClipStatus.angle = status.angle
            rotationImageView()
        }
        
        currentClipStatus.editRect = status.editRect
        currentClipStatus.ratio = status.ratio
        resetContainerViewFrame()
        recalculateStickersFrame(oldContainerSize, oldAngle, status.angle)
    }
    
    func imageStickerBtnClick() {
        ZLImageEditorConfiguration.default().imageStickerContainerView?.show(in: view)
        setToolView(show: false)
        imageStickerContainerIsHidden = false
        
        selectedTool = .select
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    func textStickerBtnClick() {
        showInputTextVC(font: ZLImageEditorConfiguration.default().textStickerDefaultFont) { [weak self] text, textColor, font, image, style in
            self?.addTextStickersView(text, textColor: textColor, font: font, image: image, style: style)
        }
        
        selectedTool = .select
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    func mosaicBtnClick() {
        if (selectedTool == .mosaic) {
            return
        }

        selectedTool = .mosaic
        
        generateNewMosaicLayerIfAdjust()
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: true)
    }
    
    func filterBtnClick() {
        if (selectedTool == .filter) {
            return
        }
        selectedTool = .filter
   
        setDrawViews(hidden: true)
        setFilterViews(hidden: false)
        setAdjustViews(hidden: true)
    }
    
    func adjustBtnClick() {
        if (selectedTool == .adjust) {
            return
        }
        
        selectedTool = .adjust
     
        generateAdjustImageRef()
        setDrawViews(hidden: true)
        setFilterViews(hidden: true)
        setAdjustViews(hidden: false)
    }
    
    func setDrawViews(hidden: Bool) {
        drawColorCollectionView?.frame = CGRect(x: 11, y: 30, width: view.zl.width, height: drawColViewH)
        drawColorCollectionView?.isHidden = hidden
        drawShapeCollectionView?.frame = CGRect(x: 8, y: -10, width: view.zl.width, height: 40.0)
        drawShapeCollectionView?.isHidden = hidden
    }
    
    func setFilterViews(hidden: Bool) {
        filterCollectionView?.isHidden = hidden
    }
    
    func setAdjustViews(hidden: Bool) {
        adjustCollectionView?.isHidden = hidden
        adjustSlider?.isHidden = hidden
    }
    
    func changeAdjustTool(_ tool: ZLImageEditorConfiguration.AdjustTool) {
        selectedAdjustTool = tool
        
        switch tool {
        case .brightness:
            adjustSlider?.value = currentAdjustStatus.brightness
        case .contrast:
            adjustSlider?.value = currentAdjustStatus.contrast
        case .saturation:
            adjustSlider?.value = currentAdjustStatus.saturation
        }
    }
    
    @objc func doneBtnClick() {
        var stickerStates: [ZLBaseStickertState] = []
        for view in stickersContainer.subviews {
            guard let view = view as? ZLBaseStickerView else { continue }
            stickerStates.append(view.state)
        }
        
        var hasEdit = true
        if drawPaths.isEmpty,
           currentClipStatus.editRect.size == imageSize,
           currentClipStatus.angle == 0,
           mosaicPaths.isEmpty,
           stickerStates.isEmpty,
           currentFilter.applier == nil,
           currentAdjustStatus.allValueIsZero {
            hasEdit = false
        }
        
        var resImage = originalImage
        var editModel: ZLEditImageModel?
        
        func callback() {
            dismiss(animated: animateDismiss) {
                self.editFinishBlock?(resImage, editModel)
            }
        }
        
        guard hasEdit else {
            callback()
            return
        }
        
        autoreleasepool {
            let hud = ZLProgressHUD(style: ZLImageEditorUIConfiguration.default().hudStyle)
            hud.show(in: view)
            
            DispatchQueue.main.async { [self] in
                resImage = buildImage()
                resImage = resImage.zl
                    .clipImage(
                        angle: currentClipStatus.angle,
                        editRect: currentClipStatus.editRect,
                        isCircle: currentClipStatus.ratio?.isCircle ?? false
                    ) ?? resImage
                if let oriDataSize = originalImage.jpegData(compressionQuality: 1)?.count {
                    resImage = resImage.zl.compress(to: oriDataSize)
                }
                
                editModel = ZLEditImageModel(
                    drawPaths: drawPaths,
                    mosaicPaths: mosaicPaths,
                    clipStatus: currentClipStatus,
                    adjustStatus: currentAdjustStatus,
                    selectFilter: currentFilter,
                    stickers: stickerStates,
                    actions: editorManager.actions
                )
                
                hud.hide()
                callback()
            }
        }
    }
    
    @objc func undoBtnClick() {
        editorManager.undoAction()
    }
    
    @objc func redoBtnClick() {
        editorManager.redoAction()
    }
    
    @objc func removeBtnClick() {
        
        guard let stickerToRemove = currentSticker else {
             // Optionally, provide feedback to the user if no sticker is selected
             return
         }
        
        let stateBeforeRemoval = stickerToRemove.state
        
        stickerToRemove.remove()
        
        editorManager.storeAction(.sticker(oldState: stateBeforeRemoval, newState: nil))

        currentSticker = nil
        
        updateTopBarButtonsForSelectedSticker()
    }
    
    @objc func duplicateBtnClick() {
        guard let originalSticker = currentSticker else {
               // print("No sticker selected to duplicate.")
               return
           }

           // 1. Get the state of the original sticker.
           let originalState = originalSticker.state

           // 2. Create a new state for the duplicate.
           //    - Generate a new unique ID.
           //    - Slightly offset the originFrame so the duplicate doesn't perfectly overlap.
           //    - All other properties (image, text, color, scale, rotation, etc.) are copied.

           var newOriginFrame = originalState.originFrame
           let offset: CGFloat = 20.0 // How much to offset the duplicate
           newOriginFrame.origin.x += offset / (originalState.originScale * originalState.gesScale) // Adjust offset by current scale
           newOriginFrame.origin.y += offset / (originalState.originScale * originalState.gesScale)

           // Ensure the new frame is still within reasonable bounds of the stickersContainer
           // You might want to add checks here to prevent it from going too far off-screen.
           // For simplicity, this example assumes the offset is generally safe.

           var duplicateState: ZLBaseStickertState?

           // Create the specific type of state based on the original sticker's state
           if let imageState = originalState as? ZLImageStickerState {
               duplicateState = ZLImageStickerState(
                   image: imageState.image, // Or a copy if mutable
                   originScale: imageState.originScale,
                   originAngle: imageState.originAngle,
                   originFrame: newOriginFrame, // Use the offset frame
                   gesScale: imageState.gesScale,
                   gesRotation: imageState.gesRotation,
                   totalTranslationPoint: imageState.totalTranslationPoint // This might also need adjustment if it's absolute
                                                                         // But usually, totalTranslationPoint is part of how originFrame is derived,
                                                                         // so modifying originFrame might be enough.
                                                                         // Let's assume originFrame modification covers position.
               )
           } else if let textState = originalState as? ZLTextStickerState {
               duplicateState = ZLTextStickerState(
                   text: textState.text,
                   textColor: textState.textColor,
                   font: textState.font,
                   style: textState.style,
                   image: textState.image, // This is the rendered text image
                   originScale: textState.originScale,
                   originAngle: textState.originAngle,
                   originFrame: newOriginFrame,
                   gesScale: textState.gesScale,
                   gesRotation: textState.gesRotation,
                   totalTranslationPoint: textState.totalTranslationPoint
               )
           } else if let freehandState = originalState as? ZLFreehandDrawState {
               duplicateState = ZLFreehandDrawState(
                   bezierPath: freehandState.bezierPath.copy() as! UIBezierPath, // Important to copy the path
                   color: freehandState.color,
                   lineWidth: freehandState.lineWidth,
                   originalRatio: freehandState.originalRatio,
                   originScale: freehandState.originScale,
                   originAngle: freehandState.originAngle,
                   originFrame: newOriginFrame,
                   gesScale: freehandState.gesScale,
                   gesRotation: freehandState.gesRotation,
                   totalTranslationPoint: freehandState.totalTranslationPoint
               )
           } else if let lineState = originalState as? ZLLineState {
               duplicateState = ZLLineState(
                   startPoint: lineState.startPoint, // These points are relative to originFrame
                   endPoint: lineState.endPoint,     // So they don't need to change if originFrame moves
                   color: lineState.color,
                   lineWidth: lineState.lineWidth,
                   originScale: lineState.originScale,
                   originAngle: lineState.originAngle,
                   originFrame: newOriginFrame,
                   gesScale: lineState.gesScale,
                   gesRotation: lineState.gesRotation,
                   totalTranslationPoint: lineState.totalTranslationPoint,
                   strokeStyle: lineState.strokeStyle
               )
           } else if let arrowState = originalState as? ZLArrowState {
                duplicateState = ZLArrowState(
                   startPoint: arrowState.startPoint,
                   endPoint: arrowState.endPoint,
                   color: arrowState.color,
                   lineWidth: arrowState.lineWidth,
                   headSize: arrowState.headSize,
                   originScale: arrowState.originScale,
                   originAngle: arrowState.originAngle,
                   originFrame: newOriginFrame,
                   gesScale: arrowState.gesScale,
                   gesRotation: arrowState.gesRotation,
                   totalTranslationPoint: arrowState.totalTranslationPoint,
                   strokeStyle: arrowState.strokeStyle
               )
           } else if let shapeState = originalState as? ZLShapeState {
               duplicateState = ZLShapeState(
                   shapeType: shapeState.shapeType,
                   bounds: shapeState.bounds, // Bounds are relative to originFrame
                   strokeColor: shapeState.strokeColor,
                   fillColor: shapeState.fillColor,
                   lineWidth: shapeState.lineWidth,
                   cornerRadius: shapeState.cornerRadius,
                   originScale: shapeState.originScale,
                   originAngle: shapeState.originAngle,
                   originFrame: newOriginFrame,
                   gesScale: shapeState.gesScale,
                   gesRotation: shapeState.gesRotation,
                   totalTranslationPoint: shapeState.totalTranslationPoint,
                   strokeStyle: shapeState.strokeStyle
               )
           }
           // Add other sticker types if you have them

           guard let finalDuplicateState = duplicateState else {
               // print("Failed to create state for duplicate.")
               return
           }

           // 3. Create the new sticker view from the duplicate state.
           if let duplicateStickerView = ZLBaseStickerView.initWithState(finalDuplicateState) {
               // 4. Add the sticker to the view hierarchy and configure it.
               //    The `addSticker` method should handle adding to `stickersContainer`
               //    and calling `configSticker`.
               addSticker(duplicateStickerView) // Use the helper that doesn't store undo action
               
               selectSticker(sticker: duplicateStickerView)
           }
    }
    
    @objc func editBtnClick() {
        guard let selectedSticker = currentSticker else {
            editBtn.isSelected = false
            shapeStyleSelectorView.isHidden = true
            return
        }

        // Hanya aktifkan tombol edit untuk tipe stiker yang bisa di-style
        let isStyleEditableSticker = selectedSticker is ZLShapeView ||
                                    selectedSticker is ZLLineView ||
                                    selectedSticker is ZLArrowView ||
                                    selectedSticker is ZLFreehandDrawView

        if !isStyleEditableSticker {
            editBtn.isSelected = false
            shapeStyleSelectorView.isHidden = true
            return
        }
        
        let newIsHiddenState = !shapeStyleSelectorView.isHidden
        shapeStyleSelectorView.isHidden = newIsHiddenState
        editBtn.isSelected = !newIsHiddenState // Highlighted jika selector terlihat

        if !shapeStyleSelectorView.isHidden {
            // Tentukan apakah stiker yang dipilih mendukung opsi fill
            var canStickerHaveFill = false
            if let shapeSticker = selectedSticker as? ZLShapeView {
                canStickerHaveFill = (shapeSticker.shapeType == .rectangle || shapeSticker.shapeType == .ellipse)
                shapeStyleSelectorView.showFillColorOptions = canStickerHaveFill // UPDATE DI SINI
                shapeStyleSelectorView.setInitialStyle(strokeColor: shapeSticker.strokeColor, fillColor: shapeSticker.fillColor, strokeWidth: shapeSticker.lineWidth, strokeStyle: shapeSticker.strokeStyle)
            } else if let lineSticker = selectedSticker as? ZLLineView {
                shapeStyleSelectorView.showFillColorOptions = false // UPDATE DI SINI
                shapeStyleSelectorView.setInitialStyle(strokeColor: lineSticker.color, fillColor: nil, strokeWidth: lineSticker.lineWidth, strokeStyle: lineSticker.strokeStyle)
            } else if let arrowSticker = selectedSticker as? ZLArrowView {
                shapeStyleSelectorView.showFillColorOptions = false // UPDATE DI SINI
                shapeStyleSelectorView.setInitialStyle(strokeColor: arrowSticker.color, fillColor: nil, strokeWidth: arrowSticker.lineWidth, strokeStyle: arrowSticker.strokeStyle)
            } else if let freehandSticker = selectedSticker as? ZLFreehandDrawView {
                 shapeStyleSelectorView.showFillColorOptions = false // UPDATE DI SINI
                shapeStyleSelectorView.setInitialStyle(strokeColor: freehandSticker.color, fillColor: nil, strokeWidth: freehandSticker.lineWidth, strokeStyle: nil)
            }
        }
    }

    func updateTopBarButtonsForSelectedSticker() {
        let stickerIsSelected = (currentSticker != nil)
        removeBtn.isEnabled = stickerIsSelected
        duplicateBtn.isEnabled = stickerIsSelected

        let isStyleEditableSticker = stickerIsSelected &&
                                    (currentSticker is ZLShapeView ||
                                     currentSticker is ZLLineView ||
                                     currentSticker is ZLArrowView ||
                                     currentSticker is ZLFreehandDrawView)

        editBtn.isEnabled = isStyleEditableSticker

        if isStyleEditableSticker {
            if !editBtn.isSelected { // Jika tombol edit tidak di-highlight (misalnya, baru saja memilih stiker)
                shapeStyleSelectorView.isHidden = true
                // shapeStyleSelectorView.showFillColorOptions TIDAK diubah di sini, biarkan editBtnClick yang mengaturnya
            } else { // Tombol edit di-highlight, berarti selector harus terlihat
                shapeStyleSelectorView.isHidden = false
                // Update visibilitas opsi fill berdasarkan tipe stiker saat ini
                var canStickerHaveFill = false
                if let shapeSticker = currentSticker as? ZLShapeView {
                    canStickerHaveFill = (shapeSticker.shapeType == .rectangle || shapeSticker.shapeType == .ellipse)
                    shapeStyleSelectorView.setInitialStyle(strokeColor: shapeSticker.strokeColor, fillColor: shapeSticker.fillColor, strokeWidth: shapeSticker.lineWidth, strokeStyle: shapeSticker.strokeStyle) // setInitialStyle juga akan dipanggil
                } else if let lineSticker = currentSticker as? ZLLineView {
                    shapeStyleSelectorView.setInitialStyle(strokeColor: lineSticker.color, fillColor: nil, strokeWidth: lineSticker.lineWidth, strokeStyle: lineSticker.strokeStyle)
                } else if let arrowSticker = currentSticker as? ZLArrowView {
                    shapeStyleSelectorView.setInitialStyle(strokeColor: arrowSticker.color, fillColor: nil, strokeWidth: arrowSticker.lineWidth, strokeStyle: arrowSticker.strokeStyle)
                } else if let freehandSticker = currentSticker as? ZLFreehandDrawView {
                     shapeStyleSelectorView.setInitialStyle(strokeColor: freehandSticker.color, fillColor: nil, strokeWidth: freehandSticker.lineWidth, strokeStyle: nil)
                }
                shapeStyleSelectorView.showFillColorOptions = canStickerHaveFill // UPDATE DI SINI
            }
        } else {
            // Tidak ada stiker yang bisa di-style dipilih
            shapeStyleSelectorView.isHidden = true
            shapeStyleSelectorView.showFillColorOptions = false // Reset
            editBtn.isSelected = false
        }
    }

    @objc func tapAction(_ tap: UITapGestureRecognizer) {
        if currentSticker != nil {
            unselectSticker()
        } else {
            if bottomShadowView.alpha == 1 {
                setToolView(show: false)
            } else {
                setToolView(show: true)
            }
        }
    }
    
    @objc func handleFreeDrawACtion(_ pan:UIPanGestureRecognizer) {
        let point = pan.location(in: stickersContainer)
        
        if pan.state == .began {
            setToolView(show: false)
            mainScrollView.isScrollEnabled = false

            currentDrawingLivePoints = [point]
            currentDrawingLivePath = UIBezierPath()
            currentDrawingLivePath?.lineWidth = drawLineWidth
            currentDrawingLivePath?.lineCapStyle = .round
            currentDrawingLivePath?.lineJoinStyle = .round
            currentDrawingLivePath?.move(to: point)

            currentDrawingPreviewLayer?.removeFromSuperlayer()
            currentDrawingPreviewLayer = CAShapeLayer()
            currentDrawingPreviewLayer?.strokeColor = currentDrawColor.cgColor
            currentDrawingPreviewLayer?.fillColor = UIColor.clear.cgColor
            currentDrawingPreviewLayer?.lineWidth = drawLineWidth
            currentDrawingPreviewLayer?.lineCap = .round
            currentDrawingPreviewLayer?.lineJoin = .round
            currentDrawingPreviewLayer?.path = currentDrawingLivePath?.cgPath
            stickersContainer.layer.addSublayer(currentDrawingPreviewLayer!)

        } else if pan.state == .changed {
            guard let livePath = currentDrawingLivePath else { return }
            currentDrawingLivePoints.append(point)
            livePath.addLine(to: point)
            currentDrawingPreviewLayer?.path = livePath.cgPath

        } else if pan.state == .cancelled || pan.state == .ended {
            mainScrollView.isScrollEnabled = true
            setToolView(show: true, delay: 0.5)
            currentDrawingPreviewLayer?.removeFromSuperlayer()
            currentDrawingPreviewLayer = nil
            
            guard let livePath = currentDrawingLivePath, !currentDrawingLivePoints.isEmpty else {
                currentDrawingLivePath = nil
                currentDrawingLivePoints.removeAll()
                return
            }
            
            let pathContentBoundingBox = livePath.bounds // Bounding box of the path's centerline
            let expandedBoundingBox = pathContentBoundingBox.insetBy(dx: -drawLineWidth/2, dy: -drawLineWidth/2) // Expanded for line width

            // Now, add extra padding for the view's frame
            let viewOriginFrame = expandedBoundingBox.insetBy(dx: -ZLFreehandDrawConstants.framePadding,
                                                             dy: -ZLFreehandDrawConstants.framePadding)

            // Create ZLDrawPath with points relative to the EXPANDED BOUNDING BOX (expandedBoundingBox),
            // NOT relative to viewOriginFrame. The view's extra padding is outside of where the path itself is drawn.
            let relativePath = UIBezierPath()
            relativePath.lineWidth = drawLineWidth
            relativePath.lineCapStyle = .round
            relativePath.lineJoinStyle = .round

            if let firstPoint = currentDrawingLivePoints.first {
                // Points are made relative to the *content's* expanded box,
                // and will be drawn starting at framePadding within the view.
                relativePath.move(to: CGPoint(x: (firstPoint.x - expandedBoundingBox.minX) + ZLFreehandDrawConstants.framePadding,
                                                y: (firstPoint.y - expandedBoundingBox.minY) + ZLFreehandDrawConstants.framePadding))
            }
            for i in 1..<currentDrawingLivePoints.count {
                let p = currentDrawingLivePoints[i]
                relativePath.addLine(to: CGPoint(x: (p.x - expandedBoundingBox.minX) + ZLFreehandDrawConstants.framePadding,
                                                 y: (p.y - expandedBoundingBox.minY) + ZLFreehandDrawConstants.framePadding))
            }

            let drawPathObject = ZLDrawPath(
                pathColor: currentDrawColor, // Initial color
                pathWidth: drawLineWidth,    // Initial width
                defaultLinePath: 0,
                ratio: 1.0,
                startPoint: CGPoint(x: (currentDrawingLivePoints.first!.x - expandedBoundingBox.minX) + ZLFreehandDrawConstants.framePadding,
                                    y: (currentDrawingLivePoints.first!.y - expandedBoundingBox.minY) + ZLFreehandDrawConstants.framePadding)
            )
            drawPathObject.path = relativePath // The UIBezierPath from user's gesture

            let originScale = 1.0 / mainScrollView.zoomScale
            let originAngle = -currentClipStatus.angle

            let freehandState = ZLFreehandDrawState(
                // Pass the UIBezierPath directly
                bezierPath: drawPathObject.path.copy() as! UIBezierPath, // Pass a copy
                color: currentDrawColor,      // Initial color for the state
                lineWidth: drawLineWidth,     // Initial line width for the state
                originalRatio: drawPathObject.ratio, // Store original ZLDrawPath.ratio if needed
                originScale: originScale,
                originAngle: originAngle,
                originFrame: viewOriginFrame,
                gesScale: 1.0,
                gesRotation: 0,
                totalTranslationPoint: .zero
            )
            let freehandView = ZLFreehandDrawView(state: freehandState)
            addSticker(freehandView)

            currentDrawingLivePath = nil
            currentDrawingLivePoints.removeAll()
        }
    }
    
    @objc func handleMozaicAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: imageView)
        if pan.state == .began {
            setToolView(show: false)
            
            var actualSize = currentClipStatus.editRect.size
            if shouldSwapSize {
                swap(&actualSize.width, &actualSize.height)
            }
            let ratio = min(
                mainScrollView.frame.width / currentClipStatus.editRect.width,
                mainScrollView.frame.height / currentClipStatus.editRect.height
            )
            
            let pathW = mosaicLineWidth / mainScrollView.zoomScale
            let path = ZLMosaicPath(pathWidth: pathW, ratio: ratio, startPoint: point)
            
            mosaicImageLayerMaskLayer?.lineWidth = pathW
            mosaicImageLayerMaskLayer?.path = path.path.cgPath
            mosaicPaths.append(path)
        } else if pan.state == .changed {
            let path = mosaicPaths.last
            path?.addLine(to: point)
            mosaicImageLayerMaskLayer?.path = path?.path.cgPath
        } else if pan.state == .cancelled || pan.state == .ended {
            setToolView(show: true, delay: 0.5)
            if let path = mosaicPaths.last {
                editorManager.storeAction(.mosaic(path))
            }
            generateNewMosaicImage()
        }
    }
    
    @objc func handleLineShapeArrowAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: stickersContainer) // Use stickersContainer coordinates
        
        let arrowHeadSize = ZLImageEditorConfiguration.default().defaultArrowHeadSize
        let arrowHeadAngleConfig = ZLImageEditorConfiguration.default().defaultArrowHeadAngleConfig

        
        if pan.state == .began {
            guard selectedTool != nil else { return } // Should not happen if delegate logic is correct

            creationStartPoint = point
            mainScrollView.isScrollEnabled = false
            setToolView(show: false)

            // Setup preview layer
            previewLayer?.removeFromSuperlayer() // Clear old preview
            previewLayer = CAShapeLayer()
            previewLayer?.lineWidth = ZLImageEditorConfiguration.default().defaultLineWidth // Or get from config/slider
            previewLayer?.strokeColor = currentDrawColor.cgColor // Or get from config/color picker
            previewLayer?.fillColor = nil // Or get fill if shape tool
            previewLayer?.lineCap = .round
            stickersContainer.layer.addSublayer(previewLayer!)

        } else if pan.state == .changed {
            guard let start = creationStartPoint, let previewLayer = previewLayer else { return }

            // Update preview drawing based on selectedTool
            let path = UIBezierPath()
            if selectedTool == .line || selectedTool == .arrow {
                path.move(to: start)
                path.addLine(to: point)
                // Add arrow head to path if selectedTool == .arrow (simplified)
                if selectedTool == .arrow {
                    // Calculate the angle of the line
                    let angle = atan2(point.y - start.y, point.x - start.x)
                    
                    // Calculate points for the arrow head
                    let headAngle1 = angle + arrowHeadAngleConfig
                    let headAngle2 = angle - arrowHeadAngleConfig
                    
                    let headPoint1 = CGPoint(
                        x: point.x + arrowHeadSize * cos(headAngle1),
                        y: point.y + arrowHeadSize * sin(headAngle1)
                    )
                    let headPoint2 = CGPoint(
                        x: point.x + arrowHeadSize * cos(headAngle2),
                        y: point.y + arrowHeadSize * sin(headAngle2)
                    )
                    
                    // Draw the arrow head
                    path.move(to: point)
                    path.addLine(to: headPoint1)
                    path.move(to: point)
                    path.addLine(to: headPoint2)
                }
            } else if selectedTool == .square {
                let rect = CGRect(origin: CGPoint(x: min(start.x, point.x), y: min(start.y, point.y)),
                                  size: CGSize(width: abs(start.x - point.x), height: abs(start.y - point.y)))
                path.append(UIBezierPath(roundedRect: rect, cornerRadius: 5.0))
            } else if selectedTool == .circle {
                let rect = CGRect(origin: CGPoint(x: min(start.x, point.x), y: min(start.y, point.y)),
                                  size: CGSize(width: abs(start.x - point.x), height: abs(start.y - point.y)))
                
                path.append(UIBezierPath(ovalIn: rect))
            }
            previewLayer.path = path.cgPath

        } else if pan.state == .ended || pan.state == .cancelled {
            previewLayer?.removeFromSuperlayer()
            previewLayer = nil
            mainScrollView.isScrollEnabled = true
            setToolView(show: true, delay: 0.5)

            guard let start = creationStartPoint, start != point else {
                 creationStartPoint = nil
                 return // Ignore taps or zero-length drags
            }

            // --- Finalize and Create Sticker ---
//            let currentScale = mainScrollView.zoomScale
            let originScale = 1.0
            let originAngle = -currentClipStatus.angle // Sticker angle is inverse of image rotation

            // 1. Calculate final bounds (originFrame) in stickersContainer coords
            let finalRect = CGRect(origin: CGPoint(x: min(start.x, point.x), y: min(start.y, point.y)),
                                   size: CGSize(width: abs(start.x - point.x), height: abs(start.y - point.y)))
            // For lines/arrows, the frame needs padding if line width is significant, or adjust relative points
            let padding: CGFloat = 10 // Add padding to ensure line ends aren't clipped
            let originFrame = finalRect.insetBy(dx: -padding, dy: -padding)

            // 2. Get current tool settings (color, width, shape type etc.)
            let currentLineColor = currentDrawColor // Replace with actual selection
            let currentLineWidth = drawLineWidth // Replace with actual selection

            // 3. Create State object (Calculate points relative to originFrame)
            let relativeStart = CGPoint(x: start.x - originFrame.minX, y: start.y - originFrame.minY)
            let relativeEnd = CGPoint(x: point.x - originFrame.minX, y: point.y - originFrame.minY)
            let relativeBounds = CGRect(x: padding, y: padding, width: finalRect.width, height: finalRect.height) // Bounds within the padded frame

            var sticker: ZLBaseStickerView?

            switch selectedTool {
            case .line:
                let state = ZLLineState(startPoint: relativeStart, endPoint: relativeEnd, color: currentLineColor, lineWidth: currentLineWidth, originScale: originScale, originAngle: originAngle, originFrame: originFrame, gesScale: 1, gesRotation: 0, totalTranslationPoint: .zero, strokeStyle: drawLineStyle)
                sticker = ZLLineView(state: state)
            case .arrow:
                let state = ZLArrowState(startPoint: relativeStart, endPoint: relativeEnd, color: currentLineColor, lineWidth: currentLineWidth, headSize: arrowHeadSize, originScale: originScale, originAngle: originAngle, originFrame: originFrame, gesScale: 1, gesRotation: 0, totalTranslationPoint: .zero, strokeStyle: drawLineStyle)
                sticker = ZLArrowView(state: state)
            case .square:
                let state = ZLShapeState(shapeType: .rectangle, bounds: relativeBounds, strokeColor: currentLineColor, fillColor: nil, lineWidth: currentLineWidth, cornerRadius: 5, originScale: originScale, originAngle: originAngle, originFrame: originFrame, gesScale: 1, gesRotation: 0, totalTranslationPoint: .zero, strokeStyle: drawLineStyle)
                sticker = ZLShapeView(state: state)
            case .circle:
                let state = ZLShapeState(shapeType: .ellipse, bounds: relativeBounds, strokeColor: currentLineColor, fillColor: nil, lineWidth: currentLineWidth, cornerRadius: 0, originScale: originScale, originAngle: originAngle, originFrame: originFrame, gesScale: 1, gesRotation: 0, totalTranslationPoint: .zero, strokeStyle: drawLineStyle)
                sticker = ZLShapeView(state: state)
            default:
                break // Should not happen
            }

            // 4. Add View & Store Action
            if let sticker = sticker {
                addSticker(sticker)
            }

            creationStartPoint = nil
        }
    }
    
    @objc func drawAction(_ pan: UIPanGestureRecognizer) {
        if selectedTool == .draw {
            handleFreeDrawACtion(pan)
        } else if selectedTool == .mosaic {
            handleMozaicAction(pan)
        } else {
            handleLineShapeArrowAction(pan)
        }
    }
    
    // 生成一个没有调整参数前的图片
    func generateAdjustImageRef() {
        editImageAdjustRef = generateNewMosaicImage(
            inputImage: editImageWithoutAdjust,
            inputMosaicImage: editImageWithoutAdjust.zl.mosaicImage()
        )
    }
    
    func adjustValueChanged(_ value: Float) {
        guard let selectedAdjustTool else {
            return
        }
        
        switch selectedAdjustTool {
        case .brightness:
            if currentAdjustStatus.brightness == value {
                return
            }
            
            currentAdjustStatus.brightness = value
        case .contrast:
            if currentAdjustStatus.contrast == value {
                return
            }
            
            currentAdjustStatus.contrast = value
        case .saturation:
            if currentAdjustStatus.saturation == value {
                return
            }
            
            currentAdjustStatus.saturation = value
        }
        
        adjustStatusChanged()
    }
    
    public func adjustStatusChanged() {
        let resultImage = editImageAdjustRef?.zl.adjust(
            brightness: currentAdjustStatus.brightness,
            contrast: currentAdjustStatus.contrast,
            saturation: currentAdjustStatus.saturation
        )
        
        guard let resultImage else { return }
        
        editImage = resultImage
        imageView.image = editImage
    }
    
    func generateNewMosaicLayerIfAdjust() {
        defer {
            hasAdjustedImage = false
        }
        
        guard tools.contains(.mosaic), hasAdjustedImage else { return }
        generateNewMosaicImageLayer()
        
        if !mosaicPaths.isEmpty {
            generateNewMosaicImage()
        }
    }
    
    func setToolView(show: Bool, delay: TimeInterval? = nil) {
        cleanToolViewStateTimer()
        if let delay = delay {
            toolViewStateTimer = Timer.scheduledTimer(timeInterval: delay, target: ZLWeakProxy(target: self), selector: #selector(setToolViewShow_timerFunc(show:)), userInfo: ["show": show], repeats: false)
            RunLoop.current.add(toolViewStateTimer!, forMode: .common)
        } else {
            setToolViewShow_timerFunc(show: show)
        }
    }
    
    @objc private func setToolViewShow_timerFunc(show: Bool) {
        var flag = show
        if let toolViewStateTimer = toolViewStateTimer {
            let userInfo = toolViewStateTimer.userInfo as? [String: Any]
            flag = userInfo?["show"] as? Bool ?? true
            cleanToolViewStateTimer()
        }
        topShadowView.layer.removeAllAnimations()
        bottomShadowView.layer.removeAllAnimations()
        adjustSlider?.layer.removeAllAnimations()
        if flag {
            UIView.animate(withDuration: 0.25) {
                self.topShadowView.alpha = 1
                self.bottomShadowView.alpha = 1
                self.adjustSlider?.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.topShadowView.alpha = 0
                self.bottomShadowView.alpha = 0
                self.adjustSlider?.alpha = 0
            }
        }
    }
    
    public func cleanToolViewStateTimer() {
        toolViewStateTimer?.invalidate()
        toolViewStateTimer = nil
    }
    
    public func showInputTextVC(_ text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: ZLInputTextStyle = .normal, completion: @escaping (String, UIColor, UIFont, UIImage?, ZLInputTextStyle) -> Void) {
        var bgImage: UIImage?
        autoreleasepool {
            // Calculate image displayed frame on the screen.
            var r = mainScrollView.convert(view.frame, to: containerView)
            r.origin.x += mainScrollView.contentOffset.x / mainScrollView.zoomScale
            r.origin.y += mainScrollView.contentOffset.y / mainScrollView.zoomScale
            let scale = imageSize.width / imageView.frame.width
            r.origin.x *= scale
            r.origin.y *= scale
            r.size.width *= scale
            r.size.height *= scale
            
            let isCircle = currentClipStatus.ratio?.isCircle ?? false
            bgImage = buildImage()
                .zl.clipImage(angle: currentClipStatus.angle, editRect: currentClipStatus.editRect, isCircle: isCircle)?
                .zl.clipImage(angle: 0, editRect: r, isCircle: isCircle)
        }
        
        let vc = ZLInputTextViewController(image: bgImage, text: text, font: font, textColor: textColor, style: style)
        
        vc.endInput = { text, textColor, font, image, style in
            completion(text, textColor, font, image, style)
        }
        
        vc.modalPresentationStyle = .fullScreen
        showDetailViewController(vc, sender: nil)
    }
    
    func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let scale = mainScrollView.zoomScale
        // Calculate the display rect of container view.
        let x = (mainScrollView.contentOffset.x - containerView.frame.minX) / scale
        let y = (mainScrollView.contentOffset.y - containerView.frame.minY) / scale
        let w = view.frame.width / scale
        let h = view.frame.height / scale
        // Convert to text stickers container view.
        let r = containerView.convert(CGRect(x: x, y: y, width: w, height: h), to: stickersContainer)
        let originFrame = CGRect(x: r.minX + (r.width - size.width) / 2, y: r.minY + (r.height - size.height) / 2, width: size.width, height: size.height)
        return originFrame
    }
    
    /// Add image sticker
    func addImageStickerView(_ image: UIImage) {
        let scale = mainScrollView.zoomScale
        let size = ZLImageStickerView.calculateSize(image: image, width: view.frame.width)
        let originFrame = getStickerOriginFrame(size)
        
        let imageSticker = ZLImageStickerView(image: image, originScale: 1 / scale, originAngle: -currentClipStatus.angle, originFrame: originFrame)
        addSticker(imageSticker)
    }
    
    /// Add text sticker
    func addTextStickersView(_ text: String, textColor: UIColor, font: UIFont, image: UIImage?, style: ZLInputTextStyle) {
        guard !text.isEmpty, let image = image else { return }
        
        let scale = mainScrollView.zoomScale
        let size = ZLTextStickerView.calculateSize(image: image)
        let originFrame = getStickerOriginFrame(size)
        
        let textSticker = ZLTextStickerView(
            text: text,
            textColor: textColor,
            font: font,
            style: style,
            image: image,
            originScale: 1 / scale,
            originAngle: -currentClipStatus.angle,
            originFrame: originFrame
        )
        addSticker(textSticker)
    }
    
    func addSticker(_ sticker: ZLBaseStickerView) {
        stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame
        configSticker(sticker)
        editorManager.storeAction(.sticker(oldState: nil, newState: sticker.state))
        selectSticker(sticker: sticker)
        
        // handle back to select after adding stiker into image
        selectBtnClick()
        editToolCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
        editToolCollectionView.reloadData()
    }
    
    public func removeSticker(id: String?) {
        guard let id else { return }
        
        for sticker in stickersContainer.subviews.reversed() {
            guard let stickerID = (sticker as? ZLBaseStickerView)?.id,
                  stickerID == id else {
                continue
            }
            
            (sticker as? ZLBaseStickerView)?.remove()
            
            break
        }
    }
    
    func configSticker(_ sticker: ZLBaseStickerView) {
        sticker.delegate = self
        mainScrollView.pinchGestureRecognizer?.require(toFail: sticker.pinchGes)
        mainScrollView.panGestureRecognizer.require(toFail: sticker.panGes)
        panGes.require(toFail: sticker.panGes)
    }
    
    func recalculateStickersFrame(_ oldSize: CGSize, _ oldAngle: CGFloat, _ newAngle: CGFloat) {
        let currSize = stickersContainer.frame.size
        let scale: CGFloat
        if Int(newAngle - oldAngle) % 180 == 0 {
            scale = currSize.width / oldSize.width
        } else {
            scale = currSize.height / oldSize.width
        }
        
        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.addScale(scale)
        }
    }
    
    func drawLine() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(
            mainScrollView.frame.width / currentClipStatus.editRect.width,
            mainScrollView.frame.height / currentClipStatus.editRect.height
        )
        let scale = ratio / originalRatio
        // Zoom to original size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if shouldSwapSize {
            swap(&size.width, &size.height)
        }
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale
        
        drawingImageView.image = UIGraphicsImageRenderer.zl.renderImage(size: size) { context in
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            for path in drawPaths {
                path.drawPath()
            }
        }
    }
    
    public func changeFilter(_ filter: ZLFilter) {
        func adjustImage(_ image: UIImage) -> UIImage {
            guard tools.contains(.adjust), !currentAdjustStatus.allValueIsZero else {
                return image
            }
            
            return image.zl.adjust(
                brightness: currentAdjustStatus.brightness,
                contrast: currentAdjustStatus.contrast,
                saturation: currentAdjustStatus.saturation
            ) ?? image
        }
        
        currentFilter = filter
        if let image = filterImages[currentFilter.name] {
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
        } else {
            let image = currentFilter.applier?(originalImage) ?? originalImage
            editImage = adjustImage(image)
            editImageWithoutAdjust = image
            filterImages[currentFilter.name] = image
        }
        
        if tools.contains(.mosaic) {
            generateNewMosaicImageLayer()
            
            if mosaicPaths.isEmpty {
                imageView.image = editImage
            } else {
                generateNewMosaicImage()
            }
        } else {
            imageView.image = editImage
        }
    }
    
    func generateNewMosaicImageLayer() {
        mosaicImage = editImage.zl.mosaicImage()
        
        mosaicImageLayer?.removeFromSuperlayer()
        
        mosaicImageLayer = CALayer()
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayer?.contents = mosaicImage?.cgImage
        imageView.layer.insertSublayer(mosaicImageLayer!, below: mosaicImageLayerMaskLayer)
        
        mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
    }
    
    /// 传入inputImage 和 inputMosaicImage则代表仅想要获取新生成的mosaic图片
    @discardableResult
    func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        let renderRect = CGRect(origin: .zero, size: originalImage.size)
        
        var midImage = UIGraphicsImageRenderer.zl.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { context in
            if inputImage != nil {
                inputImage?.draw(in: renderRect)
            } else {
                var drawImage: UIImage?
                if tools.contains(.filter), let image = filterImages[currentFilter.name] {
                    drawImage = image
                } else {
                    drawImage = originalImage
                }
                
                drawImage?.draw(at: .zero)
                if tools.contains(.adjust), !currentAdjustStatus.allValueIsZero {
                    drawImage = drawImage?.zl.adjust(
                        brightness: currentAdjustStatus.brightness,
                        contrast: currentAdjustStatus.contrast,
                        saturation: currentAdjustStatus.saturation
                    )
                }
                
                drawImage?.draw(in: renderRect)
            }
            
            mosaicPaths.forEach { path in
                context.move(to: path.startPoint)
                path.linePoints.forEach { point in
                    context.addLine(to: point)
                }
                context.setLineWidth(path.path.lineWidth / path.ratio)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.setBlendMode(.clear)
                context.strokePath()
            }
        }
        
        guard let midCgImage = midImage.cgImage else { return nil }
        midImage = UIImage(cgImage: midCgImage, scale: editImage.scale, orientation: .up)
        
        let temp = UIGraphicsImageRenderer.zl.renderImage(size: originalImage.size) { format in
            format.scale = self.originalImage.scale
        } imageActions: { _ in
            // 由于生成的mosaic图片可能在边缘区域出现空白部分，导致合成后会有黑边，所以在最下面先画一张原图
            originalImage.draw(in: renderRect)
            (inputMosaicImage ?? mosaicImage)?.draw(in: renderRect)
            midImage.draw(at: .zero)
        }
        
        guard let cgi = temp.cgImage else { return nil }
        let image = UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
        
        if inputImage != nil {
            return image
        }
        
        editImage = image
        imageView.image = image
        mosaicImageLayerMaskLayer?.path = nil
        
        return image
    }
    
    func buildImage() -> UIImage {
        let imageSize = originalImage.size
        
        let temp = UIGraphicsImageRenderer.zl.renderImage(size: editImage.size) { format in
            format.scale = self.editImage.scale
        } imageActions: { context in
            editImage.draw(at: .zero)
            
            if !stickersContainer.subviews.isEmpty {
                let scale = self.imageSize.width / stickersContainer.frame.width
                stickersContainer.subviews.forEach { view in
                    (view as? ZLStickerViewAdditional)?.resetState()
                }
                context.concatenate(CGAffineTransform(scaleX: scale, y: scale))
                stickersContainer.layer.render(in: context)
                context.concatenate(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
            }
        }
        
        guard let cgi = temp.cgImage else {
            return editImage
        }
        return UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
    }
    
    func finishClipDismissAnimate() {
        mainScrollView.alpha = 1
        UIView.animate(withDuration: 0.1) {
            self.topShadowView.alpha = 1
            self.bottomShadowView.alpha = 1
            self.adjustSlider?.alpha = 1
        }
    }
    
    func selectSticker(sticker: ZLBaseStickerView) {
        unselectSticker()
        
        setToolView(show: true)
        
        currentSticker = sticker
        currentSticker?.showBorder()
        
        if currentSticker is ZLShapeView {
            shapeStyleSelectorView.setInitialStyle(strokeColor: (currentSticker as! ZLShapeView).strokeColor, fillColor: (currentSticker as! ZLShapeView).fillColor, strokeWidth: (currentSticker as! ZLShapeView).lineWidth, strokeStyle: (currentSticker as! ZLShapeView).strokeStyle)
        } else if currentSticker is ZLLineView {
            shapeStyleSelectorView.setInitialStyle(strokeColor: (currentSticker as! ZLLineView).color, fillColor: nil, strokeWidth: (currentSticker as! ZLLineView).lineWidth, strokeStyle: (currentSticker as! ZLLineView).strokeStyle)
        } else if currentSticker is ZLArrowView {
            shapeStyleSelectorView.setInitialStyle(strokeColor: (currentSticker as! ZLArrowView).color, fillColor: nil, strokeWidth: (currentSticker as! ZLArrowView).lineWidth, strokeStyle: (currentSticker as! ZLArrowView).strokeStyle)
        } else if currentSticker is ZLFreehandDrawView {
            shapeStyleSelectorView.setInitialStyle(strokeColor: (currentSticker as! ZLFreehandDrawView).color, fillColor: nil, strokeWidth: (currentSticker as! ZLFreehandDrawView).lineWidth, strokeStyle: nil)
        }
        
        updateTopBarButtonsForSelectedSticker()
    }
    
    func unselectSticker() {
        currentSticker?.hideBorder()
        currentSticker = nil
        
        updateTopBarButtonsForSelectedSticker()
    }
}


