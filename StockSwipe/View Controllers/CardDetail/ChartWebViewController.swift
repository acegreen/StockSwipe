//
//  WebViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-07-09.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore
import Parse
import Crashlytics
import SDVersion
import SwiftyJSON

class ChartWebViewController: UIViewController, ChartDetailDelegate {
    
    var symbol: String!
    var companyName: String!
    var card: Card!
    
    var webView: WKWebView!
    var jsContext: JSContext!
    
    var customAlert = SweetAlert()
    
    @IBOutlet var actionButton: UIBarButtonItem!
    
    //    @IBOutlet var tradeItButton: UIBarButtonItem!
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //    @IBAction func tradeButtonPressed(sender: AnyObject) {
    //
    //        #if DEBUG
    //
    //            TradeItTicketController.showTicketWithApiKey(Constants.APIKeys.TradeItDev.key(), symbol: self.symbol, orderAction: nil, orderQuantity: nil, viewController: self, withDebug: true, onCompletion: { (TradeItTicketControllerResult) -> Void in
    //
    //            })
    //
    //        #else
    //
    //            TradeItTicketController.showTicketWithApiKey(Constants.APIKeys.TradeItProd.key(), symbol: self.symbol, orderAction: nil, orderQuantity: nil, viewController: self, withDebug: false, onCompletion: { (TradeItTicketControllerResult) -> Void in
    //
    //            })
    //
    //        #endif
    //    }
    
    @IBAction func addToWatchlistAction(_ sender: UIBarButtonItem) {
        Functions.promptAddToWatchlist(card, registerChoice: true) { (choice) in
        }
    }
    
    @IBAction func actionButtonPressed(_ sender: AnyObject) {
        
        let textToShare = "Discovered $" + symbol + " #StockSwipe" + "stockswipe://card?symbol=\(symbol)"
        
        customAlert.showAlert("Hold On!", subTitle: "While we prepare the snapshot", style: AlertStyle.activityIndicator, dismissTime: nil)
        
        DispatchQueue.main.async {
            
            self.customAlert.closeAlertDismissButton()
            
            let view = SwipeCardView(frame: CGRect(x: self.view.bounds.midX - (cardWidth / 2), y: self.view.bounds.midY - (cardHeight / 2), width: cardWidth, height: cardHeight), card: self.card, options: nil)
            let chartImage = UIImage(view: view)
            
            Functions.presentActivityVC(textToShare, imageToShare: chartImage, url: Constants.appLinkURL!, sender: self.actionButton, vc: self, completion: { (activity, success, items, error) -> Void in
                
                if success {
                    
                    SweetAlert().showAlert("Success!", subTitle: nil, style: AlertStyle.success)
                    
                    // log shared successfully
                    Answers.logShare(withMethod: "\(activity!)",
                        contentName: self.symbol + " Card Shared",
                        contentType: "Share",
                        contentId: nil,
                        customAttributes: ["User": PFUser.current()?.username ?? "N/A", "App Version": Constants.AppVersion])
                    
                } else if error != nil {
                    SweetAlert().showAlert("Error!", subTitle: "Something went wrong", style: AlertStyle.error)
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parentTabBarController = self.tabBarController as! CardDetailTabBarController
        symbol = parentTabBarController.symbol
        companyName = parentTabBarController.companyName
        card = parentTabBarController.card
        
        self.webView = WKWebView()
        self.view = self.webView!
        self.webView.navigationDelegate = self
        self.webView.scrollView.bounces = false
        self.webView.scrollView.isScrollEnabled = false
        
        // title
        if companyName != nil {
            self.navigationItem.title = companyName
        } else {
            self.navigationItem.title = symbol
        }
        
        guard symbol != nil else { return }
        let urlString: URL = Functions.setChartURL(symbol)
        let urlrequest: URLRequest = URLRequest(url: urlString)
        self.webView.load(urlrequest)
        
    }
    
    deinit {
        
        guard webView != nil else { return }
        
        if webView.isLoading {
            webView.stopLoading()
        }
        
        self.webView.navigationDelegate = nil
        self.webView = nil
    }
}

extension ChartWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        actionButton.isEnabled = false
        //        tradeItButton.enabled = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        actionButton.isEnabled = true
        //        tradeItButton.enabled = true
        
        Functions.showPopTip(popTipText: NSLocalizedString("Share", comment: ""),
                             inView: self.navigationController!.view,
                             fromFrame: CGRect(x: view.frame.width - 30, y: 50, width: 1, height: 1), direction: .down, color: Constants.SSColors.green, duration: 2)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        actionButton.isEnabled = false
        //        tradeItButton.enabled = false
        
        print("error:", error.localizedDescription)
        
        SweetAlert().showAlert("Something went wrong while loading card", subTitle: "Please try again", style: AlertStyle.warning)
    }
}
