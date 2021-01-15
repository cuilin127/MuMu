//
//  DatabaseManager.swift
//  MuMu
//
//  Created by Lin Cui on 2021-01-12.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    
}
//Mark: - Accoount Management

extension DatabaseManager{
    
    public func userExist(with email: String, completion: @escaping ((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
        
    
    ///Insert new user to db
    public func insertUser(with user:ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue(["firstName":user.firstName,
                                                 "lastName":user.lastName], withCompletionBlock: {
                                                    error, _ in
                                                    guard error == nil else{
                                                        print("Faild to write in database")
                                                        completion(false)
                                                        return
                                                    }
                                                    completion(true)
                                                    
                                                 })
        //scale up later for more information!!
    }
}

struct ChatAppUser {
    let firstName : String
    let lastName : String
    let emailAddress : String
    
    var safeEmail:String{
        
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName : String {
        //images/cuilin940127-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
    //scale up later for more information!!
}
