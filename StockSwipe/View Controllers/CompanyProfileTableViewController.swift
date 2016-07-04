//
//  CompanyProfileTableViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2015-09-06.
//  Copyright © 2015 StockSwipe. All rights reserved.
//

import UIKit
import Charts
import SwiftyJSON

class CompanyProfileTableViewController: UITableViewController, ChartDetailDelegate, ChartViewDelegate  {
    
    var symbol: String!
    var companyName:String!
    
    var ratingsType: [String] = ["Buy", "Outperform", "Hold", "Underperform", "Sell"]
    var ratings: [Double] = [Double](count: 5, repeatedValue: 0.0)
    let ChartreuseWebColor = UIColor(red:0.50, green:1.00, blue:0.00, alpha:1.0)
    
    @IBOutlet var PELabel: UILabel!
    @IBOutlet var marketCapLabel: UILabel!
    @IBOutlet var EPSLabel: UILabel!
    
    @IBOutlet var DivYieldLabel: UILabel!
    @IBOutlet var earningsDateLabel: UILabel!
    @IBOutlet var fiftyTwoWeekRange: UILabel!
    
    @IBOutlet var overallRating: UILabel!
    @IBOutlet var meanRecommendation: UILabel!
    @IBOutlet var numberOfAnalysts: UILabel!

    @IBOutlet var oneYearPriceTarget: UILabel!
    @IBOutlet var EPSEstimate: UILabel!
    
    @IBOutlet var companySector: UILabel!
    @IBOutlet var companyIndustry: UILabel!
    @IBOutlet var companySummary: UITextView!

    var companyProfileOperationQueue: NSOperationQueue = NSOperationQueue()
    
    @IBOutlet var ratingBarChartView: BarChartView!
    
    @IBAction func xButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ratingBarChartView.delegate = self
        
        let parentTabBarController = self.tabBarController as! ChartDetailTabBarController
        symbol = parentTabBarController.symbol
        companyName = parentTabBarController.companyName
        
        // title
        if companyName != nil {
            self.navigationItem.title = companyName
        } else {
            self.navigationItem.title = symbol
        }
        
