//
//  CloudSharingView.swift
//
//  Created by Franklyn Weber on 08/02/2021.
//

import SwiftUI
import CloudKit


public protocol CloudSharable {
    var record: CKRecord? { get }
    var shareName: String { get }
}

public extension CloudSharable {
    
    var shareName: String {
        return NSLocalizedString("Item", bundle: .module, comment: "Item")
    }
}


public struct CloudSharingView: View {
    
    @Binding private var isPresented: Bool
    
    private let record: CKRecord?
    
    internal var name: String
    internal var container: CKContainer = .default()
    internal var image: UIImage?
    
    
    public init(isPresented: Binding<Bool>, itemToShare: CloudSharable) {
        _isPresented = isPresented
        record = itemToShare.record
        name = itemToShare.shareName
    }
    
    public var body: some View {
        
        if isPresented {
            presentSharingController()
        }
    }
    
    private func presentSharingController() -> EmptyView {
        
        guard let record = record else {
            print("Failed to create record for sharing")
            return EmptyView()
        }
        
        let share = CKShare(rootRecord: record)
        share["CKShareTitleKey"] = name
        
        let controller = SharingController(isPresented: _isPresented, title: name) { cloudSharingController, handler in
            
            let makeSharedList = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
            
            makeSharedList.modifyRecordsCompletionBlock = { record, recordId, error in
                handler(share, CKContainer.default(), error)
            }
            
            container.privateCloudDatabase.add(makeSharedList)
        }
        
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.image = image
    
        UIApplication.window?.rootViewController?.present(controller, animated: true)
        
        return EmptyView()
    }
}
