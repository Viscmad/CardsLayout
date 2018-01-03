//
//  CardsCollectionViewHorizontalLayout.swift
//  CardsLayout
//
//  Created by Filipp Fediakov on 03.01.18.
//  Copyright © 2018 filletofish. All rights reserved.
//

import UIKit


protocol CardsCollectionViewLayout {
    var itemSize: CGSize { get set }
    var spacing: CGPoint { get set }
    var maximumVisibleItems: Int { get set }
}


open class CardsCollectionViewHorizontalLayout: UICollectionViewLayout, CardsCollectionViewLayout {

    // MARK: Layout configuration

    public var itemSize: CGSize = CGSize(width: 200, height: 300) {
        didSet {
            invalidateLayout()
        }
    }

    public var spacing: CGPoint = CGPoint(x: 10.0, y: 10.0) {
        didSet {
            invalidateLayout()
        }
    }

    public var maximumVisibleItems: Int = 4 {
        didSet {
            invalidateLayout()
        }
    }

    // MARK: - UICollectionViewLayout

    override open var collectionView: UICollectionView {
        return super.collectionView!
    }

    override open var collectionViewContentSize: CGSize {
        let itemsCount = CGFloat(collectionView.numberOfItems(inSection: 0))
        return CGSize(width: collectionView.bounds.width * itemsCount,
                      height: collectionView.bounds.height)
    }

    override open func prepare() {
        super.prepare()
        assert(collectionView.numberOfSections == 1, "Multiple sections aren't supported!")
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let totalItemsCount = collectionView.numberOfItems(inSection: 0)
        let minVisibleIndex = max(Int(collectionView.contentOffset.x) / Int(collectionView.bounds.width), 0)
        let maxVisibleIndex = min(minVisibleIndex + maximumVisibleItems, totalItemsCount)
        let visibleIndices = minVisibleIndex..<maxVisibleIndex
        let attributes: [UICollectionViewLayoutAttributes?] = visibleIndices.map { index in
            let indexPath = IndexPath(item: index, section: 0)
            return self.layoutAttributesForItem(at: indexPath)
        }
        let filteredAttributes = attributes.flatMap { $0 }
        return filteredAttributes
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let minVisibleIndex = Int(collectionView.contentOffset.x) / Int(collectionView.bounds.width)
        let deltaOffset = CGFloat(Int(collectionView.contentOffset.x) % Int(collectionView.bounds.width))
        let percentageDeltaOffset = CGFloat(deltaOffset) / collectionView.bounds.width
        let visibleIndex = indexPath.row - minVisibleIndex

        let attributes = UICollectionViewLayoutAttributes(forCellWith:indexPath)
        attributes.size = itemSize
        let midY = self.collectionView.bounds.midY
        let midX = self.collectionView.bounds.midX
        attributes.center = CGPoint(x: midX + spacing.x * CGFloat(visibleIndex),
                                    y: midY + spacing.y * CGFloat(visibleIndex))
        attributes.zIndex = maximumVisibleItems - visibleIndex
        attributes.transform = scaleTransform(forVisibleIndex: visibleIndex,
                                              percentageOffset: percentageDeltaOffset)


        switch visibleIndex {
        case 0:
            attributes.center.x -= deltaOffset
            attributes.isHidden = false
            break
        case 1..<maximumVisibleItems:
            attributes.center.x -= spacing.x * percentageDeltaOffset
            attributes.center.y -= spacing.y * percentageDeltaOffset
            if visibleIndex == maximumVisibleItems - 1 {
                attributes.alpha = percentageDeltaOffset
            } else {
                attributes.alpha = 1.0
            }

            attributes.isHidden = false
            break
        default:
            attributes.alpha = 0
            attributes.isHidden = true
            break
        }
        return attributes
    }

    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}


extension CardsCollectionViewLayout {
    private func scale(at index: Int) -> CGFloat {
        let translatedCoefficient = CGFloat(index) - CGFloat(self.maximumVisibleItems) / 2
        return CGFloat(pow(0.95, translatedCoefficient))
    }

    func scaleTransform(forVisibleIndex visibleIndex: Int, percentageOffset: CGFloat) -> CGAffineTransform {
        guard visibleIndex != 0 else {
            let scaleAtZeroIndex = scale(at: visibleIndex)
            return CGAffineTransform(scaleX: scaleAtZeroIndex, y: scaleAtZeroIndex)
        }

        guard visibleIndex < maximumVisibleItems else {
            return CGAffineTransform.identity
        }

        var rawScale = scale(at: visibleIndex)
        let previousScale = scale(at: visibleIndex - 1)
        let delta = (previousScale - rawScale) * percentageOffset
        rawScale += delta
        return CGAffineTransform(scaleX: rawScale, y: rawScale)
    }
}
