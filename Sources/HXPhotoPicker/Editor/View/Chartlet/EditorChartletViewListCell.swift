//
//  EditorChartletViewListCell.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

protocol EditorChartletViewListCellDelegate: AnyObject {
    func listCell(_ cell: EditorChartletViewListCell, didSelectImage image: UIImage, imageData: Data?, chartlet: EditorChartlet)
}

class EditorChartletViewListCell: UICollectionViewCell,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegate,
                                  UICollectionViewDelegateFlowLayout {
    weak var delegate: EditorChartletViewListCellDelegate?
    private var loadingView: UIActivityIndicatorView!
    private var loadingLabel: UILabel!
    private var flowLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    
    var rowCount: Int = 4
    var chartletList: [EditorChartlet] = [] {
        didSet {
            collectionView.reloadData()
            resetOffset()
        }
    }
    var editorType: EditorContentViewType = .image
    /// 加载时显示的文案（由上层传入）
    var loadingText: String?
    
    func resetOffset() {
        collectionView.contentOffset = CGPoint(
            x: -collectionView.contentInset.left,
            y: -collectionView.contentInset.top
        )
    }
    
    /// 开始列表页加载，显示菊花与文案
    func startLoading() {
        loadingView.startAnimating()
        loadingLabel.text = loadingText
        loadingLabel.isHidden = (loadingLabel.text == nil || loadingLabel.text?.isEmpty == true) ? true : false
    }
    /// 停止列表页加载，隐藏菊花与文案
    func stopLoad() {
        loadingView.stopAnimating()
        loadingLabel.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 5
        collectionView = HXCollectionView.init(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.register(EditorChartletViewCell.self, forCellWithReuseIdentifier: "EditorChartletViewListCellID")
        contentView.addSubview(collectionView)
        loadingView = UIActivityIndicatorView(style: .white)
        loadingView.hidesWhenStopped = true
        contentView.addSubview(loadingView)
        loadingLabel = UILabel()
        loadingLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        loadingLabel.font = .systemFont(ofSize: 12)
        loadingLabel.textAlignment = .center
        loadingLabel.numberOfLines = 2
        loadingLabel.isHidden = true
        contentView.addSubview(loadingLabel)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        chartletList.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EditorChartletViewListCellID",
            for: indexPath
        ) as! EditorChartletViewCell
        cell.editorType = editorType
        cell.chartlet = chartletList[indexPath.item]
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let rowCount = !UIDevice.isPortrait && !UIDevice.isPad ? 7 : CGFloat(self.rowCount)
        let margin = collectionView.contentInset.left + collectionView.contentInset.right
        let spacing = flowLayout.minimumLineSpacing * (rowCount - 1)
        let itemWidth = (width - margin - spacing) / rowCount
        
        // 计算额外高度以容纳 name 和 description
        let chartlet = chartletList[indexPath.item]
        var extraHeight: CGFloat = 0
        
        if let name = chartlet.name, !name.isEmpty {
            extraHeight += 18 // nameLabel 高度
        }
        if let description = chartlet.description, !description.isEmpty {
            extraHeight += 32 // descriptionLabel 高度（2行）
        }
        if extraHeight > 0 {
            extraHeight += 4 // 图片与文本之间的间距
        }
        
        let itemHeight = itemWidth + extraHeight
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let cell = collectionView.cellForItem(at: indexPath) as! EditorChartletViewCell
        let chartlet = chartletList[indexPath.item]
        if var image = cell.chartlet.image {
            let imageData: Data?
            if editorType == .image {
                if let count = image.images?.count,
                   let img = image.images?.first,
                   count > 0 {
                    image = img
                }
                imageData = nil
            }else {
                imageData = cell.chartlet.imageData
            }
            delegate?.listCell(
                self,
                didSelectImage: image,
                imageData: imageData,
                chartlet: chartlet
            )
        }else {
            if let url = cell.chartlet.url, cell.downloadCompletion {
                PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: superview)
                PhotoManager.ImageView.download(with: .init(downloadURL: url), options: nil, progressHandler: nil) { [weak self]  in
                    guard let self = self else { return }
                    PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.superview)
                    switch $0 {
                    case .success(let result):
                        if let image = result.image {
                            if self.editorType == .image {
                                self.delegate?.listCell(self, didSelectImage: image, imageData: nil, chartlet: chartlet)
                                return
                            }
                            self.delegate?.listCell(self, didSelectImage: image, imageData: result.imageData, chartlet: chartlet)
                        }else if let imageData = result.imageData, let image = UIImage(data: imageData) {
                            if self.editorType == .image {
                                self.delegate?.listCell(self, didSelectImage: image, imageData: nil, chartlet: chartlet)
                                return
                            }
                            self.delegate?.listCell(self, didSelectImage: image, imageData: imageData, chartlet: chartlet)
                        }
                    case .failure:
                        return
                    }
                }
            }
        }
    }
    
    /// 布局子视图，调整loading文案在菊花下方位置
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
        loadingView.center = CGPoint(x: width * 0.5, y: height * 0.5)
        // 将文案放置在菊花下方
        let maxLabelWidth = width - 30
        let labelSize = loadingLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: CGFloat.greatestFiniteMagnitude))
        loadingLabel.frame = CGRect(
            x: (width - min(labelSize.width, maxLabelWidth)) / 2,
            y: loadingView.frame.maxY + 8,
            width: min(labelSize.width, maxLabelWidth),
            height: labelSize.height
        )
        collectionView.contentInset = UIEdgeInsets(
            top: 60,
            left: 15 + UIDevice.leftMargin,
            bottom: 15 + UIDevice.bottomMargin,
            right: 15 + UIDevice.rightMargin
        )
        collectionView.scrollIndicatorInsets = UIEdgeInsets(
            top: 60,
            left: UIDevice.leftMargin,
            bottom: 15 + UIDevice.bottomMargin,
            right: UIDevice.rightMargin
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
