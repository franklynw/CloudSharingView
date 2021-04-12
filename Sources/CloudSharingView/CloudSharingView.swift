//
//  CloudSharingView.swift
//
//  Created by Franklyn Weber on 08/02/2021.
//

import SwiftUI
import CloudKit
import TopAlert


public protocol CloudSharable {
    var zone: CKRecordZone? { get }
    var rootRecord: CKRecord? { get }
    var shareName: String { get }
    var thumbnailImage: UIImage? { get }
}

public extension CloudSharable {
    
    var thumbnailImage: UIImage? {
        return nil
    }
}


public enum ShareResult {
    case shared(share: CKShare, rootRecord: CKRecord)
    case stoppedSharing(rootRecord: CKRecord)
    case failure(Error)
}


public struct CloudSharingView: View {
    
    @StateObject private var sharingCoordinator = SharingCoordinator()
    @Binding internal var isPresented: Bool
    @State private var topAlertConfig: TopAlert.AlertConfig?
    
    internal let itemToShare: () -> (sharable: CloudSharable?, done: (ShareResult) -> ())?
    internal var container: CKContainer = .default()
    
    private struct ResultMessage: Identifiable {
        let value: String
        var id: String {
            return value
        }
        
        init(_ message: String) {
            value = message
        }
    }
    
    
    public init(isPresented: Binding<Bool>, share: @escaping () -> (share: CloudSharable?, done: (ShareResult) -> ())?) {
        _isPresented = isPresented
        self.itemToShare = share
    }
    
    public var body: some View {
        
        if isPresented {
            presentSharingController()
        }
        
        TopAlert(alertConfig: $topAlertConfig)
    }
    
    private func presentSharingController() -> EmptyView {
        
        guard let sharable = itemToShare()?.sharable, let record = sharable.rootRecord else {
            return EmptyView()
        }
        
        if record.share == nil { // not yet shared
            createNew()
        } else {
            shareExisting()
        }
        
        return EmptyView()
    }
    
    private func shareExisting() {
        
        guard let sharable = itemToShare()?.sharable, let record = sharable.rootRecord, let shareRecordId = record.share?.recordID else {
            return
        }
        
        let fetch = CKFetchRecordsOperation(recordIDs: [shareRecordId])
        
        fetch.fetchRecordsCompletionBlock = { records, error in
            
            guard handleCloudKitError(error, operation: .fetchRecords, affectedObjects: [shareRecordId]) == nil, let share = records?[shareRecordId] as? CKShare else {
                
                isPresented = false
                
                let title = NSLocalizedString("ShareDeletedTitle", bundle: .module, comment: "Share deleted title")
                let message = NSLocalizedString("ShareDeletedMessage", bundle: .module, comment: "Share deleted message")
                
                let createNewButton = TopAlert.AlertConfig.ButtonType.default(title: NSLocalizedString("CreateNewShareButton", bundle: .module, comment: "Create New")) {
                    createNew()
                }
                
                topAlertConfig = .init(title: title, message: message, buttons: [createNewButton, .cancel()])
                
                return
            }
            
            DispatchQueue.main.async {
                sharingCoordinator.presentAlreadyShared(parent: self, share: share, response: processSharingResponse)
            }
        }
        
        container.privateCloudDatabase.add(fetch)
    }
    
    private func createNew() {
        
        guard itemToShare()?.sharable?.zone != nil else {
            
            isPresented = false
            
            let title = NSLocalizedString("iCloudAccountUnavailable", bundle: .module, comment: "Share couldn't be created")
            
            topAlertConfig = .init(title: title)
            
            return
        }
        
        DispatchQueue.main.async {
            sharingCoordinator.presentUnshared(parent: self, response: processSharingResponse)
        }
    }
    
    private func processSharingResponse(_ result: ShareResult) {
        
        isPresented = false
        
        switch result {
        case .shared:
            topAlertConfig = .init(title: NSLocalizedString("ShareSuccess", bundle: .module, comment: "Share success")) {
                itemToShare()?.done(result)
            }
        case .stoppedSharing:
            topAlertConfig = .init(title: NSLocalizedString("StoppedSharing", bundle: .module, comment: "Stopped Sharing")) {
                itemToShare()?.done(result)
            }
        case .failure:
            topAlertConfig = .init(title: NSLocalizedString("ShareFailure", bundle: .module, comment: "Share failure"))
        }
    }
}
