//
//  HandleCloudKitError.swift
//  
//
//  Created by Franklyn Weber on 02/04/2021.
//

import Foundation
import CloudKit


enum CloudKitOperationType: String {
    
    case accountStatus = "AccountStatus"// Checking account status with CKContainer.accountStatus.
    case fetchRecords = "FetchRecords"  // Fetching data from the CloudKit server.
    case modifyRecords = "ModifyRecords"// Modifying records (.serverRecordChanged should be handled).
    case deleteRecords = "DeleteRecords"// Deleting records.
    case modifyZones = "ModifyZones"    // Modifying zones (.serverRecordChanged should be handled).
    case deleteZones = "DeleteZones"    // Deleting zones.
    case fetchZones = "FetchZones"      // Fetching zones.
    case modifySubscriptions = "ModifySubscriptions"    // Modifying subscriptions.
    case deleteSubscriptions = "DeleteSubscriptions"    // Deleting subscriptions.
    case fetchChanges = "FetchChanges"  // Fetching changes (.changeTokenExpired should be handled).
    case acceptShare = "AcceptShare"    // Accepting a share with CKAcceptSharesOperation.
    case fetchUserID = "FetchUserID"    // Fetching user record ID with fetchUserRecordID(completionHandler:).
}


func handleCloudKitError(_ error: Error?, operation: CloudKitOperationType, affectedObjects: [Any]? = nil) -> CKError? {
    
    guard let error = error else {
        return nil
    }
    
    let nsError = error as NSError
    
    if let partialErrors = nsError.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
        
        let errors = affectedObjects?.map { partialErrors[$0] }
            .compactMap { $0 }
        
        guard let ckError = errors?.first as? CKError else {
            return nil
        }
        
        return handlePartialError(ckError, operation: operation)
    }
    
    if operation == .fetchChanges {
        if let ckError = error as? CKError {
            if ckError.code == .changeTokenExpired || ckError.code == .zoneNotFound {
                return ckError
            }
        }
    }
    
    return error as? CKError
}


private func handlePartialError(_ error: CKError, operation: CloudKitOperationType) -> CKError? {
    
    if operation == .deleteZones || operation == .deleteRecords || operation == .deleteSubscriptions {
        if error.code == .unknownItem {
            return nil
        }
    }
    
    switch error.code {
    case .serverRecordChanged:
        print("Server record changed. Consider using serverRecord and ignore this error!")
    case .zoneNotFound:
        print("Zone not found. May have been deleted. Probably ignore!")
    case .unknownItem:
        print("Unknown item. May have been deleted. Probably ignore!")
    case .batchRequestFailed:
        print("Atomic failure!")
    default:
        break
    }
    
    return error
}
