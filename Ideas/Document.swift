//
//  Document.swift
//  Ideas
//
//  Created by Joseph, Ethan on 4/11/17.
//  Copyright © 2017 Joseph, Ethan. All rights reserved.
//

import Cocoa
import MapKit

//Names of files and directories in the package
enum IdeaDocumentFileNames : String {
    case TextFile = "Text.rtf"
    
    case AttachmentsDirectory = "Attachments"
    
}

@objc protocol AttachmentCellDelegate : NSObjectProtocol {
    func openSelectedAttachment(_ collectionViewItem: NSCollectionViewItem)
}

extension Document : AttachmentCellDelegate{
    func openSelectedAttachment(_ collectionViewItem: NSCollectionViewItem) {
        // Get the index of this item or bail out
        guard let selectedIndex = (self.attachmentsList.indexPath(for: collectionViewItem) as IndexPath?)?.item else{
            return
        }
        
        // Get the selected Attachment or bail out
        guard let attachment = self.attachedFiles?[selectedIndex] else {
            return
        }
        
        // First ensure that the document is saved
        self.autosave(withImplicitCancellability: false, completionHandler: { (error) -> Void in
            
            // if the attachment is JSON and we can retrieve
            if attachment.conforms(to: kUTTypeJSON),
                let data = attachment.regularFileContents,
            let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? NSDictionary {
                
                //if that entry contains lat and long entries
                if let lat = json?["lat"] as? CLLocationDegrees,
                    let lon = json?["long"] as? CLLocationDegrees{
                    
                    //build a coordinate from them
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    
                    //build a placemark with that coordinate
                    let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
                    
                    //build map item from placemark
                    let mapItem = MKMapItem(placemark: placemark)
                    
                    //open the maps item in the maps app
                    mapItem.openInMaps(launchOptions: nil)
                } else {
                
                
                    var url = self.fileURL
                    url = url?.appendingPathComponent(IdeaDocumentFileNames.AttachmentsDirectory.rawValue, isDirectory: true)
            
                    url = url?.appendingPathComponent(attachment.preferredFilename!)
            
                    if let path = url?.path {
                        NSWorkspace.shared().openFile(path, withApplication: nil, andDeactivate: true)
                    }
                }
            }
        })
    }
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

extension Document : NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.attachedFiles?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        // Get the attachment that this cell should represent
        let attachment = self.attachedFiles![(indexPath as NSIndexPath).item]
        
        // Get the cell itself
        let item = collectionView
        .makeItem(withIdentifier: "AttachmentCell", for: indexPath) as! AttachmentCell
        
        // Display the image and file exgtension in the ecell
        //item.imageView?.image = attachment.thumbnailImage
        
        item.textField?.stringValue = attachment.fileExtension ?? ""
        
        //make this cell use itself as it's delegate
        item.delegate = self
        
        return item
    }
}

extension Document : AddAttachmentDelegate {
    func addFile() {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { (result) -> Void in
            if result == NSModalResponseOK,
                let resultURL = panel.urls.first {
                do {
                    //We were given a URL - copy it in
                    try self.addAttachmentAtURL(url: resultURL)
                    
                    //Refresh the attachments list
                    self.attachmentsList?.reloadData();
                } catch let error as NSError {
                    
                    // There was an error adding the attachment.
                    // Show the user!
                    
                    //try to get a window to present a sheet in
                    if let window = self.windowForSheet {
                        //Present the error in a sheet
                        NSApp.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
                    } else {
                        //No window, so present it in a dialog box
                        NSApp.presentError(error)
                    }
                }
            }
            
        }
    }
}

class Document: NSDocument {
    
    @IBOutlet var attachmentsList: NSCollectionView!
    
    @IBAction func addAttachment(_ sender: NSButton) {
        
        if let viewController = AddAttachmentViewController(nibName:"AddAttachmentViewController", bundle:Bundle.main){
            
            viewController.delegate = self
            
            self.popover = NSPopover()
            
            self.popover?.behavior = .transient
            
            self.popover?.contentViewController = viewController
            
            self.popover?.show(relativeTo: sender.bounds
                , of: sender, preferredEdge: NSRectEdge.maxY)
        }
    }
    
    // Main text content
    var text : NSAttributedString = NSAttributedString()
    
    var documentFileWrapper = FileWrapper(directoryWithFileWrappers: [:])
    
    var popover : NSPopover?
    
    private var attachmentsDirectoryWrapper : FileWrapper? {
        
        guard let fileWrappers = self.documentFileWrapper.fileWrappers else {
            NSLog("Attempting to access document's contents, but none found!")
            return nil
        }
        
        //Represents the attachments folder inside the documents package
        var attachmentsDirectoryWrapper =
            fileWrappers[IdeaDocumentFileNames.AttachmentsDirectory.rawValue]
        
        if attachmentsDirectoryWrapper == nil {
            
            attachmentsDirectoryWrapper =
                FileWrapper(directoryWithFileWrappers: [:])
            
            attachmentsDirectoryWrapper?.preferredFilename = IdeaDocumentFileNames.AttachmentsDirectory.rawValue
            
            self.documentFileWrapper.addFileWrapper(attachmentsDirectoryWrapper!)
        }
        
        return attachmentsDirectoryWrapper
    }
    
    //Adds an attachment to the attachment directory
    func addAttachmentAtURL(url:URL) throws {
        
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.CannotAccessAttachments)
        }
        
        self.willChangeValue(forKey: "attachedFiles")
        
        let newAttachment = try FileWrapper(url: url, options: FileWrapper.ReadingOptions.immediate)
        
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        
        self.updateChangeCount(.changeDone)
        self.didChangeValue(forKey: "attachedFiles")
    }
    
    //gets the dictionary that maps filenames to file wrappers inside the Attachments directory and returns the list of file wrappers
    dynamic var attachedFiles : [FileWrapper]? {
        if let attachmentsFileWrappers = self.attachmentsDirectoryWrapper?.fileWrappers{
            let attachments = Array(attachmentsFileWrappers.values)
            return attachments
        } else {
            return nil
        }
    }
    
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

