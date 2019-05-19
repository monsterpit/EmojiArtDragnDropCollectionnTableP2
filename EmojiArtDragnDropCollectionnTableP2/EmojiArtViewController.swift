//
//  EmojiArtViewController.swift
//  EmojiArtDragAndDrop
//
//  Created by Boppo on 02/05/19.
//  Copyright © 2019 MB. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController,UIDropInteractionDelegate,UIScrollViewDelegate , UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout , UICollectionViewDragDelegate,UICollectionViewDropDelegate{

    @IBOutlet weak var dropZone: UIView! {
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
            
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    
    var emojiArtView = EmojiArtView()
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        
        scrollViewHeight.constant = scrollView.contentSize.height
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    var emojiArtBackImage : UIImage?{
        get{
            return emojiArtView.backgroundImage
        }
        set{
            scrollView?.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue
            let size = newValue?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            
            scrollViewWidth?.constant = size.width
            
            scrollViewHeight?.constant = size.height
            
            if let dropZone = self.dropZone , size.width > 0 , size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width/size.width, dropZone.bounds.size.height/size.height )
            }
            
        }
    }
    
    //canHandle -> sessionUpdate -> PerformDrop
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        
        return UIDropProposal(operation: .copy)
    }
    
    
    var imageFetcher : ImageFetcher!
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        imageFetcher = ImageFetcher(){ (url,image) in
            DispatchQueue.main.async {
                self.emojiArtBackImage = image
            }
        }
        
        
        session.loadObjects(ofClass: NSURL.self) { (nsurls) in
            if let url = nsurls.first as? URL{
                self.imageFetcher.fetch(url)
            }
        }
        session.loadObjects(ofClass: UIImage.self) { (images) in
            
            if let image = images.first as? UIImage{
                self.imageFetcher.backup = image
            }
            
            
        }
    }
    
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.dataSource = self
            
            emojiCollectionView.delegate = self
            
            emojiCollectionView.dragDelegate = self
            
            emojiCollectionView.dropDelegate = self
        }
    }
    
    //map just takes in an collection and turn's it into an array where it executes a closure on each of the element
    var emojis = "🍭👻🤪🧞‍♂️🦊🦄🐝🦍🐉🐲🍩⚽️✈️".map { String($0)}
    
    // so there are 3 required numberOfItemsInSection,cellForItemAt , numberOfSection
    // we dont want to implement numberOfScetions as it defaults to 1 that's true for tableView and collectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    //MARK:- Dynamic Font accessibility UIFontMetrics Accessbility
    private var font : UIFont  {
        
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        
        if let emojiCell = cell as? EmojiCollectionViewCell{
            
            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font : font])
            
            emojiCell.label.attributedText = text
        }
        
        return cell
    }
    
    // itemsForBeginning is the thing that tells dragging system here's what we are dragging  , so we have to provide dragItem to drag
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        //MARK: - Context of Session to track who is it
        session.localContext = collectionView
        
        return dragItems(at : indexPath)
    }
    
    // So remember you can start a drag and add more items by tapping on them so you could be dragging multiple things at once that's easy to implement as well just like we have item
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at : indexPath)
    }
    
    private func dragItems(at indexPath : IndexPath)-> [UIDragItem]{
        
        if let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label?.attributedText {

            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))

            dragItem.localObject = attributedString
            
            return [dragItem]
        }
        else{
            return []
        }
        
    }
    

    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy , intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {

        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)

        for item in coordinator.items{
            if let sourceindexPath = item.sourceIndexPath{

                if let dragItem = item.dragItem.localObject as? NSAttributedString {

                    collectionView.performBatchUpdates({
                        
                        emojis.remove(at: sourceindexPath.item)
                        emojis.insert(dragItem.string, at: destinationIndexPath.item)
                        
                        
                        collectionView.deleteItems(at: [sourceindexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                        
                    })
                    
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
                
            }
            else{
                                let placeHolderContext  = coordinator.drop(
                                    item.dragItem,
                                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell")
                                )

                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in

                    DispatchQueue.main.async {
                        
                        if let attributedString = provider as? NSAttributedString{
                        placeHolderContext.commitInsertion(dataSourceUpdates: { (insertionIndexPath) in
       
                            self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                        })
                        }
                        else{

                            placeHolderContext.deletePlaceholder()
                        }
                    
                    }

                }

            }
        }
    }

}

