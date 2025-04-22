//
//  ZLDrawShapeCell.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 21/04/25.
//

import UIKit

enum DrawShapeType {
    case freehand
    case line
    case arrow
    case rectangle
    case ellipse
    // Add icons later
}

class ZLDrawShapeCell: UICollectionViewCell {
    static let identifier = "ZLDrawShapeCell"
    lazy var icon = UIImageView(frame: contentView.bounds)
    
    var shapeType: DrawShapeType = .freehand {
        didSet {
            switch shapeType {
            case .freehand:
                icon.image = .zl.getImage("zl_drawLine")
                icon.highlightedImage = .zl.getImage("zl_drawLine_selected")
            case .line:
                icon.image = .zl.getImage("zl_line")
                icon.highlightedImage = .zl.getImage("zl_line_selected")
            case .arrow:
                icon.image = .zl.getImage("zl_arrow")
                icon.highlightedImage = .zl.getImage("zl_arrow_selected")
            case .rectangle:
                icon.image = .zl.getImage("zl_square")
                icon.highlightedImage = .zl.getImage("zl_square_selected")
            case .ellipse:
                icon.image = .zl.getImage("zl_circle")
                icon.highlightedImage = .zl.getImage("zl_circle_selected")
            }
            
            if let color = UIColor.zl.toolIconHighlightedColor {
                icon.highlightedImage = icon.image?
                    .zl.fillColor(color)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 30), // Adjust size
            icon.heightAnchor.constraint(equalToConstant: 30) // Adjust size
        ])
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