        if symbol != nil {
            runDataQueueries()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath == NSIndexPath(forRow: 0, inSection: 1) {
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                
                return 300
                
            } else {
                
                return 400
            }
            
        } else if indexPath == NSIndexPath(forRow: 1, inSection: 2) {
            
            return 150
            
        } else {
            
            return 45
        }

    }
    
    func runDataQueueries() {
        
        companyProfileOperationQueue.cancelAllOperations()
        companyProfileOperationQueue.waitUntilAllOperationsAreFinished()
        
        // Company figures query
        let companyFiguresOperation = NSBlockOperation { () -> Void in
            
            QueryHelper.sharedInstance.queryYahooSymbolQuote([self.symbol]) { (quoteData, response, error) -> Void in
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                } else if quoteData != nil {
                    
                    let quoteJsonResults = JSON(data: quoteData!)["query"]["results"]
                    let quoteJsonResultsQuote = quoteJsonResults["quote"]
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        if let PE = quoteJsonResultsQuote["PERatio"].string {
                            
                            self.PELabel.text = PE
                            
                        }
                        
                        if let MarketCapitalization = quoteJsonResultsQuote["MarketCapitalization"].string {
                            
                            self.marketCapLabel.text = MarketCapitalization
                            
                        }
                        
                        if let EarningsShare = quoteJsonResultsQuote["EarningsShare"].string {
                            
                            self.EPSLabel.text = EarningsShare
                            
                        }
                        
                        if let YearRange = quoteJsonResultsQuote["YearRange"].string {
                            
                            self.fiftyTwoWeekRange.text = YearRange
                            
                        }
                        
                        if let DividendShare = quoteJsonResultsQuote["DividendShare"].string {
                            
                            self.DivYieldLabel.text = DividendShare
                            
                            var percentYieldString:String!
                            
                            if let percentYield = quoteJsonResultsQuote["DividendYield"].string {
                                
                                percentYieldString = " (\(percentYield)%)"
                                
                                self.DivYieldLabel.text = DividendShare + percentYieldString
                                
                            }
                            
                        }
                        //            earningsDateLabel.text = newJsonResultsQuote["MarketCapitalization"].string
                        
                        //            overallRating.text = newJsonResultsQuote["MarketCapitalization"].string
                        
                        if let OneyrTargetPrice = quoteJsonResultsQuote["OneyrTargetPrice"].string {
                            
                            self.oneYearPriceTarget.text = OneyrTargetPrice
                            
                        }
                        
                        if let EPSEstimateNextYear = quoteJsonResultsQuote["EPSEstimateNextYear"].string {
                            
                            self.EPSEstimate.text = EPSEstimateNextYear
                            
                        }
                        
                        //            companySector.text = newJsonResultsQuote["MarketCapitalization"].string
                        //            companyIndustry.text = newJsonResultsQuote["MarketCapitalization"].string
                        //            companySummary.text = newJsonResultsQuote["MarketCapitalization"].string
                    })
                    
                }
            }
        }
        companyFiguresOperation.queuePriority = .VeryHigh

        // Company analysts rating query
        let companyAnalystRatings = NSBlockOperation { () -> Void in
            QueryHelper.sharedInstance.queryYahooCompanyAnalystRating(self.symbol) { (companyAnalystRatingData, response, error) -> Void in
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                } else if companyAnalystRatingData != nil {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        let companyAnalystRatingJSON = JSON(data: companyAnalystRatingData!)["query"]["results"]
                        
                        if let companyAnalystsRatingMeanRecommendation = companyAnalystRatingJSON["table"][0]["tbody"]["tr"][0]["td"][1]["content"].string {
                            
                            if let inputDoubleValue = Double(companyAnalystsRatingMeanRecommendation) {
                                
                                self.meanRecommendation.text = companyAnalystsRatingMeanRecommendation
                                
                                self.setOverallAnalystRating(inputDoubleValue)
                            }
                        }
                        
                        if let companyAnalystsRatingNumberOfAnalysts = companyAnalystRatingJSON["table"][1]["tbody"]["tr"][4]["td"][1]["content"].string {
                            
                            self.numberOfAnalysts.text = companyAnalystsRatingNumberOfAnalysts
                        }
                        
                        let companyAnalystRatingJsonBuySellHoldTable = companyAnalystRatingJSON["table"][3]["tbody"]["tr"]["td"]["table"]["tbody"]
                        
                        if let companyAnalystRatingNumberOfBuys = companyAnalystRatingJsonBuySellHoldTable["tr"][1]["td"][0]["content"].string {
                            
                            self.ratings[0] = Double(companyAnalystRatingNumberOfBuys)!
                        }
                        
                        if let companyAnalystRatingNumberOfOutperform = companyAnalystRatingJsonBuySellHoldTable["tr"][2]["td"][0]["content"].string {
                            
                            self.ratings[1] = Double(companyAnalystRatingNumberOfOutperform)!
                        }
                        
                        if let companyAnalystRatingNumberOfHolds = companyAnalystRatingJsonBuySellHoldTable["tr"][3]["td"][0]["content"].string {
                            
                            self.ratings[2] = Double(companyAnalystRatingNumberOfHolds)!
                        }
                        
                        if let companyAnalystRatingNumberOfUnderPerform = companyAnalystRatingJsonBuySellHoldTable["tr"][4]["td"][0]["content"].string {
                            
                            self.ratings[3] = Double(companyAnalystRatingNumberOfUnderPerform)!
                        }
                        
                        if let companyAnalystRatingNumberOfSells = companyAnalystRatingJsonBuySellHoldTable["tr"][5]["td"][0]["content"].string {
                            
                            self.ratings[4] = Double(companyAnalystRatingNumberOfSells)!
                        }
                        
                        self.setChart(self.ratingsType, values: self.ratings)
                        
                    })
                }
            }
        }
        companyAnalystRatings.queuePriority = .High
    
        // Company Profile Query
        let companyProfileQperation = NSBlockOperation { () -> Void in
            QueryHelper.sharedInstance.queryYahooCompanyProfile(self.symbol) { (companyProfileData, response, error) -> Void in
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                } else if companyProfileData != nil {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        let companyProfileJsonResults = JSON(data: companyProfileData!)["query"]["results"]
                        
                        //            let companyProfileGeneralInfo = companyProfileJsonResults["table"][0]["tbody"]["tr"]["td"]["table"]["tbody"]["tr"]
                        //            let companyProfileExecutiveCompensation = companyProfileJsonResults["table"][1]["tbody"]["tr"]["td"]["table"]["tbody"]["tr"]
                        
                        if let companyProfileSector = companyProfileJsonResults["table"][0]["tbody"]["tr"]["td"]["table"]["tbody"]["tr"][1]["td"][1]["a"]["content"].string {
                            
                            self.companySector.text = companyProfileSector
                        }
                        
                        if let companyProfileIndustry = companyProfileJsonResults["table"][0]["tbody"]["tr"]["td"]["table"]["tbody"]["tr"][2]["td"][1]["a"]["content"].string {
                            
                            self.companyIndustry.text = companyProfileIndustry
                        }
                    })
                }
            }
        }
        companyProfileQperation.queuePriority = .Normal
            
        // Company Summary Query
        let companySummaryOperation = NSBlockOperation { () -> Void in
            QueryHelper.sharedInstance.queryYahooCompanySummary(self.symbol) { (companySummaryData, response, error) -> Void in
                
                if error != nil {
                    
                    print("error: \(error!.localizedDescription): \(error!.userInfo)")
                    
                } else if companySummaryData != nil {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            if let companySummaryJsonResults = JSON(data: companySummaryData!)["query"]["results"]["p"][1].string {
                                
                                self.companySummary.text = companySummaryJsonResults
                                self.companySummary.flashScrollIndicators()
                            }
                        })
                    })
                }
            }
        }
        companySummaryOperation.queuePriority = .Normal
        
        companyProfileOperationQueue.addOperations([companyFiguresOperation, companyAnalystRatings, companyProfileQperation, companySummaryOperation], waitUntilFinished: false)
    }

    // MARK: Analysts Rating Bar Chart Stuff

    func setChart(dataPoints: [String], values: [Double]) {
        
        if let _ = values.find ({ $0 > 1 }) {
            
            var dataEntries = [BarChartDataEntry]()
            
            for i in 0..<dataPoints.count {
                let dataEntry = BarChartDataEntry(value: values[i], xIndex: i)
                dataEntries.append(dataEntry)
            }
            
            let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "Analysts Rating")
            chartDataSet.colors = [UIColor.greenColor(), ChartreuseWebColor, UIColor.yellowColor(), UIColor.orangeColor() , UIColor.redColor()]
            chartDataSet.valueFont = UIFont(name: "HelveticaNeue", size: 15.0)!
            chartDataSet.valueTextColor = Constants.stockSwipeFontColor
            
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = .NoStyle
            chartDataSet.valueFormatter = numberFormatter
            
            //        ratingBarChartView.noDataText = "Loading Analysts Data"
            //        ratingBarChartView.infoFont = UIFont(name: "HelveticaNeue", size: 20.0)!
            //        ratingBarChartView.infoTextColor = Constants.stockSwipeFontColor
            ratingBarChartView.descriptionText = ""
            ratingBarChartView.xAxis.labelPosition = .Bottom
            ratingBarChartView.xAxis.drawGridLinesEnabled = false
            ratingBarChartView.xAxis.labelFont = UIFont(name: "HelveticaNeue", size: 11.0)!
            ratingBarChartView.xAxis.labelTextColor = Constants.stockSwipeFontColor
            ratingBarChartView.leftAxis.enabled = false
            ratingBarChartView.leftAxis.drawGridLinesEnabled = false
            ratingBarChartView.leftAxis.axisMinValue = 0.0
            ratingBarChartView.rightAxis.enabled = false
            ratingBarChartView.rightAxis.drawGridLinesEnabled = false
            ratingBarChartView.drawBordersEnabled = false
            ratingBarChartView.drawGridBackgroundEnabled = false
            ratingBarChartView.legend.enabled = false
            ratingBarChartView.userInteractionEnabled = false
            
            let chartData = BarChartData(xVals: ratingsType, dataSet: chartDataSet)
            ratingBarChartView.data = chartData
            
            ratingBarChartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5)
        } else {
            ratingBarChartView.hidden = true
        }
    }
    
    func setOverallAnalystRating(input: Double) {
        
        switch input {
            
        case input where input >= 1.0 && input <= 1.5:
            
            overallRating.text = "Buy"
            overallRating.textColor = UIColor.greenColor()
            
        case input where input > 1.5 && input <= 2.5:
            
            overallRating.text = "Outperform"
            overallRating.textColor = ChartreuseWebColor
            
        case input where input > 2.5 && input <= 3.5:
            
            overallRating.text = "Hold"
            overallRating.textColor = UIColor.yellowColor()
            
        case input where input > 3.5 && input <= 4.5:
            
            overallRating.text = "Underperform"
            overallRating.textColor = UIColor.orangeColor()
            
        case input where input > 4.5 && input <= 5.0:
            
            overallRating.text = "Sell"
            overallRating.textColor = UIColor.redColor()
            
        default:
            
            break
            
        }
    }
}
