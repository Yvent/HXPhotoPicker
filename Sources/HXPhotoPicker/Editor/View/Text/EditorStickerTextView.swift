//
//  EditorStickerTextView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/22.
//

import UIKit

class EditorStickerTextView: UIView {
    let config: EditorConfiguration.Text
    var textView: UITextView!
    private var textButton: UIButton!
    private var flowLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    
    // Font size controls
    private var fontSizeContainerView: UIView!
    private var fontSizeLabel: UILabel!
    private var fontSizeMinusButton: UIButton!
    private var fontSizePlusButton: UIButton!
    private var fontSizeTitleLabel: UILabel!
    
    // Opacity controls
    private var opacityContainerView: UIView!
    private var opacitySlider: UISlider!
    private var opacityTitleLabel: UILabel!
    
    // Style buttons
    private var styleContainerView: UIView!
    private var boldButton: UIButton!
    private var boldLabel: UILabel!
    private var italicButton: UIButton!
    private var italicLabel: UILabel!
    private var underlineButton: UIButton!
    private var underlineLabel: UILabel!
    private var strikethroughButton: UIButton!
    private var strikethroughLabel: UILabel!
    
    var text: String {
        textView.text
    }
    var currentSelectedIndex: Int = 0 {
        didSet {
            if currentSelectedIndex < 0 {
                return
            }
            collectionView.scrollToItem(
                at: IndexPath(item: currentSelectedIndex, section: 0),
                at: .centeredHorizontally,
                animated: true
            )
        }
    }
    
