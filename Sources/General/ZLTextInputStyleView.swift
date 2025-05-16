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
}
