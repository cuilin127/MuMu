//
//  AppDelegate.swift
//  MuMu
//
//  Created by Lin Cui on 2021-01-11.
//
import UIKit
import FBSDKCoreKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,GIDSignInDelegate {
    
    
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        FirebaseApp.configure()
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance().handle(url)
        
    }
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else{
            if let error = error{
                print("Faild to gifn in with google: \(error)")
            }
            return
        }
        guard let email = user.profile.email,
              let firstName = user.profile.givenName,
              let lastName = user.profile.familyName
        else{
            return
        }
        
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        guard let user = user else{
            return
        }
        
        print("Did sign in with google: \(user)")
        
        
        DatabaseManager.shared.userExist(with: email, completion: {exists in
            if !exists {
                // insert into DB
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                    if success{
                        //upload image
                        if user.profile.hasImage{
                            guard let url = user.profile.imageURL(withDimension: 200) else{
                                return
                            }
                            
                            URLSession.shared.dataTask(with:url,completionHandler: {data,_,_ in
                                guard let data = data else{
                                    print("faild to get image data from google image")
                                    return
                                }
                                print("got data from google image, uploading")
                                
                                //upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result{
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    }
                })
            }
        })
        
        guard let authentication = user.authentication else {
            print("Missing auth object off of google user")
            return
            
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential, completion: {authResult, error in
            guard authResult != nil, error == nil else{
                print("faild to log in with google credential")
                return
            }
            
            print("successfully signed in with google cred")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            
        })
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        print("Google user was didconnected")
    }
    
}
