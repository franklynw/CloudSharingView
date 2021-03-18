//
//  CloudSharingView.swift
//
//  Created by Franklyn Weber on 08/02/2021.
//

import SwiftUI
import CloudKit


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
    
    @Binding private var isPresented: Bool
    @State private var shareResultMessage: ResultMessage?
    
    private let itemToShare: CloudSharable
    
    internal var container: CKContainer = .default()
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
        
        EmptyView()
            .alert(item: $shareResultMessage) { shareResultMessage in
                Alert(title: Text(shareResultMessage.value))
            }
    }
    
    private func presentSharingController() -> EmptyView {
        
        let share = CKShare(rootRecord: itemToShare.record)
        share["CKShareTitleKey"] = itemToShare.shareName
        
        let controller = SharingController(title: itemToShare.shareName) { cloudSharingController, handler in
            
            let makeSharedList = CKModifyRecordsOperation(recordsToSave: [itemToShare.record, share], recordIDsToDelete: nil)
            
            makeSharedList.modifyRecordsCompletionBlock = { record, recordId, error in
                handler(share, CKContainer.default(), error)
            }
            
            container.privateCloudDatabase.add(makeSharedList)
            
        } response: { result in
            
            isPresented = false
            
            switch result {
            case .success:
                shareResultMessage = ResultMessage(NSLocalizedString("ShareSuccess", bundle: .module, comment: "Share success"))
            case .failure:
                shareResultMessage = ResultMessage(NSLocalizedString("ShareFailure", bundle: .module, comment: "Share success"))
            }
        }
        
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.image = itemToShare.image ?? thumbnailImage
    
        UIApplication.window?.rootViewController?.present(controller, animated: true)
        
        return EmptyView()
    }
}
