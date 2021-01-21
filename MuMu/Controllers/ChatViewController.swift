//
//  ChatViewController.swift
//  MuMu
//
//  Created by Lin Cui on 2021-01-14.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
}
extension MessageKind {
    var messageKingString: String{
        switch self {
        
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}
struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}
class ChatViewController: MessagesViewController {
    
    public let otherUserEmail: String
    public var isNewConversation = false
    private let conversationId: String?
    
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "", senderId: safeEmail , displayName: "Me")
    }
    
    
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id

        super.init(nibName:  nil, bundle: nil)
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBotton: true)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
       
        
    }
    private func listenForMessages(id: String,shouldScrollToBotton: Bool){
        print("start listening for: \(id)")
        
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: {
            [weak self]result in
            switch result{
            
            case .success(let messages):
                print("messages got")
                guard !messages.isEmpty else{
                    return
                }
                
                self?.messages = messages
                
                DispatchQueue.main.async {
                   
                    print("updating UI with messages")
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBotton{
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
                
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageid = createMessageId()
        else{
            return
        }
        
        print("Sending: \(text)")
        //Send message
        let message = Message(sender: selfSender,
                              messageId: messageid, // a unique identifier
                              sentDate: Date(),
                              kind: .text(text))
        if isNewConversation {
            //create conversation in DB
            
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: {[weak self]success in
                if success{
                    print("message sent")
                    self?.isNewConversation = false
                }
                else{
                    print("faild to sent")
                    
                }
            })
            
        }else{
            //append to existing conversation
            guard let conversationId = conversationId,
                  let name = self.title
                  else{
                return
            }
            DatabaseManager.shared.sendMessageToConversation(to: conversationId,otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: {success in
                if success{
                    print("Message sent")
                }else{
                    print("failed to send")
                }
                
            })
        }
    }
    
    private func createMessageId() -> String?{
        //date, otherEmail, senderEmail, random Int
        
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String
        else{
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("Created message id: \(newIdentifier)")
        return newIdentifier
        
    }
    
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        
        return messages.count
    }
    
    
}
