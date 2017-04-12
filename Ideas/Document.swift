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

let ErrorDomain = "IdeasErrorDomain"


func err(_ code: ErrorCode, _ userInfo:[NSObject:Any]? = nil)
    -> NSError {
        //Generate an NSError object, using ErrorDomain and whatever value we were passed
        return NSError(domain: ErrorDomain, code : code.rawValue, userInfo: userInfo)
}

extension FileWrapper {
    dynamic var fileExtension : String? {
        return self.preferredFilename?
        .components(separatedBy: ".").last
    }
    
    dynamic var thumbnailImage : NSImage {
        
        if let fileExtension = self.fileExtension{
            return NSWorkspace.shared()
            .icon(forFileType: fileExtension)
        } else {
            return NSWorkspace.shared().icon(forFileType: "")
        }
    }
    
    func conforms(to aProtocol: CFString) -> Bool {
        
        // Get the extension of this file
        guard let fileExtension = self.fileExtension else {
            
            //If we can't get a file extension, assume it doesn't conform
            return false
        }
    
        // Get the file type of the attachment based on its extension
        guard let fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?
            .takeRetainedValue() else {
                // If we can't figure out the file type from the extension, it also doesn't conform
                return false
        }
        
        // Ask the system if this file type conforms to the provided type
        return UTTypeConformsTo(fileType, aProtocol)
    }
}

class Document: NSDocument {
    
    @IBOutlet weak var attachmentsList: NSScrollView!
    
    @IBAction func addAttachment(_ sender: Any) {
    }
    
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    
    var documentFileWrapper = FileWrapper(directoryWithFileWrappers: [:])
    
    //Prepares and returns a new file wrapper to the system, which then saves it to disk
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        
        let textRTFData = try self.text.data(from: NSRange(0..<self.text.length), documentAttributes: [NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType])
        
        //If the current document file wrapper already contains a  text file, remove it and replace with new one
        //I think that if the optional returns nil (aka nothings there) the conditonal binding returns false
            // and the code doesn't execute- would be cool to talk about this and see if I understand correctly
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[IdeaDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }
        
        //Save the text data into the file
        self.documentFileWrapper.addRegularFile(withContents: textRTFData, preferredFilename: IdeaDocumentFileNames.TextFile.rawValue)
        
        //return the main documents file wrapper - what is saved on disk
        return self.documentFileWrapper
    }
    
    //Loads document from the file wrapper
    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        
        //Ensure that we have additional file wrappers in this file wrapper
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(.CannotLoadFileWrappers)
        }
        
        //Ensure that we can access the document text
        guard let documentTextData = fileWrappers[IdeaDocumentFileNames.TextFile.rawValue]?.regularFileContents else {
            throw err(.CannotLoadText)
        }
        
        //Load the text data as RTF
        guard let documentText = NSAttributedString(rtf: documentTextData, documentAttributes: nil) else {
            throw err(.CannotLoadText)
        }
        
        //Keep the text in memory
        self.documentFileWrapper = fileWrapper
        self.text = documentText
    }
    
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

