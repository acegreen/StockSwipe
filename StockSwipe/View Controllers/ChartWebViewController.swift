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
    var chart: Chart!
    
    var webView: WKWebView!
    var jsContext: JSContext!
    
    var customAlert = SweetAlert()
    
    @IBOutlet var actionButton: UIBarButtonItem!
    
    //    @IBOutlet var tradeItButton: UIBarButtonItem!
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
    
    @IBAction func actionButtonPressed(sender: AnyObject) {
        
        let textToShare = "Discovered $\(self.symbol) #StockSwipe"
        
        customAlert.showAlert("Hold On!", subTitle: "While we prepare the snapshot", style: AlertStyle.ActivityIndicator, dismissTime: nil)
        
        QueryHelper.sharedInstance.queryChartImage(symbol, completion: { (result) in
            
            do {
                
                let chartImageResult = try result()
                self.chart.image = chartImageResult
                
                let view = SwipeChartView(frame: CGRectMake(0, 0, self.chart.image.size.width, self.chart.image.size.height + Constants.informationViewHeight + Constants.chartImageTopPadding), chart: self.chart, options: nil)
                
                let chartImage = UIImage(view: view)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                    self.customAlert.closeAlertDismissButton()
                    
                    Functions.presentActivityVC(textToShare, imageToShare: chartImage, url: Constants.appLinkURL!, sender: self.actionButton, vc: self, completion: { (activity, success, items, error) -> Void in
                        
                        if success {
                            
                            SweetAlert().showAlert("Success!", subTitle: nil, style: AlertStyle.Success)
                            
                            // log shared successfully
                            Answers.logShareWithMethod("\(activity!)",
                                contentName: "\(self.symbol) chart shared",
                                contentType: "chart share",
                                contentId: nil,
                                customAttributes: ["App Version": Constants.AppVersion])
                            
                        } else if error != nil {
                            
                            SweetAlert().showAlert("Error!", subTitle: "Something went wrong", style: AlertStyle.Error)
                        }
                    })
                })
                
            } catch {
                
                if let error = error as? Constants.Errors {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                        self.customAlert.closeAlertDismissButton()
                        
                        SweetAlert().showAlert("Something Went Wrong!", subTitle: error.message(), style: AlertStyle.Warning)
                    })
                }
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let parentTabBarController = self.tabBarController as! ChartDetailTabBarController
        symbol = parentTabBarController.symbol
        companyName = parentTabBarController.companyName
        chart = parentTabBarController.chart
        
        self.webView = WKWebView()
        self.view = self.webView!
        self.webView.navigationDelegate = self
        self.webView.scrollView.bounces = false
        self.webView.scrollView.scrollEnabled = false
        
        // title
        if companyName != nil {
            self.navigationItem.title = companyName
        } else {
            self.navigationItem.title = symbol
        }
        
        guard symbol != nil else { return }
        
        let urlString: NSURL = Functions.setChartURL(symbol)
        
        let urlrequest: NSURLRequest = NSURLRequest(URL: urlString)
        
        self.webView.loadRequest(urlrequest)
        
    }
    
    deinit {
        
        guard webView != nil else { return }
        
        if webView.loading {
            
            webView.stopLoading()
        }
        
        self.webView.navigationDelegate = nil
        self.webView = nil
    }
}

extension ChartWebViewController: WKNavigationDelegate {
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        actionButton.enabled = false
        //        tradeItButton.enabled = false
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        
        actionButton.enabled = true
        //        tradeItButton.enabled = true
        
        Functions.showPopTip(popTipText: NSLocalizedString("Share this trade idea", comment: ""),
                             inView: view,
                             fromFrame: CGRect(x: view.frame.width - 30, y: -10, width: 1, height: 1), direction: .Down, color: Constants.stockSwipeGreenColor)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        
        actionButton.enabled = false
        //        tradeItButton.enabled = false
        
        print("error: \(error.localizedDescription): \(error.userInfo)")
        
        SweetAlert().showAlert("Something went wrong while loading chart", subTitle: "Please try again", style: AlertStyle.Warning)
    }
}