    var customColor: PhotoEditorBrushCustomColor
    var isShowCustomColor: Bool {
        if #available(iOS 14.0, *), config.colors.count > 1 {
            return true
        }
        return false
    }
    var currentSelectedColor: UIColor = .clear
    var typingAttributes: [NSAttributedString.Key: Any] = [:]
    var stickerText: EditorStickerText?
    
    var showBackgroudColor: Bool = false
    var useBgColor: UIColor = .clear
    var textIsDelete: Bool = false
    var textLayer: EditorStickerTextLayer?
    var rectArray: [CGRect] = []
    var blankWidth: CGFloat = 22
    var layerRadius: CGFloat = 8
    var keyboardFrame: CGRect = .zero
    var maxIndex: Int = 0
    
    // New style properties
    var currentFontSize: CGFloat
    var currentAlpha: CGFloat = 1.0
    var isBold: Bool = false
    var isItalic: Bool = false
    var hasUnderline: Bool = false
    var hasStrikethrough: Bool = false
    
    init(
        config: EditorConfiguration.Text,
        stickerText: EditorStickerText?
    ) {
        self.config = config
        self.currentFontSize = config.defaultFontSize
        self.stickerText = stickerText
        
        // Initialize customColor
        let initialColor: UIColor
        if #available(iOS 14.0, *), config.colors.count > 1, let color = config.colors.last?.color {
            initialColor = color
        } else {
            initialColor = .clear
        }
        self.customColor = .init(color: initialColor)
        
        super.init(frame: .zero)
        initViews()
        setupTextConfig()
        setupStickerText()
        setupTextColors()
        addKeyboardNotificaition()
        
        textView.becomeFirstResponder()
    }
    
    private func initViews() {
        textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.layoutManager.delegate = self
        textView.textContainerInset = UIEdgeInsets(
            top: 15,
            left: 15 + UIDevice.leftMargin,
            bottom: 15,
            right: 15 + UIDevice.rightMargin
        )
        textView.contentInset = .zero
        addSubview(textView)
        
        textButton = UIButton(type: .custom)
        textButton.setImage(.imageResource.editor.text.backgroundNormal.image, for: .normal)
        textButton.setImage(.imageResource.editor.text.backgroundSelected.image, for: .selected)
        textButton.addTarget(self, action: #selector(didTextButtonClick(button:)), for: .touchUpInside)
        addSubview(textButton)
        
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.itemSize = CGSize(width: 37, height: 37)
        collectionView = HXCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(
            EditorStickerTextViewCell.self,
            forCellWithReuseIdentifier: "EditorStickerTextViewCellID"
        )
        addSubview(collectionView)
        
        // Font size controls
        fontSizeContainerView = UIView()
        fontSizeContainerView.backgroundColor = .clear
        addSubview(fontSizeContainerView)
        
        fontSizeTitleLabel = UILabel()
        fontSizeTitleLabel.text = "字号"
        fontSizeTitleLabel.textColor = .white
        fontSizeTitleLabel.font = .systemFont(ofSize: 14)
        fontSizeTitleLabel.textAlignment = .center
        fontSizeContainerView.addSubview(fontSizeTitleLabel)
        
        fontSizeMinusButton = UIButton(type: .custom)
        fontSizeMinusButton.setTitle("−", for: .normal)
        fontSizeMinusButton.setTitleColor(.white, for: .normal)
        fontSizeMinusButton.titleLabel?.font = .systemFont(ofSize: 24)
        fontSizeMinusButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        fontSizeMinusButton.layer.cornerRadius = 4
        fontSizeMinusButton.addTarget(self, action: #selector(didMinusFontSizeClick), for: .touchUpInside)
        fontSizeContainerView.addSubview(fontSizeMinusButton)
        
        fontSizeLabel = UILabel()
        fontSizeLabel.text = "\(Int(currentFontSize))"
        fontSizeLabel.textColor = .white
        fontSizeLabel.font = .systemFont(ofSize: 16)
        fontSizeLabel.textAlignment = .center
        fontSizeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        fontSizeLabel.layer.cornerRadius = 4
        fontSizeLabel.layer.masksToBounds = true
        fontSizeContainerView.addSubview(fontSizeLabel)
        
        fontSizePlusButton = UIButton(type: .custom)
        fontSizePlusButton.setTitle("+", for: .normal)
        fontSizePlusButton.setTitleColor(.white, for: .normal)
        fontSizePlusButton.titleLabel?.font = .systemFont(ofSize: 20)
        fontSizePlusButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        fontSizePlusButton.layer.cornerRadius = 4
        fontSizePlusButton.addTarget(self, action: #selector(didPlusFontSizeClick), for: .touchUpInside)
        fontSizeContainerView.addSubview(fontSizePlusButton)
        
        // Opacity controls
        opacityContainerView = UIView()
        opacityContainerView.backgroundColor = .clear
        addSubview(opacityContainerView)
        
        opacityTitleLabel = UILabel()
        opacityTitleLabel.text = "透明"
        opacityTitleLabel.textColor = .white
        opacityTitleLabel.font = .systemFont(ofSize: 14)
        opacityTitleLabel.textAlignment = .center
        opacityContainerView.addSubview(opacityTitleLabel)
        
        opacitySlider = UISlider()
        opacitySlider.minimumValue = 0
        opacitySlider.maximumValue = 1
        opacitySlider.value = Float(currentAlpha)
        opacitySlider.minimumTrackTintColor = .white
        opacitySlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        opacitySlider.addTarget(self, action: #selector(didOpacitySliderChanged(_:)), for: .valueChanged)
        opacityContainerView.addSubview(opacitySlider)
        
        // Style buttons
        styleContainerView = UIView()
        styleContainerView.backgroundColor = .clear
        addSubview(styleContainerView)
        
        boldButton = createStyleButton(title: "B", action: #selector(didBoldButtonClick))
        boldButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        styleContainerView.addSubview(boldButton)
        boldLabel = createStyleLabel(text: "粗体")
        styleContainerView.addSubview(boldLabel)
        
        italicButton = createStyleButton(title: "I", action: #selector(didItalicButtonClick))
        italicButton.titleLabel?.font = .italicSystemFont(ofSize: 18)
        styleContainerView.addSubview(italicButton)
        italicLabel = createStyleLabel(text: "斜体")
        styleContainerView.addSubview(italicLabel)
        
        underlineButton = createStyleButton(title: "U", action: #selector(didUnderlineButtonClick))
        let underlineAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        underlineButton.setAttributedTitle(NSAttributedString(string: "U", attributes: underlineAttributes), for: .normal)
        styleContainerView.addSubview(underlineButton)
        underlineLabel = createStyleLabel(text: "下划线")
        styleContainerView.addSubview(underlineLabel)
        
        strikethroughButton = createStyleButton(title: "S", action: #selector(didStrikethroughButtonClick))
        let strikethroughAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]
        strikethroughButton.setAttributedTitle(NSAttributedString(string: "S", attributes: strikethroughAttributes), for: .normal)
        styleContainerView.addSubview(strikethroughButton)
        strikethroughLabel = createStyleLabel(text: "删除线")
        styleContainerView.addSubview(strikethroughLabel)
    }
    
    private func createStyleButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createStyleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 11)
        label.textAlignment = .center
        return label
    }
    
    private func setupStickerText() {
        if let text = stickerText {
            showBackgroudColor = text.showBackgroud
            textView.text = text.text
            textButton.isSelected = text.showBackgroud
            currentFontSize = text.fontSize
            isBold = text.isBold
            isItalic = text.isItalic
            hasUnderline = text.hasUnderline
            hasStrikethrough = text.hasStrikethrough
            currentAlpha = text.textAlpha
            
            // Update UI controls
            fontSizeLabel.text = "\(Int(currentFontSize))"
            opacitySlider.value = Float(currentAlpha)
            updateStyleButtonStates()
        }
        setupTextAttributes()
    }
    
    private func updateStyleButtonStates() {
        boldButton.backgroundColor = isBold ? UIColor.white.withAlphaComponent(0.5) : UIColor.white.withAlphaComponent(0.2)
        italicButton.backgroundColor = isItalic ? UIColor.white.withAlphaComponent(0.5) : UIColor.white.withAlphaComponent(0.2)
        underlineButton.backgroundColor = hasUnderline ? UIColor.white.withAlphaComponent(0.5) : UIColor.white.withAlphaComponent(0.2)
        strikethroughButton.backgroundColor = hasStrikethrough ? UIColor.white.withAlphaComponent(0.5) : UIColor.white.withAlphaComponent(0.2)
    }
    
    private func setupTextConfig() {
        textView.tintColor = config.tintColor
        updateFont()
    }
    
    private func setupTextAttributes() {
        let font = getCurrentFont()
        let color = currentSelectedColor.withAlphaComponent(currentAlpha)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        
        if hasUnderline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if hasStrikethrough {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        
        typingAttributes = attributes
        textView.attributedText = NSAttributedString(string: stickerText?.text ?? "", attributes: attributes)
    }
    
    private func getCurrentFont() -> UIFont {
        if isBold && isItalic {
            if let descriptor = UIFont.systemFont(ofSize: currentFontSize).fontDescriptor
                .withSymbolicTraits([.traitBold, .traitItalic]) {
                return UIFont(descriptor: descriptor, size: currentFontSize)
            }
        } else if isBold {
            return .boldSystemFont(ofSize: currentFontSize)
        } else if isItalic {
            return .italicSystemFont(ofSize: currentFontSize)
        }
        return .systemFont(ofSize: currentFontSize)
    }
    
    private func updateFont() {
        let font = getCurrentFont()
        textView.font = font
        typingAttributes[.font] = font
        textView.typingAttributes = typingAttributes
    }
    
    private func updateTextAttributes() {
        let font = getCurrentFont()
        let color = currentSelectedColor.withAlphaComponent(currentAlpha)
        
        // Preserve paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        typingAttributes[.font] = font
        typingAttributes[.foregroundColor] = color
        typingAttributes[.paragraphStyle] = paragraphStyle
        
        if hasUnderline {
            typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        } else {
            typingAttributes.removeValue(forKey: .underlineStyle)
        }
        
        if hasStrikethrough {
            typingAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        } else {
            typingAttributes.removeValue(forKey: .strikethroughStyle)
        }
        
        textView.font = font
        textView.textColor = color
        textView.typingAttributes = typingAttributes
        
        // Apply to existing text
        if !textView.text.isEmpty {
            let currentText = textView.text ?? ""
            let attributedString = NSMutableAttributedString(string: currentText, attributes: typingAttributes)
            textView.attributedText = attributedString
        }
        
        // Redraw background if active
        if showBackgroudColor {
            drawTextBackgroudColor()
        }
    }
    
    private func setupTextColors() {
        var hasColor: Bool = false
        for (index, colorHex) in config.colors.enumerated() {
            let color = colorHex.color
            if let text = stickerText {
                if color == text.textColor {
                    if text.showBackgroud {
                        if color.isWhite {
                            changeTextColor(color: .black)
                        }else {
                            changeTextColor(color: .white)
                        }
                        useBgColor = color
                    }else {
                        changeTextColor(color: color)
                    }
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                    hasColor = true
                }
            }else {
                if index == 0 {
                    changeTextColor(color: color)
                    currentSelectedColor = color
                    currentSelectedIndex = index
                    collectionView.selectItem(
                        at: IndexPath(item: currentSelectedIndex, section: 0),
                        animated: true,
                        scrollPosition: .centeredHorizontally
                    )
                    hasColor = true
                }
            }
        }
        if !hasColor {
            if let text = stickerText {
                changeTextColor(color: text.textColor)
                currentSelectedColor = text.textColor
                currentSelectedIndex = -1
            }
        }
        if textButton.isSelected {
            drawTextBackgroudColor()
        }
    }
    
    @objc
    private func didMinusFontSizeClick() {
        if currentFontSize > config.minFontSize {
            currentFontSize -= 1
            fontSizeLabel.text = "\(Int(currentFontSize))"
            updateTextAttributes()
        }
    }
    
    @objc
    private func didPlusFontSizeClick() {
        if currentFontSize < config.maxFontSize {
            currentFontSize += 1
            fontSizeLabel.text = "\(Int(currentFontSize))"
            updateTextAttributes()
        }
    }
    
    @objc
    private func didOpacitySliderChanged(_ slider: UISlider) {
        currentAlpha = CGFloat(slider.value)
        updateTextAttributes()
    }
    
    @objc
    private func didBoldButtonClick() {
        isBold = !isBold
        updateStyleButtonStates()
        updateTextAttributes()
    }
    
    @objc
    private func didItalicButtonClick() {
        isItalic = !isItalic
        updateStyleButtonStates()
        updateTextAttributes()
    }
    
    @objc
    private func didUnderlineButtonClick() {
        hasUnderline = !hasUnderline
        updateStyleButtonStates()
        updateTextAttributes()
    }
    
    @objc
    private func didStrikethroughButtonClick() {
        hasStrikethrough = !hasStrikethrough
        updateStyleButtonStates()
        updateTextAttributes()
    }
    
    @objc
    private func didTextButtonClick(button: UIButton) {
        button.isSelected = !button.isSelected
        showBackgroudColor = button.isSelected
        useBgColor = currentSelectedColor
        if button.isSelected {
            if currentSelectedColor.isWhite {
                changeTextColor(color: .black)
            }else {
                changeTextColor(color: .white)
            }
        }else {
            changeTextColor(color: currentSelectedColor)
        }
    }
    
    private func addKeyboardNotificaition() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillAppearance),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDismiss),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc
    private func keyboardWillAppearance(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.keyboardFrame = keyboardFrame
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    @objc
    private func keyboardWillDismiss(notifi: Notification) {
        guard let info = notifi.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        keyboardFrame = .zero
        UIView.animate(withDuration: duration) {
            self.layoutSubviews()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12 + UIDevice.rightMargin)
        
        let controlsHeight: CGFloat = 220 // Total height for all controls (50 + 50 + 50 + 70)
        
        // Calculate bottom position
        var bottomY: CGFloat
        if keyboardFrame.isEmpty {
            if UIDevice.isPad {
                if config.modalPresentationStyle == .fullScreen {
                    bottomY = height - UIDevice.bottomMargin
                }else {
                    bottomY = height
                }
            }else {
                bottomY = height - UIDevice.bottomMargin
            }
        }else {
            bottomY = height - keyboardFrame.height
        }
        
        // Style buttons (bottom-most, above keyboard)
        let styleButtonY = bottomY - 70
        styleContainerView.frame = CGRect(x: 0, y: styleButtonY, width: width, height: 70)
        let buttonWidth: CGFloat = 50
        let buttonSpacing = (width - UIDevice.leftMargin - UIDevice.rightMargin - buttonWidth * 4) / 5
        let buttonY: CGFloat = 5
        let labelY: CGFloat = buttonY + buttonWidth + 2
        
        boldButton.frame = CGRect(
            x: UIDevice.leftMargin + buttonSpacing,
            y: buttonY,
            width: buttonWidth,
            height: buttonWidth
        )
        boldLabel.frame = CGRect(
            x: boldButton.x,
            y: labelY,
            width: buttonWidth,
            height: 12
        )
        
        italicButton.frame = CGRect(
            x: boldButton.frame.maxX + buttonSpacing,
            y: buttonY,
            width: buttonWidth,
            height: buttonWidth
        )
        italicLabel.frame = CGRect(
            x: italicButton.x,
            y: labelY,
            width: buttonWidth,
            height: 12
        )
        
        underlineButton.frame = CGRect(
            x: italicButton.frame.maxX + buttonSpacing,
            y: buttonY,
            width: buttonWidth,
            height: buttonWidth
        )
        underlineLabel.frame = CGRect(
            x: underlineButton.x,
            y: labelY,
            width: buttonWidth,
            height: 12
        )
        
        strikethroughButton.frame = CGRect(
            x: underlineButton.frame.maxX + buttonSpacing,
            y: buttonY,
            width: buttonWidth,
            height: buttonWidth
        )
        strikethroughLabel.frame = CGRect(
            x: strikethroughButton.x,
            y: labelY,
            width: buttonWidth,
            height: 12
        )
        
        // Opacity slider (above style buttons)
        let opacityY = styleButtonY - 50
        opacityContainerView.frame = CGRect(x: 0, y: opacityY, width: width, height: 50)
        opacityTitleLabel.frame = CGRect(
            x: UIDevice.leftMargin + 10,
            y: 15,
            width: 50,
            height: 20
        )
        opacitySlider.frame = CGRect(
            x: opacityTitleLabel.frame.maxX + 20,
            y: 10,
            width: width - opacityTitleLabel.frame.maxX - 40 - UIDevice.rightMargin,
            height: 30
        )
        
        // Font size controls (above opacity)
        let fontSizeY = opacityY - 50
        fontSizeContainerView.frame = CGRect(x: 0, y: fontSizeY, width: width, height: 50)
        fontSizeTitleLabel.frame = CGRect(
            x: UIDevice.leftMargin + 10,
            y: 15,
            width: 50,
            height: 20
        )
        let controlWidth: CGFloat = 40
        let labelWidth: CGFloat = 80
        fontSizeMinusButton.frame = CGRect(
            x: fontSizeTitleLabel.frame.maxX + 20,
            y: 10,
            width: controlWidth,
            height: 30
        )
        fontSizeLabel.frame = CGRect(
            x: fontSizeMinusButton.frame.maxX + 10,
            y: 10,
            width: labelWidth,
            height: 30
        )
        fontSizePlusButton.frame = CGRect(
            x: fontSizeLabel.frame.maxX + 10,
            y: 10,
            width: controlWidth,
            height: 30
        )
        
        // Color picker (above font size)
        textButton.frame = CGRect(
            x: UIDevice.leftMargin,
            y: fontSizeY - 50,
            width: 50,
            height: 50
        )
        collectionView.frame = CGRect(
            x: textButton.frame.maxX,
            y: textButton.y,
            width: width - textButton.width,
            height: 50
        )
        
        // Text view
        textView.frame = CGRect(x: 10, y: 0, width: width - 20, height: textButton.y)
        textView.textContainerInset = UIEdgeInsets(
            top: 15,
            left: 15 + UIDevice.leftMargin,
            bottom: 15,
            right: 15 + UIDevice.rightMargin
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class EditorStickerTextViewCell: UICollectionViewCell {
    private var colorBgView: UIView!
    private var imageView: UIImageView!
    private var colorView: UIView!
    
    var colorHex: String! {
        didSet {
            imageView.isHidden = true
            guard let colorHex = colorHex else { return }
            let color = colorHex.color
            if color.isWhite {
                colorBgView.backgroundColor = "#dadada".color
            }else {
                colorBgView.backgroundColor = .white
            }
            colorView.backgroundColor = color
        }
    }
    
    var customColor: PhotoEditorBrushCustomColor? {
        didSet {
            guard let customColor = customColor else {
                return
            }
            imageView.isHidden = false
            colorView.backgroundColor = customColor.color
        }
    }
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.colorBgView.transform = self.isSelected ? .init(scaleX: 1.25, y: 1.25) : .identity
                self.colorView.transform = self.isSelected ? .init(scaleX: 1.3, y: 1.3) : .identity
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView(image: .imageResource.editor.text.customColor.image)
        imageView.isHidden = true
        
        let bgLayer = CAShapeLayer()
        bgLayer.contentsScale = UIScreen._scale
        bgLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bgLayer.fillColor = UIColor.white.cgColor
        let bgPath = UIBezierPath(
            roundedRect: CGRect(x: 1.5, y: 1.5, width: 19, height: 19),
            cornerRadius: 19 * 0.5
        )
        bgLayer.path = bgPath.cgPath
        imageView.layer.addSublayer(bgLayer)

        let maskLayer = CAShapeLayer()
        maskLayer.contentsScale = UIScreen._scale
        maskLayer.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        let maskPath = UIBezierPath(rect: bgLayer.bounds)
        maskPath.append(
            UIBezierPath(
                roundedRect: CGRect(x: 3, y: 3, width: 16, height: 16),
                cornerRadius: 8
            ).reversing()
        )
        maskLayer.path = maskPath.cgPath
        imageView.layer.mask = maskLayer
        
        colorBgView = UIView()
        colorBgView.size = CGSize(width: 22, height: 22)
        colorBgView.layer.cornerRadius = 11
        colorBgView.layer.masksToBounds = true
        colorBgView.addSubview(imageView)
        contentView.addSubview(colorBgView)
        
        colorView = UIView()
        colorView.size = CGSize(width: 16, height: 16)
        colorView.layer.cornerRadius = 8
        colorView.layer.masksToBounds = true
        contentView.addSubview(colorView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        colorBgView.center = CGPoint(x: width / 2, y: height / 2)
        imageView.frame = colorBgView.bounds
        colorView.center = CGPoint(x: width / 2, y: height / 2)
    }
}

struct PhotoEditorBrushCustomColor {
    var isFirst: Bool = true
    var isSelected: Bool = false
    var color: UIColor
}
