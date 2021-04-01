//
//  SharingCoordinator.swift
//  
//
//  Created by Franklyn Weber on 01/04/2021.
//

import Foundation
import SwiftUI
import CloudKit


class SharingCoordinator: NSObject, UICloudSharingControllerDelegate, ObservableObject {
    
    enum SharingError: Error {
        case nilShare
    }
    
    private var parent: CloudSharingView!
    private var response: ((SharingResult) -> ())!
    private var rootRecord: CKRecord?
    private var share: CKShare?
    
    
    func present(parent: CloudSharingView, rootRecord: CKRecord, share: CKShare, response: @escaping (SharingResult) -> ()) {
        
        self.parent = parent
        self.rootRecord = rootRecord
        self.share = share
        self.response = response
        
        let sharingController = CloudSharingController(isPresented: parent.$isPresented, share: share, container: parent.container)
        
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        sharingController.delegate = self
        
        UIApplication.window?.rootViewController?.present(sharingController, animated: true)
    }
    
    func present(parent: CloudSharingView, rootRecord: CKRecord, response: @escaping (SharingResult) -> ()) {
        
        self.parent = parent
        self.rootRecord = rootRecord
        self.response = response
        
        let sharingController = CloudSharingController(isPresented: parent.$isPresented) { cloudSharingController, handler in
            
            let share = CKShare(rootRecord: rootRecord)
            share["CKShareTitleKey"] = parent.itemToShare().share?.shareName
            share.publicPermission = .none
            
            let makeSharedList = CKModifyRecordsOperation(recordsToSave: [rootRecord, share], recordIDsToDelete: nil)
            
            makeSharedList.modifyRecordsCompletionBlock = { record, recordId, error in
                handler(share, parent.container, error)
                self.share = share
            }
            
            parent.container.privateCloudDatabase.add(makeSharedList)
        }
        
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        sharingController.delegate = self
        
        UIApplication.window?.rootViewController?.present(sharingController, animated: true)
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        
        guard let rootRecord = rootRecord, let share = self.share else {
            response(.failure(SharingError.nilShare))
            return
        }
        
        response(.success((rootRecord, share)))
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        response(.failure(error))
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        // todo
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return parent.thumbnailImage?.pngData() ?? parent.itemToShare().share?.image?.pngData()
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        
        let shareTitle = NSLocalizedString("Share", bundle: .module, comment: "Share '%@'")
        
        if let title = parent.itemToShare().share?.shareName {
            return String(format: shareTitle, title)
        }
                
        return NSLocalizedString("ShareGeneric", bundle: .module, comment: "Share")
    }
}
