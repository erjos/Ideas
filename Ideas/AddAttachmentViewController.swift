//
//  AddAttachmentViewController.swift
//  Ideas
//
//  Created by Joseph, Ethan on 4/12/17.
//  Copyright © 2017 Joseph, Ethan. All rights reserved.
//

import Cocoa

protocol AddAttachmentDelegate {
    func addFile()
}

class AddAttachmentViewController: NSViewController {

    @IBAction func addFile(_ sender: Any) {
        self.delegate?.addFile()
    }
    
    var delegate : AddAttachmentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
