//
//  EmojiArtView.swift
//  EmojiArtDragAndDrop
//
//  Created by Boppo on 02/05/19.
//  Copyright © 2019 MB. All rights reserved.
//

import UIKit

class EmojiArtView: UIView {

    
    var backgroundImage : UIImage? {
        didSet{
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        backgroundImage?.draw(in: bounds)
    }


}
