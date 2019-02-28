//
//  ProfileDetailTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 7/17/16.
//  Copyright © 2016 StockSwipe. All rights reserved.
//

import UIKit
import Parse
import DataCache

protocol ProfileDetailTableViewControllerDelegate {
    func userProfileChanged()
}

class ProfileDetailTableViewController: UITableViewController {
    
    var delegate: ProfileDetailTableViewControllerDelegate?
    
    var user: User!
    
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
        
        guard self.user == PFUser.current() else {
            Functions.showNotificationBanner(title: "User not logged in", subtitle: "Only the logged in user info can be changed", style: .warning)
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        if self.userProfilePictureChanged {
            guard let imageData = self.userAvatarImageView.image?.pngData() else { return }
            let parseImageFile = PFFileObject(data: imageData, contentType: "image/png")
            parseImageFile.saveInBackground(block: { (success, error) in
                if success {
                    if let objectId = self.user.objectId, let userAvatarImage = self.userAvatarImageView.image {
                        DataCache.instance.write(image: userAvatarImage, forKey: Constants.CacheKey.UserAvatar(objectId: objectId).key())
                    }
                    self.user["profile_image"] = parseImageFile
                    self.user["full_name"] = self.fullnameTextField.text
                    self.user["fullname_lowercase"] = self.fullnameTextField.text?.lowercased()
                    self.user["bio"] = self.userBioTextView.text
                    self.user["location"] = self.userLocationTextField.text
                    self.user["website"] = self.userWebsiteTextField.text
                    self.user.saveEventually { (success, error) in
                        self.delegate?.userProfileChanged()
                    }
                } else {
                    // TODO: show alert with error
                }
            })
        } else {
            self.user["full_name"] = self.fullnameTextField.text
            self.user["fullname_lowercase"] = self.fullnameTextField.text?.lowercased()
            self.user["bio"] = self.userBioTextView.text
            self.user["location"] = self.userLocationTextField.text
            self.user["website"] = self.userWebsiteTextField.text
            self.user.saveEventually({ (success, error) in
                self.delegate?.userProfileChanged()
            })
        }
        
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // A little trick to get rid of uitableview lines
        tableView.tableFooterView = UIView()
        userBioTextView.textContainerInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        
        // Fill in profile info
        getProfileDetails()
        
        // Add Gesture Recognizers
        let tapGestureRecognizerMainAvatar = UITapGestureRecognizer(target: self, action: #selector(ProfileDetailTableViewController.handleGestureRecognizer))
        self.userAvatarImageView.addGestureRecognizer(tapGestureRecognizerMainAvatar)
    }
    
    private func getProfileDetails() {
        self.userAvatarImageView.image = self.user.avatar
        self.fullnameTextField.text = self.user?.full_name
        self.userBioTextView.text = self.user?.bio
        self.userLocationTextField.text = self.user?.location
        self.userWebsiteTextField.text = self.user?.website
    }
    
    @objc func handleGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .currentContext
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate Methods
extension ProfileDetailTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            userAvatarImageView.image = pickedImage
            self.userProfilePictureChanged = true
            
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
