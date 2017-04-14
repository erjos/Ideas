//
//  AttachmentCell.swift
//  Ideas
//
//  Created by Joseph, Ethan on 4/12/17.
//  Copyright © 2017 Joseph, Ethan. All rights reserved.
//

import Cocoa

class AttachmentCell: NSCollectionViewItem {
    
    @IBOutlet var imageWell: NSImageView!
    //property that keeps a reference to an object that conforms to the delegate
    weak var delegate : AttachmentCellDelegate?
    
    //implement mouse down, called whenever user clicks on cells views
    override func mouseDown(with event: NSEvent) {
        if (event.clickCount == 2) {
            delegate?.openSelectedAttachment(self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        collectionView.reloadData()
    }
}
