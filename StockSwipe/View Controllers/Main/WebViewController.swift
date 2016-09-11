//
//  TopStoriesWebViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-07-09.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import WebKit
import Parse
import Crashlytics

class WebViewController: UIViewController {
    
    var url: URL!
    var webView: WKWebView!
    var customAlert = SweetAlert()
    
    @IBOutlet var webViewProgressBar: UIProgressView!
    @IBOutlet var urlField: UITextField!
    
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!
    @IBOutlet var safariButton: UIBarButtonItem!
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareButtonPressed(_ sender: AnyObject) {
        
        Functions.presentActivityVC(nil, imageToShare: nil, url: self.url, sender: self.shareButton, vc: self) { (activity, success, items, error) -> Void in
            
            if success {
                
                SweetAlert().showAlert("Success!", subTitle: nil, style: AlertStyle.success)
                
                // log shared successfully
                Answers.logShare(withMethod: "\(activity!)",
                    contentName: "\(self.url.path) shared",
                    contentType: "Share",
                    contentId: nil,
                    customAttributes: ["User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
                
                //"Installation ID":PFInstallation.currentInstallation()!.installationId,
                
            } else if error != nil {
                
                SweetAlert().showAlert("Error!", subTitle: "Something went wrong", style: AlertStyle.error)
            }
            
        }
    }
    
    @IBAction func safariButtonPressed(_ sender: AnyObject) {
        
        UIApplication.shared.openURL(self.url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView = WKWebView()
        webView.frame = self.view.frame
        self.view.insertSubview(webView, belowSubview: webViewProgressBar)
        
        self.webView.navigationDelegate = self
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        if url != nil {
            self.urlField.text = String(self.url.host!)
            let urlrequest: URLRequest = URLRequest(url: self.url)
            self.webView.load(urlrequest)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == "loading") {
//            backButton.enabled = webView.canGoBack
//            forwardButton.enabled = webView.canGoForward
        }
        
        if (keyPath == "estimatedProgress") {
            webViewProgressBar.isHidden = webView.estimatedProgress == 1
            webViewProgressBar.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }
    
    deinit {
        
        if webView.isLoading {
            
            webView.stopLoading()
        }
        
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webView.navigationDelegate = nil
        self.webView = nil
    }
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        print("error: \(error.localizedDescription): \(error.userInfo)")
        
        SweetAlert().showAlert("Something went wrong while loading", subTitle: "Please try again", style: AlertStyle.warning)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webViewProgressBar.setProgress(0.0, animated: false)
    }
}
