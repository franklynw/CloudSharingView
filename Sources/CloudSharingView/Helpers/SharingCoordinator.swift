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
    
    enum SharingResult<Success, Failure> where Failure : Error {
        case success(Success)
        case failure(Failure)
        case other
    }
    
    private var parent: CloudSharingView!
    private var response: ((SharingResult<Void, Error>) -> ())!
    private var rootRecord: CKRecord?
    
    
    func present(parent: CloudSharingView, rootRecord: CKRecord, response: @escaping (SharingResult<Void, Error>) -> ()) {
        
        self.parent = parent
        self.rootRecord = rootRecord
        self.response = response
        
        let sharingController = CloudSharingController(isPresented: parent.$isPresented) { cloudSharingController, handler in
            
            let share = CKShare(rootRecord: rootRecord)
            share["CKShareTitleKey"] = parent.itemToShare.shareName
            share.publicPermission = .none
            
            let makeSharedList = CKModifyRecordsOperation(recordsToSave: [rootRecord, share], recordIDsToDelete: nil)
            
            makeSharedList.modifyRecordsCompletionBlock = { record, recordId, error in
                handler(share, parent.container, error)
            }
            
            parent.container.privateCloudDatabase.add(makeSharedList)
        }
        
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        sharingController.delegate = self
        
        UIApplication.window?.rootViewController?.present(sharingController, animated: true)
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        response(.success(()))
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        response(.failure(error))
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        // todo
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        return parent.thumbnailImage?.pngData() ?? parent.itemToShare.image?.pngData() ?? self.rootRecord?["CKShareThumbnailImageDataKey"]
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        let shareTitle = NSLocalizedString("Share", bundle: .module, comment: "Share '%@'")
        return String(format: shareTitle, parent.itemToShare.shareName)
    }
}
