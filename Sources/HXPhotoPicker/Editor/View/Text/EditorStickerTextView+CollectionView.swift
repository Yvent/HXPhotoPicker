//
//  EditorStickerTextView+CollectionView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension EditorStickerTextView: UICollectionViewDataSource,
                                 UICollectionViewDelegate { }

@available(iOS 14.0, *)
extension EditorStickerTextView: UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidSelectColor(
        _ viewController: UIColorPickerViewController
    ) {
        if #available(iOS 15.0, *) {
            return
        }
        didSelectCustomColor(viewController.selectedColor)
    }
    
    @available(iOS 15.0, *)
    public func colorPickerViewController(
        _ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool
    ) {
        didSelectCustomColor(color)
    }
    
    func didSelectCustomColor(_ color: UIColor) {
        customColor.color = color
        let cell = collectionView.cellForItem(
            at: .init(item: currentSelectedIndex, section: 0)
        ) as? EditorStickerTextViewCell
        cell?.customColor = customColor
        let color = customColor.color
        currentSelectedColor = color
        if showBackgroudColor {
            useBgColor = color
            if color.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: color)
        }
    }
}
