//
//  ZLTextInputStyle.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 13/05/25.
//

import UIKit

protocol ZLTextInputStyleViewDelegate: AnyObject {
    func didSelectTextColor(_ color: UIColor)
    func didSelectFillColor(_ color: UIColor)
    func didSelectFontSize(_ fontSize: CGFloat)
    func didSelectFontStyle(isBold: Bool, isItalic: Bool)
}

class ZLTextInputStyleView: UIView {
    weak var delegate: ZLTextInputStyleViewDelegate?
    
    private let textColors: [UIColor] = ZLImageEditorConfiguration.default().drawColors

    private let fillColors: [UIColor] = [UIColor.clear] + ZLImageEditorConfiguration.default().drawColors
        
    private let mainStackView = UIStackView()
    
    private var textColorTitleLabel: UILabel!
    private var textColorScrollView: UIScrollView!
    private var textColorButtons: [UIButton] = []
    private var selectedTextColorButton: UIButton?
    
    private var fillColorSectionContainer: UIView!
    private var fillColorTitleLabel: UILabel!
    private var fillColorScrollView: UIScrollView!
    private var fillColorButtons: [UIButton] = []
    private var selectedFillColorButton: UIButton?
    
    // Font Size
     private var fontSizeTitleLabel: UILabel!
     private var fontSizeSlider: UISlider!
     private var fontSizeValueLabel: UILabel! // Displays the current font size

     // Font Style
     private var fontStyleTitleLabel: UILabel!
     private var fontStyleStackView: UIStackView! // Horizontal stack for style buttons
     private var normalStyleButton: UIButton! // Or keep this implicit
     private var boldStyleButton: UIButton!
     private var italicStyleButton: UIButton!
    
    // State for new controls
    private var currentFontSize: CGFloat = ZLImageEditorConfiguration.default().defaultFontSize { // Default initial font size
        didSet {
            fontSizeValueLabel?.text = String(format: "%.0f", currentFontSize)
        }
    }
    private var isBoldSelected: Bool = false
    private var isItalicSelected: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .clear
        self.layer.masksToBounds = true
        
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
        mainStackView.spacing = 16
        mainStackView.alignment = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -16) // Kurang dari atau sama dengan untuk fleksibilitas tinggi
        ])
        
        setupTextColorSection()
        setupFillColorSection()
        setupFontSizeSection()
//        setupFontStyleSection()
        
        updateFontSizeSliderAndLabel()
