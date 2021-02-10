//
//  File.swift
//  
//
//  Created by Franklyn Weber on 10/02/2021.
//

import UIKit


extension UIApplication {
    
    static var window: UIWindow? {
        return UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    }
}
