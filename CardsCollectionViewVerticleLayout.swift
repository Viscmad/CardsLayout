import UIKit
 
open class CardsCollectionViewLayout: UICollectionViewLayout {
   
    // MARK: - Layout configuration
   
    //MARK: Size attribute
    //Using code :
    //    attributes.size = CGSize(
    //    width: (collectionView.bounds.width - ((collectionView.bounds.width * 2)/100)) ,
    //    height: (collectionView.bounds.height - ((collectionView.bounds.height * 4)/100)))
    //Instead Calling
    //    public var itemSize: CGSize = CGSize(width: 200, height: 300) {
    //        didSet{
    //            invalidateLayout()
    //        }
    //    }
   
    public var spacing: CGFloat = 10.0 {
        didSet{
            invalidateLayout()
        }
    }
   
    public var maximumVisibleItems: Int = 2 {
        didSet{
            invalidateLayout()
        }
    }
   
    // MARK: UICollectionViewLayout
   
    override open var collectionView: UICollectionView {
        return super.collectionView!
    }
   
    override open var collectionViewContentSize: CGSize {
        let itemsCount = CGFloat(collectionView.numberOfItems(inSection: 0))
       
        return CGSize(width: collectionView.bounds.width,
                      height: collectionView.bounds.height * itemsCount)
    }
   
    override open func prepare() {
        super.prepare()
        assert(collectionView.numberOfSections == 1, "Multiple sections aren't supported!")
    }
   
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let totalItemsCount = collectionView.numberOfItems(inSection: 0)
       
        let minVisibleIndex = max(Int(collectionView.contentOffset.x) / Int(collectionView.bounds.width), 0)
        let maxVisibleIndex = min(minVisibleIndex + maximumVisibleItems, totalItemsCount)
       
        let contentCenterX = collectionView.contentOffset.x + (collectionView.bounds.width / 2.0)
       
        //Converted from contentOffset.x to contentOffset.y
        //and from collectionView.bounds.widt to collectionView.bounds.heigh
        let deltaOffset = Int(collectionView.contentOffset.y) % Int( collectionView.bounds.height)
        let percentageDeltaOffset = CGFloat(deltaOffset) / collectionView.bounds.height
       
        let visibleIndices = minVisibleIndex..<maxVisibleIndex
       
        let attributes: [UICollectionViewLayoutAttributes] = visibleIndices.map { index in
            let indexPath = IndexPath(item: index, section: 0)
            return computeLayoutAttributesForItem(indexPath: indexPath,
                                                  minVisibleIndex: minVisibleIndex,
                                                  contentCenterX: contentCenterX,
                                                  deltaOffset: CGFloat(deltaOffset),
                                                  percentageDeltaOffset: percentageDeltaOffset)
        }
       
        return attributes
    }
   
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let contentCenterX = collectionView.contentOffset.x + (collectionView.bounds.width / 2.0)
        let minVisibleIndex = Int(collectionView.contentOffset.x) / Int(collectionView.bounds.width)
       
        //Converted from contentOffset.x to contentOffset.y
        //and from collectionView.bounds.widt to collectionView.bounds.heigh
        let deltaOffset = Int(collectionView.contentOffset.y) % Int(collectionView.bounds.height)
        let percentageDeltaOffset = CGFloat(deltaOffset) / collectionView.bounds.height
       
        return computeLayoutAttributesForItem(indexPath: indexPath,
                                              minVisibleIndex: minVisibleIndex,
                                              contentCenterX: contentCenterX,
                                              deltaOffset: CGFloat(deltaOffset),
                                              percentageDeltaOffset: percentageDeltaOffset)
    }
   
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
 
 
// MARK: - Layout computations
fileprivate extension CardsCollectionViewLayout {
   
    private func scale(at index: Int) -> CGFloat {
        let translatedCoefficient = CGFloat(index) - CGFloat(self.maximumVisibleItems) / 2
        return CGFloat(pow(0.95, translatedCoefficient))
    }
 
    private func transform(atCurrentVisibleIndex visibleIndex: Int, percentageOffset: CGFloat) -> CGAffineTransform {
        var rawScale = visibleIndex < maximumVisibleItems ? scale(at: visibleIndex) : 1.0
 
        if visibleIndex != 0 {
            let previousScale = scale(at: visibleIndex - 1)
            let delta = (previousScale - rawScale) * percentageOffset
            rawScale += delta
        }
        return CGAffineTransform(scaleX: rawScale, y: rawScale)
    }
   
    fileprivate func computeLayoutAttributesForItem(indexPath: IndexPath,
                                                    minVisibleIndex: Int,
                                                    contentCenterX: CGFloat,
                                                    deltaOffset: CGFloat,
                                                    percentageDeltaOffset: CGFloat) -> UICollectionViewLayoutAttributes {
        let attributes = UICollectionViewLayoutAttributes(forCellWith:indexPath)
        let visibleIndex = indexPath.row - minVisibleIndex
       
        //Using this to fill up screen with card with fixed % of margin
        attributes.size = CGSize(
            width: (collectionView.bounds.width - ((collectionView.bounds.width * 2)/100)) ,
            height: (collectionView.bounds.height - ((collectionView.bounds.height * 4)/100)))
       
        let midY = self.collectionView.bounds.midY
        attributes.center = CGPoint(x: contentCenterX + spacing * CGFloat(visibleIndex),
                                    y: midY + spacing * CGFloat(visibleIndex))
        attributes.zIndex = maximumVisibleItems - visibleIndex
       
        attributes.transform = transform(atCurrentVisibleIndex: visibleIndex,
                                         percentageOffset: percentageDeltaOffset)
        switch visibleIndex {
        case 0:
            attributes.center.y -= deltaOffset
            break
        case 1..<maximumVisibleItems:
            attributes.center.x -= spacing * percentageDeltaOffset
            attributes.center.y -= spacing * percentageDeltaOffset
           
            if visibleIndex == maximumVisibleItems - 1 {
                attributes.alpha = percentageDeltaOffset
            }
            break
        default:
            attributes.alpha = 0
            break
        }
        return attributes
    }
}
