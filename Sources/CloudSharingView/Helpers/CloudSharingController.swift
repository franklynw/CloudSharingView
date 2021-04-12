//
//  CloudSharingController.swift
//  
//
//  Created by Franklyn Weber on 01/04/2021.
//

import Foundation
import SwiftUI
import CloudKit


class CloudSharingController: UICloudSharingController {
    
    @Binding private var isPresented: Bool
    
    init(isPresented: Binding<Bool>, share: CKShare, container: CKContainer) {
        _isPresented = isPresented
        super.init(share: share, container: container)
        view.backgroundColor = .systemBackground // for whatever reason, if we don't set this, it's see-through...
    }
    
    init(isPresented: Binding<Bool>, preparationHandler: @escaping (UICloudSharingController, @escaping (CKShare?, CKContainer?, Error?) -> Void) -> Void) {
        _isPresented = isPresented
        super.init(preparationHandler: preparationHandler)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isPresented = false // just in case it gets dismissed for any uncovered reason
    }
}
