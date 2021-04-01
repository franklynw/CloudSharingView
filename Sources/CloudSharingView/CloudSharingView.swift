//
//  CloudSharingView.swift
//
//  Created by Franklyn Weber on 08/02/2021.
//

import SwiftUI
import CloudKit
import TopAlert


public protocol CloudSharable {
    var rootRecord: CKRecord { get }
    var sharedRecordId: CKRecord.ID? { get }
    var shareName: String { get }
    var image: UIImage? { get }
}

public extension CloudSharable {
    
    var image: UIImage? {
        return nil
    }
}


public typealias SharingResult = Result<(rootRecord: CKRecord, share: CKShare), Error>


public struct CloudSharingView: View {
    
    @StateObject private var sharingCoordinator = SharingCoordinator()
    @Binding internal var isPresented: Bool
    @State private var topAlertConfig: TopAlert.AlertConfig?
    
    internal let itemToShare: () -> (share: CloudSharable?, done: (SharingResult) -> ())
    
    internal var container: CKContainer = .default()
    internal var sharedZoneName: String?
    internal var thumbnailImage: UIImage?
    
    private struct ResultMessage: Identifiable {
        let value: String
        var id: String {
            return value
        }
        
        init(_ message: String) {
            value = message
        }
    }
    
    
    public init(isPresented: Binding<Bool>, share: @escaping () -> (share: CloudSharable?, done: (SharingResult) -> ())) {
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
        
        guard let share = itemToShare().share else {
            return EmptyView()
        }
        
        if let shareId = share.sharedRecordId {
            shareExisting(share, with: shareId)
        } else {
            createNew(share)
        }
        
        return EmptyView()
    }
    
    private func shareExisting(_ share: CloudSharable, with shareId: CKRecord.ID) {
        
        container.privateCloudDatabase.fetch(withRecordID: shareId) { record, error in
            
            guard let sharedRecord = record as? CKShare else {
                
                let title = NSLocalizedString("ShareDeletedTitle", bundle: .module, comment: "Share deleted title")
                let message = NSLocalizedString("ShareDeletedMessage", bundle: .module, comment: "Share deleted message")
                
                let createNewButton = TopAlert.AlertConfig.ButtonType.default(title: "") {
                    createNew(share)
                }
                let cancelButton = TopAlert.AlertConfig.ButtonType.cancel {
                    isPresented = false
                }
                
                topAlertConfig = .init(title: title, message: message, buttons: [createNewButton, cancelButton])
                
                return
            }
            
            DispatchQueue.main.async {
                sharingCoordinator.present(parent: self, rootRecord: share.rootRecord, share: sharedRecord, response: processSharingResponse)
            }
        }
    }
    
    private func createNew(_ share: CloudSharable) {
        
        let shareZone = CKRecordZone(zoneName: sharedZoneName ?? "SharedZone")
        
        container.privateCloudDatabase.save(shareZone) { zone, error in
            
            guard error == nil, let zone = zone else {
                DispatchQueue.main.async {
                    topAlertConfig = .init(title: NSLocalizedString("ShareZoneUnavailable", bundle: .module, comment: "Zone unavailable")) {
                        isPresented = false
                    }
                }
                return
            }
            
            let recordId = CKRecord.ID(recordName: share.rootRecord.recordID.recordName, zoneID: zone.zoneID)
            let rootRecord = CKRecord(recordType: share.rootRecord.recordType, recordID: recordId)
            
            share.rootRecord.allKeys().forEach {
                if let value = share.rootRecord.value(forKey: $0) as? CKRecordValue {
                    rootRecord[$0] = value
                }
            }
            
            container.privateCloudDatabase.save(rootRecord) { record, error in
                
                DispatchQueue.main.async {
                    
                    guard error == nil, let rootRecord = record else {
                        topAlertConfig = .init(title: NSLocalizedString("iCloudAccountUnavailable", bundle: .module, comment: "Share failure")) {
                            isPresented = false
                        }
                        return
                    }
                    
                    sharingCoordinator.present(parent: self, rootRecord: rootRecord, response: processSharingResponse)
                }
            }
        }
    }
    
    private func processSharingResponse(_ result: SharingResult) {
        
        isPresented = false
        
        switch result {
        case .success(let records):
            topAlertConfig = .init(title: NSLocalizedString("ShareSuccess", bundle: .module, comment: "Share success")) {
                itemToShare().done(.success((records.rootRecord, records.share)))
            }
        case .failure:
            topAlertConfig = .init(title: NSLocalizedString("ShareFailure", bundle: .module, comment: "Share failure"))
        }
    }
}
