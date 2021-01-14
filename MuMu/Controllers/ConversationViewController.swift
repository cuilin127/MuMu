//
//  ConversationViewController.swift
//  MuMu
//
//  Created by Lin Cui on 2021-01-11.
//

import UIKit
import FirebaseAuth

class ConversationViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
        
    }
    
    private func validateAuth(){
        
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController:vc) // to make sure user can't go anywhere without login
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated: false)
        }
        
    }

}
