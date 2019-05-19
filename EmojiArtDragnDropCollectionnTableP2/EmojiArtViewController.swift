//
//  EmojiArtViewController.swift
//  EmojiArtDragAndDrop
//
//  Created by Boppo on 02/05/19.
//  Copyright © 2019 MB. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController,UIDropInteractionDelegate,UIScrollViewDelegate , UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout , UICollectionViewDragDelegate,UICollectionViewDropDelegate{

    

    
    
    //UICollectionViewDelegateFlowLayout this 1 you automatically get to be when you are delegate of collectionView
    // This is the delegate of the thing that does all text like flowing layout
    // remember collectionView layout is completely configurable  but this 1 is the default one so throw this 1 in too it helps escape completion and all those stuffs
    
    

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
        //WithSize so I want 64 points but I want to scale with with whatever the accessibility thing is
        // So If accessibility font is at middle the font I am gonna do is 64 , can do bigger and wit will be bigger than 64 and smaller
        // Now this wouldnt work very well because I dont change collectionview size < If i set this big it will be cut off and If I set it really small the collection viwe wont shrink up to kind of hold it
        //TODO:- To make collectionView cell size accordin to font accessibility size using layout constraint that  is constaint layout outlet
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
    // So what we gonna do is that when we start our drag up in itemForBeginning  we gonna set something in session called localContext and this is type Any
        // This is just something in drag session that lets drop's people who drop know hey this is a local drag  and here's the context of it
        // well this drag is coming from collectionview  I am gonna use collectionView as context
        session.localContext = collectionView
        
        return dragItems(at : indexPath)
    }
    
    // So remember you can start a drag and add more items by tapping on them so you could be dragging multiple things at once that's easy to implement as well just like we have item
    //Just like  we have "itemsForBeginning" we have "itemsForAddingTo"
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
        
        // intent says are you dropping into this cell or you wanna add a cell
        // if we are dragging inside collectionView we dont want the emoji to be copied and we dont want a replica of it so we .move
        // so for .move we have to know somehow that we are inside the collectionView
        // So what we gonna do is that when we start our drag up in itemForBeginning  we gonna set something in session called localContext and this is type Any
        
        // So now we can look at the local context up here to determine where my drop proposal should be copy or move
        
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy , intent: .insertAtDestinationIndexPath)
    }
    
    
    //When drop happens we have to update our model and our collectionView
    //Also there are 2 different types of drop here
    //There's a drop where its coming from my collectionView in which case i have to drop it in new place and remove it from old place because i am moving
    //And then theirs a drop which is coming from some other app i.e. safari to collectionView tap and hold cursor on text and move it to collectionView
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        //coordinator gives us the destination Path
        // nil if we are putting it at start or end not in between of items
        // So we are providing a default position
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        // So now we now where we are dropping the drop and now its just matter of going through all the items  in coordinators items this items are UICollectionViews dropItems
        // And they have very interesting peices of information for e.g.
        
        //if let sourceindexPath = item.sourceIndexPath This ensure that our drag is coming from ourself  so we dont even have to look at the localContext in this case to know this is coming from me
        // And now we know the source and the destination
        //If the item originated from the collection view, this property contains the item's original index path.

        //So all we need to here is update our model and let source go into destination and then update the collectionview to remove the one from source and add it to other one
        for item in coordinator.items{
            if let sourceindexPath = item.sourceIndexPath{
                
                // As we stashed it to localObject we dont have to do NSProvider Stuff but we have to cast it  as NSAttributedString because its Any
                if let dragItem = item.dragItem.localObject as? NSAttributedString {
                    
                    
                    // ----------------------------------------------------///
                 //   emojis.remove(at: sourceindexPath.item)
                //    emojis.insert(dragItem.string, at: destinationIndexPath.item)
                    
                    //MARK:- Dont reload the data in middle of drag
                    // Dont reload data in middle of drag because it resets the whole world it's bad dont do it
                    //So instead we have to remove and insert the items separately
                    
                  //  collectionView.deleteItems(at: [sourceindexPath])
                    
                  //  collectionView.insertItems(at: [destinationIndexPath])
                    
                    // ----------------------------------------------------///
                    
                    // So this looks it will work fine but actualy its gonna crash the program
                    // The reason for that is when you do multiple changes to collectionView each step will require model to be completly in sync which it wouldnt be until I do both of this the table wount be in sync with the model
                   
                    //MARK:- So dont forget to do batchUpdates if you do multiple adjustment to your tableView or CollectionView
                    // theres a really cool way to get around that which is collectionView and tableView both has this methods called
                    //collectionView.performBatchUpdates(<#T##updates: (() -> Void)?##(() -> Void)?##() -> Void#>, completion: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)
                    // It just has a closure , In that closure you can put any number of  this deleteItems ,insertItems,moveItems whatever you want and it will do them all as one operation so that it never gets out of sync with the model
                    // It also has a nice completion thing when it's done with all update it will call that completion closure
                    collectionView.performBatchUpdates({
                        
                        emojis.remove(at: sourceindexPath.item)
                        emojis.insert(dragItem.string, at: destinationIndexPath.item)
                        
                        
                        collectionView.deleteItems(at: [sourceindexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                        
                    })
                    
                    //Then last thing we want to do is ask the coordinator to do the drop
                    //The reason we need to do this is we need to animate the drop happening there
                    
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
                
            }
        }
    }
    
    //For loading in collectionview all the cell are custom  cell so you have to a subclass it
    //If you have any outlet to anything you have to a subclass because we couldnt have a outlet in our collectionView itself that pointed to emoji because there could be hundred cells so we cant do it
    // So instead we have to create a new file which is a subclass of UICollectionView cell 
}


//Remember We cant drag and drop in collectionView as we havent implemented it but we can drop it in other apps , i.e. try picking emoji and dropping it in google search bar and it searches for it
// So its pretty cool I got dragged up working to other apps I hardly had to do anything in my app just provide that attributed string i drag and drop so that's cool thing about drag and drop its so easy to get it going in both directions
//So now we want it to drop so now we want emoji and drop it somewhere else in our collectionview
