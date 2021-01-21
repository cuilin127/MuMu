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
    
    //    private
    let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
    
}
//Mark: - Accoount Management
extension
DatabaseManager{
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void){
        self.database.child(path).observeSingleEvent(of: .value, with: {
            snapshot in
            guard let value = snapshot.value else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
}
extension DatabaseManager{
    
    public func test1(){
        database.child("lin-cui127-gmail-com").observeSingleEvent(of: .value, with: {result in
            
            print("hahahaahahahahaahahahah\(result)")
        })
    }
    
    public func userExist(with email: String, completion: @escaping ((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        print("\(safeEmail)")
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in          //Error happend here!!!!!!!!!!!!!!!
            print("safeEmail is \(safeEmail)")
            
            // print("the user got is \(snapshot.value as? String)")
            
            guard snapshot.value as? [String: Any] != nil else{
                print(("This is a new user, insert it!"))
                completion(false)
                return
            }
            print("This user already exist, just do log in")
            completion(true)
            
        })
        
    }
    
    
    ///Insert new user to db
    public func insertUser(with user:ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue(["firstName":user.firstName, "lastName":user.lastName], withCompletionBlock: {
            error, _ in
            guard error == nil else{
                print("Faild to write in database")
                completion(false)
                return
            }
            print("start insert  new user....")
            
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // users exist, just append to user dictionary
                    print("users exist, just append to user dictionary")
                    let newElement = ["name": user.firstName + user.lastName,
                                      "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: {
                        error,_ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else{
                    //users not exist, creating that array, only happend when the first user come to use this app
                    
                    print("users not exist, creating that array, only happend when the first user come to use this app")
                    let newCollection:[[String: String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: {
                        error,_ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                
                
            })
            
            
        })
        //scale up later for more information!!
    }
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        
        database.child("users").observeSingleEvent(of:  .value, with: {snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
            
        })
        
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

/*
 users => [
 [
 "name":
 "safeEmail":
 
 ],
 [
 "name":
 "safeEmail":
 ],
 
 ]
 
 
 */

// MARK: - Sending messages / Conversations
extension DatabaseManager{
    ///Create a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String,name: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let reference = database.child("\(safeEmail)")
        reference.observeSingleEvent(of: .value, with: {[weak self]
            snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch firstMessage.kind {
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message":[
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message":[
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            
            //Update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self]snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //apppend
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationId)
                } else{
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            //update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exist for current user
                // should append
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                reference.setValue(userNode,withCompletionBlock: { [weak self]error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreateConversation(name: name,
                                                   conversationId: conversationId,
                                                   firstMessage: firstMessage,
                                                   completion: completion)
                    completion(true)
                    
                })
            } else{
                //conversation array does not exit
                //create it
                userNode["conversations"] = [
                    newConversationData
                ]
                reference.setValue(userNode,withCompletionBlock: { [weak self]error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreateConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                    completion(true)
                    
                })
            }
            
        })
    }
    private func finishCreateConversation(name: String,conversationId: String, firstMessage: Message, completion: @escaping(Bool) -> Void){
        
        
        //        {
        //        "id": String,
        //        "type": text,
        //        "content": String,
        //        "date": Date(),
        //        "sender_email": String,
        //        "isRead": true/false
        //        }
        var message = ""
        switch firstMessage.kind {
        
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let collectionMessage: [String: Any] = [ "id": firstMessage.messageId,
                                                 "type": firstMessage.kind.messageKingString,
                                                 "content": message,
                                                 "date": dateString,
                                                 "sender_email": currentUserEmail,
                                                 "is_read": false,
                                                 "name": name
        ]
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding conversation: \(conversationId)")
        database.child("\(conversationId)").setValue(value, withCompletionBlock: {error,_ in
            guard error == nil else{
                completion(false)
                return
            }
            
        })
        
    }
    
    ///Fetching and return all conversation for the user with passed email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                let latestMessageObjct = LatestMessage(date: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObjct)
            })
            
            completion(.success(conversations))
        })
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let id = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from:dateString),
                      let type = dictionary["type"] as? String
                      else{
                    return nil
                }
               let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: id, sentDate: date, kind: .text(content))
                                
            })
            
            completion(.success(messages))
        })
    }
    
    ///Sends a message with target conversation and message
    public func sendMessageToConversation(to conversation: String,otherUserEmail: String, name:String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        //add new message to messages
        //update sender latest message
        // update recipient latest meassage
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: {[weak self] snapshot in
            
            guard let strongSelf = self else{
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else{
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch newMessage.kind {
            
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String: Any] = [ "id": newMessage.messageId,
                                                     "type": newMessage.kind.messageKingString,
                                                     "content": message,
                                                     "date": dateString,
                                                     "sender_email": currentUserEmail,
                                                     "is_read": false,
                                                     "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages, withCompletionBlock: {
                error,_ in
                guard error == nil else {
                    completion(false)
                    return
                }
                strongSelf.database.child("\(currentUserEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else{
                        completion(false)
                        return
                    }
                    let updatedValue: [String: Any] = [
                         "date":dateString,
                         "is_read": false,
                         "message":message
                    ]
                    var targetConversation : [String: Any]?
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations{
                        if let currentId = conversationDictionary["id"] as? String,
                           currentId == conversation                           {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                           
                    }
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else{
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalConversation
                    print("current user is: \(finalConversation)")
                    strongSelf.database.child("\(currentUserEmail)/conversations").setValue(currentUserConversations, withCompletionBlock: {error,_ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        //update latest for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else{
                                completion(false)
                                return
                            }
                            let updatedValue: [String: Any] = [
                                 "date":dateString,
                                 "is_read": false,
                                 "message":message
                            ]
                            var targetConversation : [String: Any]?
                            var position = 0
                            
                            for otherDictionary in otherUserConversations{
                                if let currentId = otherDictionary["id"] as? String,
                                   currentId == conversation                           {
                                    targetConversation = otherDictionary
                                    break
                                }
                                position += 1
                                   
                            }
                            targetConversation?["latest_message"] = updatedValue
                            guard let finalConversation = targetConversation else{
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = finalConversation
                            print("other user is: \(finalConversation)")
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations, withCompletionBlock: {error,_ in
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                    })
                })
                
            })
            
        })
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
