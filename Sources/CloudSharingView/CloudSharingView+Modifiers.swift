//
//  CloudSharingView+Modifiers.swift
//  
//
//  Created by Franklyn Weber on 10/02/2021.
//

import SwiftUI
import CloudKit


extension CloudSharingView {
    
    /// The thumbnail image shown in the sharing controller
    /// - Parameter thumbnailImage: a UIImage
    public func thumbnailImage(_ thumbnailImage: UIImage?) -> Self {
        var copy = self
        copy.thumbnailImage = thumbnailImage
        return copy
    }
    
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
    ///   - itemToShare: the item to share, which must conform to CloudSharable
    public func cloudSharingView(isPresented: Binding<Bool>, itemToShare: CloudSharable) -> some View {
        modifier(CloudSharingViewPresentationModifier(content: { CloudSharingView(isPresented: isPresented, itemToShare: itemToShare)}))
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
