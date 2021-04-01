//
//  CloudSharingView.swift
//
//  Created by Franklyn Weber on 08/02/2021.
//

import SwiftUI
import CloudKit
import TopAlert


public protocol CloudSharable {
    var record: CKRecord { get }
    var shareName: String { get }
    var image: UIImage? { get }
}

public extension CloudSharable {
    
    var image: UIImage? {
        return nil
    }
}


public struct CloudSharingView: View {
    
    @StateObject private var sharingCoordinator = SharingCoordinator()
    @Binding internal var isPresented: Bool
    @State private var topAlertConfig: TopAlert.AlertConfig?
    
    internal let itemToShare: CloudSharable
    
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
    
    
    public init(isPresented: Binding<Bool>, itemToShare: CloudSharable) {
        _isPresented = isPresented
        self.itemToShare = itemToShare
    }
    
    public var body: some View {
        
        if isPresented {
            presentSharingController()
        }
        
        TopAlert(alertConfig: $topAlertConfig)
    }
    
    private func presentSharingController() -> EmptyView {
        
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
            
            let recordId = CKRecord.ID(recordName: itemToShare.record.recordID.recordName, zoneID: zone.zoneID)
            let rootRecord = CKRecord(recordType: itemToShare.record.recordType, recordID: recordId)
            
            itemToShare.record.allKeys().forEach {
                if let value = itemToShare.record.value(forKey: $0) as? CKRecordValue {
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
                    
                    sharingCoordinator.present(parent: self, rootRecord: rootRecord) { result in
                        
                        isPresented = false
                        
                        switch result {
                        case .success:
                            topAlertConfig = .init(title: NSLocalizedString("ShareSuccess", bundle: .module, comment: "Share success")) {
                                isPresented = false
                            }
                        case .failure:
                            topAlertConfig = .init(title: NSLocalizedString("ShareFailure", bundle: .module, comment: "Share failure")) {
                                isPresented = false
                            }
                        case .other:
                            isPresented = false
                        }
                    }
                }
            }
        }
        
        return EmptyView()
    }
}
