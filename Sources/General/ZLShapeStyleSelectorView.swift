//
//  ZLShapeStyleSelectorView.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

import UIKit

protocol ShapeStyleSelectorViewDelegate: AnyObject {
    func didSelectStrokeColor(_ color: UIColor)
    func didSelectFillColor(_ color: UIColor)
    func didSelectStrokeWidth(_ width: CGFloat)
    func didSelectStrokeStyle(_ style: String)
}

class ShapeStyleSelectorView: UIView, UIGestureRecognizerDelegate {

    weak var delegate: ShapeStyleSelectorViewDelegate?

    private let strokeColors: [UIColor] = ZLImageEditorConfiguration.default().drawColors
    // Tambahkan .clear di awal untuk opsi "No Fill"
    private let fillColors: [UIColor] = [UIColor.clear] + ZLImageEditorConfiguration.default().drawColors
    private let strokeWidths: [(label: String, value: CGFloat)] = [("Small", ZLStrokeWidthConstants.small), ("Medium", ZLStrokeWidthConstants.medium), ("Large", ZLStrokeWidthConstants.large)] // Sesuaikan nilai jika perlu
    private let strokeStyles: [(label: String, value: String)] = [ // Gunakan enum jika lebih baik
         ("Solid", "solid"),    // .butt biasanya menghasilkan garis solid standar
         ("Dashed", "dashed"), // Untuk dashed/dotted, kita perlu menggambar path secara manual
         ("Dotted", "dotted")   // atau menggunakan lineDashPattern pada CAShapeLayer
     ]
    private let mainStackView = UIStackView()

    // Views untuk bagian Stroke Color
    private var strokeColorTitleLabel: UILabel!
    private var strokeColorScrollView: UIScrollView!
    private var strokeColorButtons: [UIButton] = []
    private var selectedStrokeColorButton: UIButton?

    // Views untuk bagian Fill Color (Container untuk title + scrollview)
    private var fillColorSectionContainer: UIView!
    private var fillColorTitleLabel: UILabel!
    private var fillColorScrollView: UIScrollView!
    private var fillColorButtons: [UIButton] = []
    private var selectedFillColorButton: UIButton?
    
    // Views untuk bagian Stroke Width
    private var strokeWidthTitleLabel: UILabel!
    private var strokeWidthStackView: UIStackView!
    private var strokeWidthButtons: [UIButton] = []
    private var selectedStrokeWidthButton: UIButton?
    
    // Views untuk bagian Stroke Style
    private var strokeStyleTitleLabel: UILabel!
     private var strokeStyleStackView: UIStackView!
     private var strokeStyleButtons: [UIButton] = []
     private var selectedStrokeStyleButton: UIButton?

