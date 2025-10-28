//
//  EditorViewController+Text.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit

extension EditorViewController: EditorStickerTextViewControllerDelegate {
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinish stickerText: EditorStickerText
    ) {
        deselectedDrawTool()
        if let tool = selectedTool,
           tool.type == .graffiti || tool.type == .graffiti {
            selectedTool = nil
            updateBottomMaskLayer()
        }
        editorView.addSticker(stickerText)
        checkSelectedTool()
        checkFinishButtonState()
    }
    
    func stickerTextViewController(
        _ controller: EditorStickerTextViewController,
        didFinishUpdate stickerText: EditorStickerText
    ) {
        deselectedDrawTool()
        if let tool = selectedTool,
           tool.type == .graffiti || tool.type == .graffiti {
            selectedTool = nil
            updateBottomMaskLayer()
        }
        editorView.updateSticker(stickerText)
        checkSelectedTool()
    }
}

// MARK: - Preset Texts
extension EditorViewController {
    
    /// Add preset texts configured in EditorConfiguration
    /// 添加配置中的预设文本
    func addPresetTexts() {
        guard !config.presetTexts.isEmpty else { return }
        
        for presetText in config.presetTexts {
            let stickerText = createPresetText(
                presetText.text,
                fontSize: presetText.fontSize,
                color: presetText.color
            )
            let itemView = editorView.addSticker(stickerText, isSelected: false)
            positionPresetText(itemView, at: presetText.position)
        }
        
        // Deselect all stickers after adding
        editorView.deselectedSticker()
    }
    
    /// Create a preset text sticker
    /// 创建预设文本贴纸
    private func createPresetText(
        _ text: String,
        fontSize: CGFloat,
        color: UIColor
    ) -> EditorStickerText {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Calculate text size
        let textSize = attributedString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        // Create image from text with padding
        let padding: CGFloat = 20
        let imageSize = CGSize(
            width: ceil(textSize.width) + padding,
            height: ceil(textSize.height) + padding
        )
        
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let textImage = renderer.image { context in
            attributedString.draw(
                in: CGRect(
                    x: padding / 2,
                    y: padding / 2,
                    width: textSize.width,
                    height: textSize.height
                )
            )
        }
        
        return EditorStickerText(
            image: textImage,
            text: text,
            textColor: color,
            showBackgroud: false,
            fontSize: fontSize
        )
    }
    
    /// Position a preset text sticker
    /// 定位预设文本贴纸
    private func positionPresetText(
        _ itemView: EditorStickersItemBaseView,
        at position: EditorConfiguration.PresetText.Position
    ) {
        let viewWidth = editorView.width
        let viewHeight = editorView.height
        let margin: CGFloat = 60  // Safety margin from edges
        
        let centerPoint: CGPoint
        
        switch position {
        case .topLeft:
            centerPoint = CGPoint(x: margin, y: margin)
        case .topCenter:
            centerPoint = CGPoint(x: viewWidth * 0.5, y: margin)
        case .topRight:
            centerPoint = CGPoint(x: viewWidth - margin, y: margin)
        case .centerLeft:
            centerPoint = CGPoint(x: margin, y: viewHeight * 0.5)
        case .center:
            centerPoint = CGPoint(x: viewWidth * 0.5, y: viewHeight * 0.5)
        case .centerRight:
            centerPoint = CGPoint(x: viewWidth - margin, y: viewHeight * 0.5)
        case .bottomLeft:
            centerPoint = CGPoint(x: margin, y: viewHeight - margin)
        case .bottomCenter:
            centerPoint = CGPoint(x: viewWidth * 0.5, y: viewHeight - margin)
        case .bottomRight:
            centerPoint = CGPoint(x: viewWidth - margin, y: viewHeight - margin)
        case .custom(let relativePoint):
            // Use relative coordinates (0.0-1.0)
            centerPoint = CGPoint(
                x: viewWidth * relativePoint.x,
                y: viewHeight * relativePoint.y
            )
        }
        
        itemView.center = centerPoint
    }
}