//        updateFontStyleButtonsAppearance()
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
    
    private func setupTextColorSection() {
        textColorTitleLabel = createTitleLabel(text: "Text Color")
        mainStackView.addArrangedSubview(textColorTitleLabel)
        if #available(iOS 11.0, *) {
            mainStackView.setCustomSpacing(8, after: textColorTitleLabel)
        } else {
            // Fallback on earlier versions
        }


        for (index, color) in textColors.enumerated() {
            textColorButtons.append(createColorButton(color: color, action: #selector(textColorButtonTapped(_:)), tag: index))
        }
        textColorScrollView = createScrollViewForButtons(textColorButtons)
        mainStackView.addArrangedSubview(textColorScrollView)
    }

    private func setupFillColorSection() {
        fillColorTitleLabel = createTitleLabel(text: "Background Color")
        
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
    
    @objc private func textColorButtonTapped(_ sender: UIButton) {
        if (sender == selectedTextColorButton)  {
            return
        }
        
        selectedTextColorButton?.isSelected = false
        selectedTextColorButton?.layer.borderColor = UIColor.clear.cgColor
         if selectedTextColorButton?.backgroundColor != .clear {
             selectedTextColorButton?.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        }


        sender.isSelected = true
        sender.layer.borderColor = UIColor.zl.editDoneBtnBgColor.cgColor // Warna highlight
        selectedTextColorButton = sender
        
        delegate?.didSelectTextColor(sender.backgroundColor ?? .black)
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
    
    private func setupFontSizeSection() {
            fontSizeTitleLabel = createTitleLabel(text: "Font Size")
            mainStackView.addArrangedSubview(fontSizeTitleLabel)
            if #available(iOS 11.0, *) {
                mainStackView.setCustomSpacing(8, after: fontSizeTitleLabel)
            }

            let sliderContainer = UIStackView()
            sliderContainer.axis = .horizontal
            sliderContainer.spacing = 8
            sliderContainer.alignment = .center

            fontSizeSlider = UISlider()
            fontSizeSlider.minimumValue = 12 // Sensible min
            fontSizeSlider.maximumValue = 72 // Sensible max
            fontSizeSlider.value = Float(currentFontSize)
            fontSizeSlider.addTarget(self, action: #selector(fontSizeSliderChanged(_:)), for: .valueChanged)
            fontSizeSlider.tintColor = .zl.editDoneBtnBgColor // Match theme
            fontSizeSlider.setContentHuggingPriority(.defaultLow, for: .horizontal)
            sliderContainer.addArrangedSubview(fontSizeSlider)

            fontSizeValueLabel = UILabel()
            fontSizeValueLabel.font = .systemFont(ofSize: 12)
            fontSizeValueLabel.textColor = .white
            fontSizeValueLabel.textAlignment = .right
            fontSizeValueLabel.text = String(format: "%.0f", currentFontSize)
            fontSizeValueLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                fontSizeValueLabel.widthAnchor.constraint(equalToConstant: 30) // Fixed width for the label
            ])
            sliderContainer.addArrangedSubview(fontSizeValueLabel)

            mainStackView.addArrangedSubview(sliderContainer)
        }

        @objc private func fontSizeSliderChanged(_ sender: UISlider) {
            currentFontSize = CGFloat(sender.value)
            // fontSizeValueLabel.text is updated by the didSet of currentFontSize
            delegate?.didSelectFontSize(currentFontSize)
        }

        private func updateFontSizeSliderAndLabel() {
            fontSizeSlider?.value = Float(currentFontSize)
            // fontSizeValueLabel.text is updated by the didSet of currentFontSize
        }
    
    private func setupFontStyleSection() {
           fontStyleTitleLabel = createTitleLabel(text: "Font Style")
           mainStackView.addArrangedSubview(fontStyleTitleLabel)
           if #available(iOS 11.0, *) {
               mainStackView.setCustomSpacing(8, after: fontStyleTitleLabel)
           }

           boldStyleButton = createStyleButton(title: "B", action: #selector(boldButtonTapped(_:)))
           boldStyleButton.titleLabel?.font = .boldSystemFont(ofSize: 15) // Make B bold

           italicStyleButton = createStyleButton(title: "I", action: #selector(italicButtonTapped(_:)))
           italicStyleButton.titleLabel?.font = .italicSystemFont(ofSize: 15) // Make I italic

           // 'Normal' button could be implicit or explicit.
           // For explicit, deselecting both Bold and Italic makes it Normal.
           // Or, add a "Normal" button that deselects Bold and Italic.
           // Let's go with toggle for Bold and Italic.

           fontStyleStackView = UIStackView(arrangedSubviews: [boldStyleButton, italicStyleButton]) // Add more style buttons here if needed
           fontStyleStackView.axis = .horizontal
           fontStyleStackView.spacing = 8
           fontStyleStackView.distribution = .fillEqually // Or .fillProportionally
           fontStyleStackView.translatesAutoresizingMaskIntoConstraints = false

           mainStackView.addArrangedSubview(fontStyleStackView)
           fontStyleStackView.heightAnchor.constraint(equalToConstant: 30).isActive = true
       }

       private func createStyleButton(title: String, action: Selector) -> UIButton {
           let button = UIButton(type: .custom) // Use custom for better control over selected state
           button.setTitle(title, for: .normal)
           button.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
           button.setTitleColor(.zl.editDoneBtnBgColor, for: .selected) // Highlighted text color
           button.titleLabel?.font = .systemFont(ofSize: 14)
           button.backgroundColor = UIColor.clear // Transparent background initially
           button.layer.cornerRadius = 5
           button.layer.borderWidth = 1
           button.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor // Border for unselected
           button.addTarget(self, action: action, for: .touchUpInside)
           button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
           return button
       }

       @objc private func boldButtonTapped(_ sender: UIButton) {
           isBoldSelected.toggle()
           updateFontStyleButtonsAppearance()
           delegate?.didSelectFontStyle(isBold: isBoldSelected, isItalic: isItalicSelected)
       }

       @objc private func italicButtonTapped(_ sender: UIButton) {
           isItalicSelected.toggle()
           updateFontStyleButtonsAppearance()
           delegate?.didSelectFontStyle(isBold: isBoldSelected, isItalic: isItalicSelected)
       }

       private func updateFontStyleButtonsAppearance() {
           // Bold Button
           boldStyleButton?.isSelected = isBoldSelected
           boldStyleButton?.backgroundColor = isBoldSelected ? .zl.editDoneBtnBgColor.withAlphaComponent(0.2) : .clear
           boldStyleButton?.layer.borderColor = isBoldSelected ? UIColor.zl.editDoneBtnBgColor.cgColor : UIColor.white.withAlphaComponent(0.7).cgColor

           // Italic Button
           italicStyleButton?.isSelected = isItalicSelected
           italicStyleButton?.backgroundColor = isItalicSelected ? .zl.editDoneBtnBgColor.withAlphaComponent(0.2) : .clear
           italicStyleButton?.layer.borderColor = isItalicSelected ? UIColor.zl.editDoneBtnBgColor.cgColor : UIColor.white.withAlphaComponent(0.7).cgColor
       }
    
    func setInitialStyle(
            textColor: UIColor?,
            fillColor: UIColor?,
            fontSize: CGFloat?,
            isBold: Bool?,
            isItalic: Bool?
        ) {
            // Set Text Color
            if let tc = textColor, let index = textColors.firstIndex(of: tc) {
                textColorButtonTapped(textColorButtons[index])
            } else if let firstButton = textColorButtons.first {
                textColorButtonTapped(firstButton)
            }

            // Set Fill Color
            let targetFillColor = fillColor ?? .clear
            if let index = fillColors.firstIndex(of: targetFillColor) {
                fillColorButtonTapped(fillColorButtons[index])
            } else if let firstButton = fillColorButtons.first {
                fillColorButtonTapped(firstButton)
            }

            // Set Font Size
            if let fs = fontSize {
                self.currentFontSize = fs
            } else {
                self.currentFontSize = ZLImageEditorConfiguration.default().defaultFontSize // Fallback
            }
            updateFontSizeSliderAndLabel() // Update slider and label from currentFontSize

            // Set Font Style
            self.isBoldSelected = isBold ?? false
            self.isItalicSelected = isItalic ?? false
            updateFontStyleButtonsAppearance()
        }
}
