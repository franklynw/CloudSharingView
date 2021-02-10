//
//  SharingController.swift
//  
//
//  Created by Franklyn Weber on 10/02/2021.
//

import SwiftUI
import CloudKit


class SharingController: UICloudSharingController, UICloudSharingControllerDelegate {
    
    @Binding private var isPresented: Bool
    var image: UIImage?
    
    
    init(isPresented: Binding<Bool>, share: CKShare, container: CKContainer) {
        _isPresented = isPresented
        super.init(share: share, container: container)
        delegate = self
    }
    
    init(isPresented: Binding<Bool>, title: String, preparationHandler: @escaping (UICloudSharingController, @escaping (CKShare?, CKContainer?, Error?) -> Void) -> Void) {
        _isPresented = isPresented
        super.init(preparationHandler: preparationHandler)
        self.title = title
        delegate = self
    }
    
    deinit {
        isPresented = false
        print("deinit sharing controller")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        
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
