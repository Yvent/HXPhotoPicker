//
//  EditorChartletViewCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

class EditorChartletViewCell: UICollectionViewCell {
    private var selectedBgView: UIVisualEffectView!
    
    var imageView: HXImageViewProtocol!
    var editorType: EditorContentViewType = .image
    var downloadCompletion = false
    
    private var nameLabel: UILabel!
    private var descriptionLabel: UILabel!
    
    var titleChartlet: EditorChartletTitle! {
        didSet {
            selectedBgView.isHidden = !titleChartlet.isSelected
            setupImage(image: titleChartlet.image, url: titleChartlet.url)
        }
    }
    
    var isSelectedTitle: Bool = false {
        didSet {
            titleChartlet.isSelected = isSelectedTitle
            selectedBgView.isHidden = !titleChartlet.isSelected
        }
    }
    
    var showSelectedBgView: Bool = false {
        didSet {
            selectedBgView.isHidden = !showSelectedBgView
        }
    }
    
    var chartlet: EditorChartlet! {
        didSet {
            selectedBgView.isHidden = true
            setupImage(image: chartlet.image, url: chartlet.url)
            
            // 设置 name 和 description
            if let name = chartlet.name, !name.isEmpty {
                nameLabel.text = name
                nameLabel.isHidden = false
            } else {
                nameLabel.text = nil
                nameLabel.isHidden = true
            }
            
            if let description = chartlet.description, !description.isEmpty {
                descriptionLabel.text = description
                descriptionLabel.isHidden = false
            } else {
                descriptionLabel.text = nil
                descriptionLabel.isHidden = true
            }
            
            setNeedsLayout()
        }
    }
    
    func setupImage(image: UIImage?, url: URL? = nil) {
        downloadCompletion = false
        imageView.image = nil
        if let image = image {
            imageView.image = image
            downloadCompletion = true
        }else if let url = url {
            let options: ImageDownloadOptionsInfo
            if url.isGif && editorType == .video {
                options = [.memoryCacheExpirationExpired]
            }else {
                options = [.cacheOriginalImage, .imageProcessor(CGSize(width: width * 2, height: height * 2))]
            }
            imageView.setImage(with: .init(downloadURL: url, indicatorColor: .white), placeholder: nil, options: options, progressHandler: nil) { [weak self] _ in
                self?.downloadCompletion = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let effect = UIBlurEffect(style: .dark)
        selectedBgView = UIVisualEffectView(effect: effect)
        selectedBgView.isHidden = true
        selectedBgView.layer.cornerRadius = 5
        selectedBgView.layer.masksToBounds = true
        contentView.addSubview(selectedBgView)
        imageView = PhotoManager.ImageView.init()
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        
        // 初始化 nameLabel
        nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.isHidden = true
        contentView.addSubview(nameLabel)
        
        // 初始化 descriptionLabel
        descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 10)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2
        descriptionLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.isHidden = true
        contentView.addSubview(descriptionLabel)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBgView.frame = bounds
        if titleChartlet != nil {
            imageView.size = CGSize(width: 25, height: 25)
            imageView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        } else {
            // 为贴纸列表布局
            let padding: CGFloat = 5
            var currentY: CGFloat = padding
            
            // 计算图片可用空间
            let nameLabelHeight: CGFloat = !nameLabel.isHidden ? 18 : 0
            let descriptionLabelHeight: CGFloat = !descriptionLabel.isHidden ? 32 : 0
            let textTotalHeight = nameLabelHeight + descriptionLabelHeight
            let spacing: CGFloat = (nameLabelHeight > 0 || descriptionLabelHeight > 0) ? 4 : 0
            
            let imageHeight = height - textTotalHeight - padding * 2 - spacing
            let imageSize = min(imageHeight, width - padding * 2)
            
            // 布局图片（居中）
            imageView.frame = CGRect(
                x: (width - imageSize) / 2,
                y: currentY,
                width: imageSize,
                height: imageSize
            )
            currentY = imageView.frame.maxY + spacing
            
            // 布局 nameLabel
            if !nameLabel.isHidden {
                nameLabel.frame = CGRect(
                    x: padding,
                    y: currentY,
                    width: width - padding * 2,
                    height: nameLabelHeight
                )
                currentY = nameLabel.frame.maxY
            }
            
            // 布局 descriptionLabel
            if !descriptionLabel.isHidden {
                descriptionLabel.frame = CGRect(
                    x: padding,
                    y: currentY,
                    width: width - padding * 2,
                    height: descriptionLabelHeight
                )
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