    public var showFillColorOptions: Bool = false {
        didSet {
            if oldValue != showFillColorOptions {
                fillColorSectionContainer.isHidden = !showFillColorOptions
                // Trigger re-layout of the main stack view if needed
                UIView.animate(withDuration: 0.2) {
                    self.layoutIfNeeded()
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        // Defaultnya, opsi fill disembunyikan sampai diatur oleh controller
        self.showFillColorOptions = false
        self.fillColorSectionContainer.isHidden = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        self.showFillColorOptions = false
        self.fillColorSectionContainer.isHidden = true
    }

    private func setupView() {
        let internalTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleInternalTap))
        self.addGestureRecognizer(internalTapGesture)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.75) // Latar belakang semi-transparan gelap
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = false // Jika menggunakan blur effect, ini mungkin perlu false

         let blurEffect = UIBlurEffect(style: .dark)
         let blurView = UIVisualEffectView(effect: blurEffect)
         blurView.translatesAutoresizingMaskIntoConstraints = false
         addSubview(blurView)
         NSLayoutConstraint.activate([
             blurView.topAnchor.constraint(equalTo: topAnchor),
             blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
             blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
             blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
         ])
         insertSubview(mainStackView, aboveSubview: blurView) // Pastikan stackView di atas blur

        mainStackView.axis = .vertical
        mainStackView.spacing = 16 // Spasi antar section
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -16) // Kurang dari atau sama dengan untuk fleksibilitas tinggi
        ])

        setupStrokeColorSection()
        setupFillColorSection()
        setupStrokeWidthSection()
        setupStrokeStyleSection()
    }

    private func createTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .white // Warna teks untuk kontras
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }
    
    private func createColorButton(color: UIColor, action: Selector, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag // Untuk identifikasi warna
        button.layer.cornerRadius = 15 // Ukuran button 30x30
        button.clipsToBounds = true
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor // Border awal transparan
        button.addTarget(self, action: action, for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        if color == .clear { // Tombol "No Fill"
            button.backgroundColor = .clear // Latar belakang gelap agar garis terlihat
            let noFillImage = UIImage.zl.getImage("zl_transparent")?.withRenderingMode(.alwaysTemplate) // Pastikan gambar ada
            button.setImage(noFillImage, for: .normal)
            button.imageView?.contentMode = .scaleAspectFill
            button.tintColor = UIColor.white
        } else {
            button.backgroundColor = color
        }
        return button
    }
    
    private func createScrollViewForButtons(_ buttons: [UIButton]) -> UIScrollView {
        let buttonStackView = UIStackView(arrangedSubviews: buttons)
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 10
        buttonStackView.alignment = .center
        buttonStackView.distribution = .fillProportionally // Atau .equalSpacing
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(buttonStackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            buttonStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 30) // Tinggi baris warna
        ])
        return scrollView
    }

    private func setupStrokeColorSection() {
        strokeColorTitleLabel = createTitleLabel(text: "Stroke Color")
        mainStackView.addArrangedSubview(strokeColorTitleLabel)
        if #available(iOS 11.0, *) {
            mainStackView.setCustomSpacing(8, after: strokeColorTitleLabel)
        } else {
            // Fallback on earlier versions
        }


        for (index, color) in strokeColors.enumerated() {
            strokeColorButtons.append(createColorButton(color: color, action: #selector(strokeColorButtonTapped(_:)), tag: index))
        }
        strokeColorScrollView = createScrollViewForButtons(strokeColorButtons)
        mainStackView.addArrangedSubview(strokeColorScrollView)
    }

    private func setupFillColorSection() {
        fillColorTitleLabel = createTitleLabel(text: "Fill Color")
        
        for (index, color) in fillColors.enumerated() {
            fillColorButtons.append(createColorButton(color: color, action: #selector(fillColorButtonTapped(_:)), tag: index))
        }
        fillColorScrollView = createScrollViewForButtons(fillColorButtons)
        
        // Container untuk fill color section
        fillColorSectionContainer = UIStackView(arrangedSubviews: [fillColorTitleLabel, fillColorScrollView])
        (fillColorSectionContainer as! UIStackView).axis = .vertical
        (fillColorSectionContainer as! UIStackView).spacing = 8
        (fillColorSectionContainer as! UIStackView).alignment = .fill
        fillColorSectionContainer.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(fillColorSectionContainer)
    }
    
    private func setupStrokeWidthSection() {
        strokeWidthTitleLabel = createTitleLabel(text: "Stroke Width")
        mainStackView.addArrangedSubview(strokeWidthTitleLabel)
        if #available(iOS 11.0, *) {
            mainStackView.setCustomSpacing(8, after: strokeWidthTitleLabel)
        } else {
            // Fallback on earlier versions
        }

        for (index, widthItem) in strokeWidths.enumerated() {
            strokeWidthButtons.append(createTextButton(title: widthItem.label, action: #selector(strokeWidthButtonTapped(_:)), tag: index))
        }
        strokeWidthStackView = UIStackView(arrangedSubviews: strokeWidthButtons)
        strokeWidthStackView.axis = .horizontal
        strokeWidthStackView.spacing = 8
        strokeWidthStackView.distribution = .fillEqually
        strokeWidthStackView.translatesAutoresizingMaskIntoConstraints = false
        
        mainStackView.addArrangedSubview(strokeWidthStackView)
        strokeWidthStackView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    private func createTextButton(title: String, action: Selector, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        return button
    }

    @objc private func strokeColorButtonTapped(_ sender: UIButton) {
        if (sender == selectedStrokeColorButton)  {
            return
        }
        
        selectedStrokeColorButton?.isSelected = false
        selectedStrokeColorButton?.layer.borderColor = UIColor.clear.cgColor
         if selectedStrokeColorButton?.backgroundColor != .clear {
            selectedStrokeColorButton?.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        }


        sender.isSelected = true
        sender.layer.borderColor = UIColor.zl.editDoneBtnBgColor.cgColor // Warna highlight
        selectedStrokeColorButton = sender
        
        delegate?.didSelectStrokeColor(sender.backgroundColor ?? .black)
    }

    @objc private func fillColorButtonTapped(_ sender: UIButton) {
        if (sender == selectedFillColorButton)  {
            return
        }
        
        selectedFillColorButton?.isSelected = false
        selectedFillColorButton?.layer.borderColor = UIColor.clear.cgColor
        if selectedFillColorButton?.backgroundColor != .clear {
             selectedFillColorButton?.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        }
        if selectedFillColorButton?.backgroundColor == .clear {
            selectedFillColorButton?.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        }

        sender.isSelected = true
        sender.layer.borderColor = UIColor.zl.editDoneBtnBgColor.cgColor // Warna highlight
        selectedFillColorButton = sender
        
        delegate?.didSelectFillColor(sender.backgroundColor ?? .clear) // .clear akan dihandle sebagai nil
    }
    
    @objc private func strokeWidthButtonTapped(_ sender: UIButton) {
        if (sender == selectedStrokeWidthButton)  {
            return
        }
        
        selectedStrokeWidthButton?.isSelected = false
        selectedStrokeWidthButton?.backgroundColor = UIColor.white.withAlphaComponent(0.1)

        sender.isSelected = true
        sender.backgroundColor = UIColor.zl.editDoneBtnBgColor
        selectedStrokeWidthButton = sender
        
        let widthItem = strokeWidths[sender.tag]
        delegate?.didSelectStrokeWidth(widthItem.value)
    }

    func setInitialStyle(strokeColor: UIColor?, fillColor: UIColor?, strokeWidth: CGFloat?, strokeStyle: String?) {
        // Set Stroke Color
        if let strokeColor = strokeColor, let index = strokeColors.firstIndex(of: strokeColor) {
            strokeColorButtonTapped(strokeColorButtons[index])
        } else if let firstButton = strokeColorButtons.first { // Default ke warna pertama jika tidak ada
            strokeColorButtonTapped(firstButton)
        }

        // Set Fill Color (hanya jika opsi fill ditampilkan)
        if showFillColorOptions {
            let targetFillColor = fillColor ?? .clear // Jika nil, anggap .clear (opsi "No Fill")
            if let index = fillColors.firstIndex(of: targetFillColor) {
                fillColorButtonTapped(fillColorButtons[index])
            } else if let firstButton = fillColorButtons.first { // Default ke warna pertama (yaitu .clear)
                fillColorButtonTapped(firstButton)
            }
        }
        
        // Set Stroke Width
        if let strokeWidth = strokeWidth, let index = strokeWidths.firstIndex(where: { abs($0.value - strokeWidth) < 0.1 }) {
            strokeWidthButtonTapped(strokeWidthButtons[index])
        } else if let firstButton = strokeWidthButtons.first { // Default
             strokeWidthButtonTapped(firstButton)
        }

        // Set Stroke Style
        if let strokeStyle = strokeStyle, let index = strokeStyles.firstIndex(where: { $0.value == strokeStyle }) {
             strokeStyleButtonTapped(strokeStyleButtons[index])
         } else if let firstButton = strokeStyleButtons.first { // Default ke gaya pertama (misalnya "Solid")
              strokeStyleButtonTapped(firstButton)
         }
    }
    
    private func setupStrokeStyleSection() {
        strokeStyleTitleLabel = createTitleLabel(text: "Stroke Style")
        mainStackView.addArrangedSubview(strokeStyleTitleLabel)
        if #available(iOS 11.0, *) {
            mainStackView.setCustomSpacing(8, after: strokeStyleTitleLabel)
        } else {
            // Fallback on earlier versions
        }

        for (index, styleItem) in strokeStyles.enumerated() {
            // Tombol akan menampilkan styleItem.label
            strokeStyleButtons.append(createTextButton(title: styleItem.label, action: #selector(strokeStyleButtonTapped(_:)), tag: index))
        }
        strokeStyleStackView = UIStackView(arrangedSubviews: strokeStyleButtons)
        strokeStyleStackView.axis = .horizontal
        strokeStyleStackView.spacing = 8
        strokeStyleStackView.distribution = .fillEqually // Atau .fillProportionally jika label berbeda panjang
        strokeStyleStackView.translatesAutoresizingMaskIntoConstraints = false
        
        mainStackView.addArrangedSubview(strokeStyleStackView)
        strokeStyleStackView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }

    @objc private func strokeStyleButtonTapped(_ sender: UIButton) {
        if (sender == selectedStrokeStyleButton)  {
            return
        }
        
        selectedStrokeStyleButton?.isSelected = false
        selectedStrokeStyleButton?.backgroundColor = UIColor.white.withAlphaComponent(0.1)

        sender.isSelected = true
        sender.backgroundColor = UIColor.zl.editDoneBtnBgColor // Highlight warna
        selectedStrokeStyleButton = sender
        
        let styleItem = strokeStyles[sender.tag]
        delegate?.didSelectStrokeStyle(styleItem.value)
    }
    
    @objc private func handleInternalTap(_ gesture: UITapGestureRecognizer) {
          // This method being called means the tap was on ShapeStyleSelectorView
          // and will prevent it from propagating further up to ZLEditImageViewController's tap.
          // No specific action needed here unless you want internal elements to react.
      }
}
