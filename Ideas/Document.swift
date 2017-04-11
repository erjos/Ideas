//
//  Document.swift
//  Ideas
//
//  Created by Joseph, Ethan on 4/11/17.
//  Copyright © 2017 Joseph, Ethan. All rights reserved.
//

import Cocoa

//Names of files and directories in the package
enum IdeaDocumentFileNames : String {
    case TextFile = "Text.rtf"
    
    case AttachmentsDirectory = "Attachments"
    
}

enum ErrorCode : Int {
    /// Couldn't find document
    case CannotAccessDocument
    
    /// Couldn't access any file wrappers inside this document
    case CannotLoadFileWrappers
    
    /// Couldn't load the Text.rtf file
    case CannotLoadText
    
    /// Couldn't Access the Attachments folder
    case CannotAccessAttachments
    
    /// Couldn't save the Text.rtf file
    case CannotSaaveText
    
    /// Couldn't save an attachment
    case CannotSaveAttachment
}

let ErrorDomain = "IdeasErrorDoman"


func err(_ code: ErrorCode, _ userInfo:[NSObject:Any]? = nil)
    -> NSError {
        //Generate an NSError object, using ErrorDomain and whatever value we were passed
        return NSError(domain: ErrorDomain, code : code.rawValue, userInfo: userInfo)
}

class Document: NSDocument {

    // Main text content
    var text : NSAttributedString = NSAttributedString()
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }


}

