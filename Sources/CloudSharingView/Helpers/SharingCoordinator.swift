//
//  SharingCoordinator.swift
//  
//
//  Created by Franklyn Weber on 01/04/2021.
//

import Foundation
import SwiftUI
import CloudKit


class SharingCoordinator: NSObject, ObservableObject {
    
    enum SharingError: Error {
        case noZone
        case nilShare
    }
    
    private var parent: CloudSharingView!
    private var response: ((ShareResult) -> ())!
    
    
    func presentAlreadyShared(parent: CloudSharingView, share: CKShare, response: @escaping (ShareResult) -> ()) {
        
        self.parent = parent
        self.response = response
        
        let sharingController = CloudSharingController(isPresented: parent.$isPresented, share: share, container: parent.container)
        
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        sharingController.delegate = self
        
        sharingController.popoverPresentationController?.sourceView = nil
        
        UIApplication.window?.rootViewController?.present(sharingController, animated: true)
    }
    
    func presentUnshared(parent: CloudSharingView, response: @escaping (ShareResult) -> ()) {
        
        guard let sharable = parent.itemToShare()?.sharable, let record = sharable.rootRecord, let zoneId = sharable.zone?.zoneID else {
            response(.failure(SharingError.noZone))
            return
        }
        
        self.parent = parent
        self.response = response
        
        let sharingController = CloudSharingController(isPresented: parent.$isPresented) { _, handler in
            
            let shareId = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneId)
            var share = CKShare(rootRecord: record, shareID: shareId)
            
            share[CKShare.SystemFieldKey.title] = sharable.shareName
            share[CKShare.SystemFieldKey.thumbnailImageData] = sharable.thumbnailImage?.pngData()
            share.publicPermission = .none
            
            let makeShared = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
            
            makeShared.modifyRecordsCompletionBlock = { records, recordIds, error in
                
                if let ckError = handleCloudKitError(error, operation: .modifyRecords, affectedObjects: [shareId]) {
                    if let serverVersion = ckError.serverRecord as? CKShare {
                        share = serverVersion
                    }
//                    if ckError.code == .serverRecordChanged {
//                        handler(share, parent.container, nil)
//                        return
//                    }
                }
                
                handler(share, parent.container, error)
            }
            
            parent.container.privateCloudDatabase.add(makeShared)
        }
        
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        sharingController.delegate = self
        
        UIApplication.window?.rootViewController?.present(sharingController, animated: true)
    }
}


extension SharingCoordinator: UICloudSharingControllerDelegate {
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        
        guard let share = csc.share, let rootRecord = parent.itemToShare()?.sharable?.rootRecord else {
            response(.failure(SharingError.nilShare)) // shouldn't be able to happen
            return
        }
        
        response(.shared(share: share, rootRecord: rootRecord))
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        response(.failure(error))
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        
        guard let rootRecord = parent.itemToShare()?.sharable?.rootRecord else {
            response(.failure(SharingError.nilShare)) // shouldn't be able to happen
            return
        }
        
        response(.stoppedSharing(rootRecord: rootRecord))
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return parent.itemToShare()?.sharable?.thumbnailImage?.pngData()
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        
        let shareTitle = NSLocalizedString("Share", bundle: .module, comment: "Share '%@'")
        
        if let title = parent.itemToShare()?.sharable?.shareName {
            return String(format: shareTitle, title)
        }
                
        return NSLocalizedString("ShareGeneric", bundle: .module, comment: "Share")
    }
}
