//
//  ViewController.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/8/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import UIKit
import SafariServices
import AVFoundation
import Alamofire

class ViewController: UIViewController, UITextFieldDelegate {
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var loginUrl: URL?
    var User: SPTUser!

    @IBOutlet weak var spotifyBtn: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var createAccountBtn: UIButton!
    
    @IBOutlet weak var undoBtn: UIButton!
    
    @IBOutlet weak var loginBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.setBottomBorder()
        passwordTextField.setBottomBorder()
        loginBtn.layer.cornerRadius = 15
        signUpBtn.layer.cornerRadius = 15
        createAccountBtn.layer.cornerRadius = 15
        nameField.setBottomBorder()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
    }
    

    @objc func updateAfterFirstLogin () {
        if let sessionObj:AnyObject = UserDefaults.standard.value(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            let uvc = self.storyboard?.instantiateViewController(withIdentifier: "UserVC") as? UserVC
            self.present(uvc!, animated: true, completion: nil)
          }
    }
    
    
    @IBAction func loginBtnPressed(_ sender: Any) {
        if UIApplication.shared.openURL(loginUrl!) {
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }     
    }
    
    var firstClick = false
    @IBAction func createAccount(_ sender: Any) {
        undoBtn.isHidden = false
        if firstClick == false {
            nameField.isHidden = false
            signUpBtn.isHidden = true
            firstClick = true
            createAccountBtn.setTitle("Register", for: .normal)
        } else {
            if (emailTextField.text?.isEmpty)! && (passwordTextField.text?.isEmpty)! && (nameField.text?.isEmpty)! {
            } else {
                AuthService.instance.registerUser(name: nameField.text!, email: emailTextField.text!, password: passwordTextField.text!, userCreationComplete: { (registered, error) in
                    if registered {
                        AuthService.instance.loginUser(email: self.emailTextField.text!, password: self.passwordTextField.text!, loginComplete: { (loggedIn, error) in
                            if loggedIn {
                                self.spotifyBtn.isHidden = false
                                self.signUpBtn.isHidden = true
                                self.emailTextField.isHidden = true
                                self.passwordTextField.isHidden = true
                                self.createAccountBtn.isHidden = true
                                self.nameField.isHidden = true
                                self.undoBtn.isHidden = true
                            }
                        })
                    } else {
                        print(error?.localizedDescription ?? "")
                    }
                })
            }
        }
        
        
    }
    @IBAction func undoClicked(_ sender: Any) {
        firstClick = false
        nameField.isHidden = true
        signUpBtn.isHidden = false
        createAccountBtn.setTitle("Create Account", for: .normal)
        nameField.text = ""
        emailTextField.text = ""
        passwordTextField.text = ""
        undoBtn.isHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        
    }
    
    @IBAction func signUpClicked(_ sender: Any) {
        self.resignFirstResponder()
        if (emailTextField.text?.isEmpty)! && (passwordTextField.text?.isEmpty)! {
            print("please enter email/password")
        } else {
            AuthService.instance.loginUser(email: emailTextField.text!, password: passwordTextField.text!, loginComplete: { (LoggedIn, error) in
                if LoggedIn {
                    self.spotifyBtn.isHidden = false
                    self.signUpBtn.isHidden = true
                    self.emailTextField.isHidden = true
                    self.passwordTextField.isHidden = true
                    self.createAccountBtn.isHidden = true
                } else {
                }
            })
        }
    }
    
    func getRecentlyPlayed() {
        let url = "https://api.spotify.com/v1/me/player/recently-played"
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": "Bearer " + session.accessToken!]).responseJSON { (response) in
            guard let json = response.result.value as? [String: Any] else {return}
            print(json)
        }
        

    }
    
    
    func setup() {
        SPTAuth.defaultInstance().clientID = "your client id"
        SPTAuth.defaultInstance().redirectURL = URL(string:"GroupMusic://returnAfterLogin")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthUserReadTopScope,SPTAuthUserLibraryReadScope,"user-read-recently-played",SPTAuthUserReadPrivateScope, SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope,SPTAuthPlaylistModifyPublicScope,SPTAuthPlaylistModifyPrivateScope]
        loginUrl = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        
        
    }
}


extension UITextField {
    func setBottomBorder(){
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = #colorLiteral(red: 0.9568627451, green: 0.4431372549, blue: 0.2588235294, alpha: 1)
        border.frame = CGRect(x: 0, y: self.frame.size.height - width,   width:  self.frame.size.width, height: self.frame.size.height)
        border.borderWidth = width
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}

