//
//  ZLEditImageViewController+UICollectionViewDataSource+UICollectionViewDelegate.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

import UIKit


extension ZLEditImageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == editToolCollectionView {
            return tools.count
        } else if collectionView == drawColorCollectionView {
            return drawColors.count
        } else if collectionView == drawShapeCollectionView {
            return shapeOptions.count
        } else if collectionView == filterCollectionView {
            return thumbnailFilterImages.count
        } else {
            return adjustTools.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == editToolCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLEditToolCell.zl.identifier, for: indexPath) as! ZLEditToolCell
            let toolType = tools[indexPath.row]
            cell.icon.isHighlighted = false
            cell.toolType = toolType
            cell.icon.isHighlighted = toolType == selectedTool
            if ((selectedTool == .arrow || selectedTool == .circle || selectedTool == .draw || selectedTool == .line || selectedTool == .square) && toolType == .shape) {
                cell.icon.isHighlighted = true
            }
            return cell
        } else if collectionView == drawColorCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawColorCell.zl.identifier, for: indexPath) as! ZLDrawColorCell
            
            let c = drawColors[indexPath.row]
            cell.color = c
            if c == currentDrawColor, !eraserBtn.isSelected {
                cell.bgWhiteView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
            } else {
                cell.bgWhiteView.layer.transform = CATransform3DIdentity
            }
            
            return cell
        }else if collectionView == drawShapeCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawShapeCell.zl.identifier, for: indexPath) as! ZLDrawShapeCell
            let c = shapeOptions[indexPath.row]
            cell.icon.isHighlighted = false
            cell.shapeType = c
            cell.icon.isHighlighted = c == currentDrawShape
            return cell
        } else if collectionView == filterCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLFilterImageCell.zl.identifier, for: indexPath) as! ZLFilterImageCell
            
            let image = thumbnailFilterImages[indexPath.row]
            let filter = ZLImageEditorConfiguration.default().filters[indexPath.row]
            
            cell.nameLabel.text = filter.name
            cell.imageView.image = image
            
            if currentFilter === filter {
                cell.nameLabel.textColor = .zl.toolTitleTintColor
            } else {
                cell.nameLabel.textColor = .zl.toolTitleNormalColor
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLAdjustToolCell.zl.identifier, for: indexPath) as! ZLAdjustToolCell
            
            let tool = adjustTools[indexPath.row]
            
            cell.imageView.isHighlighted = false
            cell.adjustTool = tool
            let isSelected = tool == selectedAdjustTool
            cell.imageView.isHighlighted = isSelected
            
            if isSelected {
                cell.nameLabel.textColor = .zl.toolTitleTintColor
            } else {
                cell.nameLabel.textColor = .zl.toolTitleNormalColor
            }
            
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == editToolCollectionView {
            let toolType = tools[indexPath.row]
            switch toolType {
            case .shape:
                shapeBtnClick()
            case .clip:
                clipBtnClick()
            case .imageSticker:
                imageStickerBtnClick()
            case .textSticker:
                textStickerBtnClick()
            case .mosaic:
                mosaicBtnClick()
            case .filter:
                filterBtnClick()
            case .adjust:
                adjustBtnClick()
            case .line, .arrow, .square, .circle, .draw:
                break
            }
        } else if collectionView == drawColorCollectionView {
            currentDrawColor = drawColors[indexPath.row]
            switchEraserBtnStatus(false, reloadData: false)
        } else if collectionView == drawShapeCollectionView {
            currentDrawShape = shapeOptions[indexPath.row]
            switch currentDrawShape {
            case .arrow:
                selectedTool = .arrow
                setDrawViewsWithoutEraser(hidden: false)
            case .ellipse:
                selectedTool = .circle
                setDrawViewsWithoutEraser(hidden: false)
            case .freehand:
                selectedTool = .draw
                setDrawViews(hidden: false)
            case .line:
                selectedTool = .line
                setDrawViewsWithoutEraser(hidden: false)
            case .rectangle:
                selectedTool = .square
                setDrawViewsWithoutEraser(hidden: false)
            case .none:
                break
            }
            drawShapeCollectionView?.reloadData()
        } else if collectionView == filterCollectionView {
            let filter = ZLImageEditorConfiguration.default().filters[indexPath.row]
            editorManager.storeAction(.filter(oldFilter: currentFilter, newFilter: filter))
            changeFilter(filter)
        } else {
            let tool = adjustTools[indexPath.row]
            if tool != selectedAdjustTool {
                changeAdjustTool(tool)
            }
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
    }
}

