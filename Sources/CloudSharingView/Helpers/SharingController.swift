//
//  SharingController.swift
//  
//
//  Created by Franklyn Weber on 10/02/2021.
//

import SwiftUI
import CloudKit


class SharingController: UICloudSharingController, UICloudSharingControllerDelegate {
    
    var image: UIImage?
    
    private let response: (Result<Void, Error>) -> ()
    
    
    init(share: CKShare, container: CKContainer, response: @escaping (Result<Void, Error>) -> ()) {
        self.response = response
        super.init(share: share, container: container)
        delegate = self
    }
    
    init(title: String, preparationHandler: @escaping (UICloudSharingController, @escaping (CKShare?, CKContainer?, Error?) -> Void) -> Void, response: @escaping (Result<Void, Error>) -> ()) {
        self.response = response
        super.init(preparationHandler: preparationHandler)
        self.title = title
        delegate = self
    }
    
    deinit {
        print("deinit sharing controller")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        response(.success(()))
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        response(.failure(error))
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return image?.pngData() ?? self.share?["CKShareThumbnailImageDataKey"]
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        
        let shareListTitle = NSLocalizedString("ShareList", bundle: .module, comment: "Share '%@'")
        
        if let title = self.share?["CKShareTitleKey"] as? String {
            return String(format: shareListTitle, title)
        }
        if let title = title {
            return String(format: shareListTitle, title)
        }
        
        return NSLocalizedString("ShareGenericList", bundle: .module, comment: "Share your list")
    }
}
