//
//  ProfileDetailTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 7/17/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse

protocol ProfileDetailTableViewControllerDelegate {
    func userProfileChanged(newUser: User)
}

class ProfileDetailTableViewController: UITableViewController {
    
    var delegate: ProfileDetailTableViewControllerDelegate?
    
    var user: User?
    
    let imagePicker = CustomImagePickerController()
    
    private var userProfilePictureChanged: Bool = false
    
    @IBOutlet var userAvatarImageView: UIImageView!
    
    @IBOutlet var fullnameTextField: UITextField!
    
    @IBOutlet var userBioTextView: UITextView!
    
    @IBOutlet var userLocationTextField: UITextField!
    
    @IBOutlet var userWebsiteTextField: UITextField!
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        guard let currentUser = PFUser.current() else { return }
        let tempUser = currentUser
        
        if self.userProfilePictureChanged {
            let imageData = self.userAvatarImageView.image!.pngData()
            let parseImageFile = PFFileObject(name: "profile_image.png", data: imageData!)
            
            parseImageFile?.saveInBackground(block: { (success, error) -> Void in
                if success {
                    currentUser["profile_image"] = parseImageFile
                    currentUser["full_name"] = self.fullnameTextField.text
                    currentUser["fullname_lowercase"] = self.fullnameTextField.text?.lowercased()
                    currentUser["bio"] = self.userBioTextView.text
                    currentUser["location"] = self.userLocationTextField.text
                    currentUser["website"] = self.userWebsiteTextField.text
                    currentUser.saveEventually { (success, error) in
                        if self.didUserProfileChange(previousUser: tempUser, newUser: currentUser) {
                            self.delegate?.userProfileChanged(newUser: User(userObject: currentUser))
                        }
                    }
                } else {
                    // TODO: show alert with error
                }
            })
        } else {
            currentUser["full_name"] = self.fullnameTextField.text
            currentUser["fullname_lowercase"] = self.fullnameTextField.text?.lowercased()
            currentUser["bio"] = self.userBioTextView.text
            currentUser["location"] = self.userLocationTextField.text
            currentUser["website"] = self.userWebsiteTextField.text
            currentUser.saveEventually({ (success, error) in
                if self.didUserProfileChange(previousUser: tempUser, newUser: currentUser) {
                    self.delegate?.userProfileChanged(newUser: User(userObject: currentUser))
                }
            })
        }
        
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
    
    private func didUserProfileChange(previousUser: PFUser, newUser: PFUser) -> Bool {
        return previousUser == newUser
    }
    
    private func getProfileDetails() {
        
        guard let user = user else { return }
        user.getAvatar { (profileImage) in
            DispatchQueue.main.async {
                self.userAvatarImageView.image = profileImage
            }
        }
        self.fullnameTextField.text = user.fullname
        self.userBioTextView.text = user.bio
        self.userLocationTextField.text = user.location
        self.userWebsiteTextField.text = user.website

    }
    
    @objc func handleGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .currentContext
        
        present(imagePicker, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate Methods
extension ProfileDetailTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            userAvatarImageView.image = pickedImage
            self.userProfilePictureChanged = true
            
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
