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
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
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
            userAvatarImageView.contentMode = .scaleAspectFill
            userAvatarImageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}