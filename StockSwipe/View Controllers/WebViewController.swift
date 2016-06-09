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
    
    var url: NSURL!
    var webView: WKWebView!
    var customAlert = SweetAlert()
    
    @IBOutlet var webViewProgressBar: UIProgressView!
    @IBOutlet var urlField: UITextField!
    
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var shareButton: UIBarButtonItem!
    @IBOutlet var safariButton: UIBarButtonItem!
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func shareButtonPressed(sender: AnyObject) {
        
        Functions.presentActivityVC(nil, imageToShare: nil, url: self.url, sender: self.shareButton, vc: self) { (activity, success, items, error) -> Void in
            
            if success {
                
                SweetAlert().showAlert("Success!", subTitle: nil, style: AlertStyle.Success)
                
                // log shared successfully
                Answers.logShareWithMethod("\(activity!)",
                    contentName: "\(self.url.path) shared",
                    contentType: "top stories share",
                    contentId: nil,
                    customAttributes: ["Installation ID":PFInstallation.currentInstallation().installationId, "App Version": Constants.AppVersion])
                
            } else if error != nil {
                
                SweetAlert().showAlert("Error!", subTitle: "Something went wrong", style: AlertStyle.Error)
            }
            
        }
    }
    
    @IBAction func safariButtonPressed(sender: AnyObject) {
        
        UIApplication.sharedApplication().openURL(self.url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView = WKWebView()
        webView.frame = self.view.frame
        self.view.insertSubview(webView, belowSubview: webViewProgressBar)
        
        self.webView.navigationDelegate = self
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        
        if url != nil {
            self.urlField.text = String(self.url.host!)
            let urlrequest: NSURLRequest = NSURLRequest(URL: self.url)
            self.webView.loadRequest(urlrequest)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if (keyPath == "loading") {
//            backButton.enabled = webView.canGoBack
//            forwardButton.enabled = webView.canGoForward
        }
        
        if (keyPath == "estimatedProgress") {
            webViewProgressBar.hidden = webView.estimatedProgress == 1
            webViewProgressBar.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }
    
    deinit {
        
        if webView.loading {
            
            webView.stopLoading()
        }
        
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webView.navigationDelegate = nil
        self.webView = nil
    }
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        
        print("error: \(error.localizedDescription): \(error.userInfo)")
        
        SweetAlert().showAlert("Something went wrong while loading", subTitle: "Please try again", style: AlertStyle.Warning)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        
        webViewProgressBar.setProgress(0.0, animated: false)
    }
}