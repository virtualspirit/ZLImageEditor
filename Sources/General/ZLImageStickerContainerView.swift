//
//  ZLImageStickerContainerView.swift
//  ZLImageEditor
//
//  Created by long on 2020/11/20.
//

import UIKit
import SDWebImage

public class ZLImageStickerContainerView: UIView, ZLImageStickerContainerDelegate {
    
    static let baseViewH: CGFloat = 400
    
    public var baseView: UIView!
    
    public var collectionView: UICollectionView!
    
    public var selectImageBlock: ((UIImage) -> Void)?
    
    public var hideBlock: (() -> Void)?
    
    var datas: [String] {
        return ZLImageEditorConfiguration.default().imageStickerFiles
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.frame.width, height: ZLImageStickerContainerView.baseViewH), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 8, height: 8))
        self.baseView.layer.mask = nil
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        self.baseView.layer.mask = maskLayer
    }
    
    func setupUI() {
        self.baseView = UIView()
        self.addSubview(self.baseView)
        self.baseView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.baseView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.baseView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.baseView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: ZLImageStickerContainerView.baseViewH),
            self.baseView.heightAnchor.constraint(equalToConstant: ZLImageStickerContainerView.baseViewH)
        ])
        
        let visualView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.baseView.addSubview(visualView)
        visualView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualView.topAnchor.constraint(equalTo: self.baseView.topAnchor),
            visualView.bottomAnchor.constraint(equalTo: self.baseView.bottomAnchor),
            visualView.leftAnchor.constraint(equalTo: self.baseView.leftAnchor),
            visualView.rightAnchor.constraint(equalTo: self.baseView.rightAnchor)
        ])
        
        let toolView = UIView()
        toolView.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        self.baseView.addSubview(toolView)
        toolView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolView.topAnchor.constraint(equalTo: self.baseView.topAnchor),
            toolView.leftAnchor.constraint(equalTo: self.baseView.leftAnchor),
            toolView.rightAnchor.constraint(equalTo: self.baseView.rightAnchor),
            toolView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let hideBtn = UIButton(type: .custom)
        hideBtn.setImage(UIImage(named: "close"), for: .normal)
        hideBtn.backgroundColor = .clear
        hideBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        hideBtn.addTarget(self, action: #selector(hideBtnClick), for: .touchUpInside)
        toolView.addSubview(hideBtn)
        hideBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hideBtn.centerYAnchor.constraint(equalTo: toolView.centerYAnchor),
            hideBtn.rightAnchor.constraint(equalTo: toolView.rightAnchor, constant: -20),
            hideBtn.widthAnchor.constraint(equalToConstant: 40),
            hideBtn.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.baseView.addSubview(self.collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: toolView.bottomAnchor),
            self.collectionView.leftAnchor.constraint(equalTo: self.baseView.leftAnchor),
            self.collectionView.rightAnchor.constraint(equalTo: self.baseView.rightAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.baseView.bottomAnchor)
        ])
        
        self.collectionView.register(ZLImageStickerCell.self, forCellWithReuseIdentifier: NSStringFromClass(ZLImageStickerCell.classForCoder()))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideBtnClick))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    @objc func hideBtnClick() {
        self.hide()
    }
    
    public func show(in view: UIView) {
        if self.superview !== view {
            self.removeFromSuperview()
            
            view.addSubview(self)
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.topAnchor.constraint(equalTo: view.topAnchor),
                self.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                self.leftAnchor.constraint(equalTo: view.leftAnchor),
                self.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
            view.layoutIfNeeded()
        }
        
        self.isHidden = false
        UIView.animate(withDuration: 0.25) {
            // Update constraint to show
            if let bottomConstraint = self.baseView.constraints.first(where: { $0.firstAttribute == .bottom && $0.firstItem === self.baseView }) {
                bottomConstraint.constant = 0
            } else {
                // Fallback if constraint not found easily, though it should be there.
                // Re-activating might be needed if we didn't store reference.
                // For simplicity in this migration without stored properties, we iterate.
                // Actually, standard way is to keep reference.
                // Let's try to find it in self.baseView.constraints (which are added to self.baseView? No, constraints between self and baseView are added to self)
                
                for constraint in self.constraints {
                    if constraint.firstItem === self.baseView && constraint.firstAttribute == .bottom {
                        constraint.constant = 0
                    }
                }
            }
            
            view.layoutIfNeeded()
        }
    }
    
    public func hide() {
        self.hideBlock?()
        
        UIView.animate(withDuration: 0.25) {
            for constraint in self.constraints {
                if constraint.firstItem === self.baseView && constraint.firstAttribute == .bottom {
                    constraint.constant = ZLImageStickerContainerView.baseViewH
                }
            }
            self.superview?.layoutIfNeeded()
        } completion: { (_) in
            self.isHidden = true
        }

    }
    
}


extension ZLImageStickerContainerView: UIGestureRecognizerDelegate {
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        return !self.baseView.frame.contains(location)
    }
    
}


extension ZLImageStickerContainerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let column: CGFloat = 4
        let spacing: CGFloat = 20 + 5 * (column - 1)
        let w = (collectionView.frame.width - spacing) / column
        return CGSize(width: w, height: w)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.datas.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ZLImageStickerCell.classForCoder()), for: indexPath) as! ZLImageStickerCell
        
        let path = self.datas[indexPath.row]
        if let url = URL(string: path), (path.hasPrefix("http") || path.hasPrefix("https")) {
            cell.imageView.sd_setImage(with: url)
        } else {
            cell.imageView.image = UIImage(named: path)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let path = self.datas[indexPath.row]
        if let url = URL(string: path), (path.hasPrefix("http") || path.hasPrefix("https")) {
            SDWebImageManager.shared.loadImage(with: url, options: .highPriority, progress: nil) { (image, _, _, _, _, _) in
                if let image = image {
                    self.selectImageBlock?(image)
                    self.hide()
                }
            }
        } else {
            guard let image = UIImage(named: path) else {
                return
            }
            self.selectImageBlock?(image)
            self.hide()
        }
    }
    
}


class ZLImageStickerCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
