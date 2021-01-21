//
//  StorageManager.swift
//  MuMu
//
//  Created by Lin Cui on 2021-01-14.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    /*
     /images/cuilin940127-gmail-com_profile_picture.png
     */
    
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    ///Upload pictures to firebase storage and return s completion with url string to download
    public func uploadProfilePicture(with data: Data,
                                     fileName: String,
                                     completion:@escaping UploadPictureCompletion){
        
        storage.child("images/\(fileName)").putData(data, metadata: nil,completion: {metadata, error in
            guard error == nil else{
                print("Failed to upload to firebase storage")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            print("images/\(fileName)")
            self.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
        
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL(completion: {url,error in
            guard let url = url, error == nil else{
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
}
