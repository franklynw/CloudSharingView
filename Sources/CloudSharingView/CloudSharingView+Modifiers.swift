//
//  CloudSharingView+Modifiers.swift
//  
//
//  Created by Franklyn Weber on 10/02/2021.
//

import SwiftUI
import CloudKit


extension CloudSharingView {
    
    /// The CloudKit container used by the sharing - defaults to .default()
    /// - Parameter container: a CKContainer
    public func container(_ container: CKContainer) -> Self {
        var copy = self
        copy.container = container
        return copy
    }
}


extension View {
    
    /// View extension in the style of .sheet - lacks a couple of customisation options. If more flexibility is required, use CloudSharingView(...) directly, and apply the required modifiers
    /// - Parameters:
    ///   - isPresented: binding to a Bool which controls whether or not to show the picker
    ///   - share: closure which returns the item to share, which must conform to CloudSharable, and a completion closure where the root & shared records are returned
    public func cloudSharingView(isPresented: Binding<Bool>, share: @escaping () -> (share: CloudSharable, done: (ShareResult) -> ())) -> some View {
        modifier(CloudSharingViewPresentationModifier(content: { CloudSharingView(isPresented: isPresented, share: share)}))
    }
}


struct CloudSharingViewPresentationModifier: ViewModifier {
    
    var content: () -> CloudSharingView
    
    init(@ViewBuilder content: @escaping () -> CloudSharingView) {
        self.content = content
    }
    
    func body(content: Content) -> some View {
        Group {
            content
            self.content()
        }
    }
}
