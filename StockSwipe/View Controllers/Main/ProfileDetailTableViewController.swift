//
//  ProfileDetailTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 7/17/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit

class ProfileDetailTableViewController: UITableViewController {
    
    var user: User?
    
    let imagePicker = CustomImagePickerController()
    
    @IBOutlet var userAvatarImageView: UIImageView!
    
    @IBOutlet var fullnameTextField: UITextField!
    
    @IBOutlet var userBioTextView: UITextView!
    
    @IBOutlet var userLocationTextField: UITextField!
    
    @IBOutlet var userWebsiteTextField: UITextField!
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // A little trick to get rid of uitableview lines
        tableView.tableFooterView = UIView()
        
        // Fill in profile info
        getProfileDetails()
        
        // Add Gesture Recognizers
        let tapGestureRecognizerMainAvatar = UITapGestureRecognizer(target: self, action: #selector(ProfileDetailTableViewController.handleGestureRecognizer))
        self.userAvatarImageView.addGestureRecognizer(tapGestureRecognizerMainAvatar)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getProfileDetails() {
        
        guard let user = user else { return }
        
        if let profileImageURL = user.userObject.object(forKey: "profile_image_url") as? String {
            
            QueryHelper.sharedInstance.queryWith(profileImageURL, completionHandler: { (result) in
                
                do {
                    
                    let imageData = try result()
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        let profileImage = UIImage(data: imageData)
                        self.userAvatarImageView.image = profileImage
                    })
                    
                } catch {
                }
            })
        }
        
        if let fullName = user.userObject.object(forKey: "full_name") as? String {
            self.fullnameTextField.text = fullName
        }
        
        if let bio = user.userObject.object(forKey: "bio") as? String {
            self.userBioTextView.text = bio
        }
        
        if let location = user.userObject["location"] as? String {
            self.userLocationTextField.text = location
        }
        
        if let website = user.userObject.object(forKey: "website") as? String {
            self.userWebsiteTextField.text = website
        }
    }
    
    func handleGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .currentContext
        
        present(imagePicker, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate Methods
extension ProfileDetailTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            userAvatarImageView.contentMode = .scaleAspectFit
            userAvatarImageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
