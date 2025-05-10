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

class ShapeStyleSelectorView: UIView {

    weak var delegate: ShapeStyleSelectorViewDelegate?

    private let strokeColors: [UIColor] = ZLImageEditorConfiguration.default().drawColors
    private let fillColors: [UIColor] = [.clear] + ZLImageEditorConfiguration.default().drawColors
    private let strokeWidths: [(label: String, value: CGFloat)] = [("Small", 1), ("Medium", 3), ("Bold", 6)]
    private let strokeStyles: [String] = ["Solid", "Dashed", "Dotted"]

    private let stackView = UIStackView()
    private var selectedStrokeColorButton: UIButton?
    private var strokeColorButtons: [UIButton] = []
    private var selectedFillColorButton: UIButton?
    private var fillColorButtons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 10
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.1
        self.layer.shadowOffset = CGSize(width: 0, height: 2)

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12)
        ])

        addSection(title: "Stroke color", items: strokeColors.map { setupStrokeColorButton(color: $0)}, scrollable: true)
        addSection(title: "Fill color", items: fillColors.map { setupFillColorButton(color: $0)}, scrollable: true)
//        addSection(title: "Stroke width", items: strokeWidths.map { textButton(title: $0.label, action: #selector(strokeWidthSelected(_:))) })
//        addSection(title: "Stroke style", items: strokeStyles.map { textButton(title: $0, action: #selector(strokeStyleSelected(_:))) })
    }

    private func addSection(title: String, items: [UIView], scrollable: Bool = false) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 14)
        stackView.addArrangedSubview(titleLabel)

        let contentStack = UIStackView(arrangedSubviews: items)
        contentStack.axis = .horizontal
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        if scrollable {
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsHorizontalScrollIndicator = false

            scrollView.addSubview(contentStack)
            
            stackView.addArrangedSubview(scrollView)

            NSLayoutConstraint.activate([
                contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
                contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                contentStack.heightAnchor.constraint(equalToConstant: 30),
                scrollView.heightAnchor.constraint(equalToConstant: 30),
                scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
            ])
        } else {
            stackView.addArrangedSubview(contentStack)
        }
    }
    
    private func setupStrokeColorButton(color: UIColor) -> UIButton {
        let button = colorButton(color: color)
        button.addTarget(self, action: #selector(strokeColorButtonTapped(_:)), for: .touchUpInside)
        strokeColorButtons.append(button)
        return button
    }
    
    private func setupFillColorButton(color: UIColor) -> UIButton {
        let button = colorButton(color: color)
        button.addTarget(self, action: #selector(fillColorButtonTapped(_:)), for: .touchUpInside)
        strokeColorButtons.append(button)
        return button
    }

    private func colorButton(color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = color.cgColor
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        if color == UIColor.white {
            button.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
        }

        if color == .clear {
            button.setImage(.zl.getImage("zl_transparent"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.backgroundColor = color
            button.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
            button.tintColor = UIColor(white: 0.8, alpha: 1)
        } else {
            button.backgroundColor = color
        }
        
        return button
    }
    
    @objc private func strokeColorButtonTapped(_ sender: UIButton) {
        strokeColorButtons.forEach {
            if $0.layer.backgroundColor == UIColor.white.cgColor {
                $0.layer.borderColor = UIColor.lightGray.cgColor
            } else {
                $0.layer.borderColor = $0.layer.backgroundColor
            }
        }
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        selectedStrokeColorButton = sender
        delegate?.didSelectStrokeColor(sender.backgroundColor ?? .black)
    }
    
    @objc private func fillColorButtonTapped(_ sender: UIButton) {
        fillColorButtons.forEach {
            if $0.layer.backgroundColor == UIColor.white.cgColor {
                $0.layer.borderColor = UIColor.lightGray.cgColor
            } else {
                $0.layer.borderColor = $0.layer.backgroundColor
            }
        }
        sender.layer.borderWidth = 2
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        selectedFillColorButton = sender
        delegate?.didSelectFillColor(sender.backgroundColor ?? .black)
    }

    private func textButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    func setInitialStyle(strokeColor: UIColor?, fillColor: UIColor?, strokeWidth: CGFloat?, strokeStyle: String?) {
        if let strokeColor = strokeColor {
            let button = strokeColorButtons.first { $0.backgroundColor?.cgColor == strokeColor.cgColor }
            if let button = button {
                strokeColorButtonTapped(button)
            }
        }
        
        if let fillColor = fillColor {
            let button = fillColorButtons.first { $0.backgroundColor?.cgColor == fillColor.cgColor }
            if let button = button {
                fillColorButtonTapped(button)
            }
        }
        if let strokeWidth = strokeWidth {
            // Optional: Highlight stroke width button
        }
        if let strokeStyle = strokeStyle {
            // Optional: Highlight stroke style button
        }
    }

    @objc private func strokeWidthSelected(_ sender: UIButton) {
        guard let title = sender.title(for: .normal),
              let width = strokeWidths.first(where: { $0.label == title })?.value else { return }
        delegate?.didSelectStrokeWidth(width)
    }

    @objc private func strokeStyleSelected(_ sender: UIButton) {
        guard let style = sender.title(for: .normal) else { return }
        delegate?.didSelectStrokeStyle(style)
    }
}
