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
    var ratings: [Double] = [Double](repeating: 0.0, count: 5)
    let outperformGreen = UIColor(red: 25/255, green: 225/255, blue: 25/255, alpha: 1.0)
    
    @IBOutlet var PELabel: UILabel!
    @IBOutlet var marketCapLabel: UILabel!
    @IBOutlet var EPSLabel: UILabel!
    @IBOutlet var bookValueLabel: UILabel!
    @IBOutlet var divYieldLabel: UILabel!
    @IBOutlet var earningsDateLabel: UILabel!
    @IBOutlet var EBITDALabel: UILabel!
    @IBOutlet var wallstreetTargetLabel: UILabel!
    
    @IBOutlet var fiftyTwoWeekRange: UILabel!
    @IBOutlet var fiftyMALabel: UILabel!
    @IBOutlet var twoHundredMALabel: UILabel!
    @IBOutlet var betaLabel: UILabel!
    @IBOutlet var shortRatioLabel: UILabel!
    
    @IBOutlet var sectorLabel: UILabel!
    @IBOutlet var industryLabel: UILabel!
    @IBOutlet var fulltimeEmployeesLabel: UILabel!
    @IBOutlet var exchangeLabel: UILabel!
    @IBOutlet var summaryLabel: UITextView!
    
    @IBOutlet var overallRating: UILabel!
    @IBOutlet var meanRecommendation: UILabel!
    @IBOutlet var numberOfAnalysts: UILabel!
    @IBOutlet var oneYearPriceTarget: UILabel!
    @IBOutlet var EPSEstimate: UILabel!

    var companyFundamentalsOperationQueue: OperationQueue = OperationQueue()
    
    @IBOutlet var ratingBarChartView: BarChartView!
    
    @IBAction func xButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ratingBarChartView.delegate = self
        
        let parentTabBarController = self.tabBarController as! CardDetailTabBarController
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
    
    deinit {
        companyFundamentalsOperationQueue.cancelAllOperations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath == IndexPath(row: 0, section: 1) {
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                
                return 300
                
            } else {
                
                return 400
            }
            
        } else if indexPath == IndexPath(row: 1, section: 2) {
            
            return 150
            
        } else {
            
            return 45
        }

    }
    
    func runDataQueueries() {
        
        companyFundamentalsOperationQueue.cancelAllOperations()
        
        // Company figures query
//        let companyFiguresOperation = BlockOperation { () -> Void in
//            QueryHelper.sharedInstance.queryYahooSymbolQuote(tickers: [self.symbol]) { (quoteData, response, error) -> Void in
//
//                do {
//
//                    if error != nil {
//
//                        print("error:", error!.localizedDescription)
//
//                    } else if quoteData != nil {
//
//                        let quoteJsonResults = try JSON(data: quoteData!)["query"]["results"]
//                        let quoteJsonResultsQuote = quoteJsonResults["quote"]
//
//                        DispatchQueue.main.async {
//
//                            if let PE = quoteJsonResultsQuote["PERatio"].string {
//
//                                self.PELabel.text = PE
//                            }
//
//                            if let MarketCapitalization = quoteJsonResultsQuote["MarketCapitalization"].string {
//
//                                self.marketCapLabel.text = MarketCapitalization
//                            }
//
//                            if let EarningsShare = quoteJsonResultsQuote["EarningsShare"].string {
//
//                                self.EPSLabel.text = EarningsShare
//                            }
//
//                            if let YearRange = quoteJsonResultsQuote["YearRange"].string {
//
//                                self.fiftyTwoWeekRange.text = YearRange
//
//                            }
//
//                            if let DividendShare = quoteJsonResultsQuote["DividendShare"].string {
//
//                                self.DivYieldLabel.text = DividendShare
//
//                                var percentYieldString:String!
//
//                                if let percentYield = quoteJsonResultsQuote["DividendYield"].string {
//
//                                    percentYieldString = " (\(percentYield)%)"
//
//                                    self.DivYieldLabel.text = DividendShare + percentYieldString
//                                }
//                            }
//                            //            earningsDateLabel.text = newJsonResultsQuote["MarketCapitalization"].string
//
//                            //            overallRating.text = newJsonResultsQuote["MarketCapitalization"].string
//
//                            if let OneyrTargetPrice = quoteJsonResultsQuote["OneyrTargetPrice"].string {
//
//                                self.oneYearPriceTarget.text = OneyrTargetPrice
//
//                            }
//
//                            if let EPSEstimateNextYear = quoteJsonResultsQuote["EPSEstimateNextYear"].string {
//
//                                self.EPSEstimate.text = EPSEstimateNextYear
//                            }
//
//                            //            companySector.text = newJsonResultsQuote["MarketCapitalization"].string
//                            //            companyIndustry.text = newJsonResultsQuote["MarketCapitalization"].string
//                            //            companySummary.text = newJsonResultsQuote["MarketCapitalization"].string
//                        }
//                    }
//                } catch {
//                    //TODO: handle error
//                }
//            }
//        }
//        companyFiguresOperation.queuePriority = .veryHigh

        // Company analysts rating query
//        let companyAnalystRatings = BlockOperation { () -> Void in
//            QueryHelper.sharedInstance.queryYahooCompanyAnalystRating(symbol: self.symbol) { (companyAnalystRatingData, response, error) -> Void in
//
//                if error != nil {
//
//                    print("error:", error!.localizedDescription)
//
//                } else if companyAnalystRatingData != nil {
//
//                    DispatchQueue.main.async {
//
//                        do {
//
//                            let companyAnalystRatingJSON = try JSON(data: companyAnalystRatingData!)["query"]["results"]
//
//                            if let companyAnalystsRatingMeanRecommendation = companyAnalystRatingJSON["table"][0]["tbody"]["tr"][0]["td"][1]["content"].string {
//
//                                if let inputDoubleValue = Double(companyAnalystsRatingMeanRecommendation) {
//
//                                    self.meanRecommendation.text = companyAnalystsRatingMeanRecommendation
//
//                                    self.setOverallAnalystRating(inputDoubleValue)
//                                }
//                            }
//
//                            if let companyAnalystsRatingNumberOfAnalysts = companyAnalystRatingJSON["table"][1]["tbody"]["tr"][4]["td"][1]["content"].string {
//
//                                self.numberOfAnalysts.text = companyAnalystsRatingNumberOfAnalysts
//                            }
//
//                            let companyAnalystRatingJsonBuySellHoldTable = companyAnalystRatingJSON["table"][3]["tbody"]["tr"]["td"]["table"]["tbody"]
//
//                            if let companyAnalystRatingNumberOfBuys = companyAnalystRatingJsonBuySellHoldTable["tr"][1]["td"][1]["content"].string {
//
//                                self.ratings[0] = Double(companyAnalystRatingNumberOfBuys)!
//                            }
//
//                            if let companyAnalystRatingNumberOfOutperform = companyAnalystRatingJsonBuySellHoldTable["tr"][2]["td"][1]["content"].string {
//
//                                self.ratings[1] = Double(companyAnalystRatingNumberOfOutperform)!
//                            }
//
//                            if let companyAnalystRatingNumberOfHolds = companyAnalystRatingJsonBuySellHoldTable["tr"][3]["td"][1]["content"].string {
//
//                                self.ratings[2] = Double(companyAnalystRatingNumberOfHolds)!
//                            }
//
//                            if let companyAnalystRatingNumberOfUnderPerform = companyAnalystRatingJsonBuySellHoldTable["tr"][4]["td"][1]["content"].string {
//
//                                self.ratings[3] = Double(companyAnalystRatingNumberOfUnderPerform)!
//                            }
//
//                            if let companyAnalystRatingNumberOfSells = companyAnalystRatingJsonBuySellHoldTable["tr"][5]["td"][1]["content"].string {
//
//                                self.ratings[4] = Double(companyAnalystRatingNumberOfSells)!
//                            }
//
//                            self.setChart(self.ratingsType, values: self.ratings)
//
//                        } catch {
//                            //TODO: handle error
//                        }
//                    }
//                }
//            }
//        }
//        companyAnalystRatings.queuePriority = .high
    
        // Company Profile Query
        let companyFundamentalsQperation = BlockOperation { () -> Void in
            QueryHelper.sharedInstance.queryEODFundamentals(for: self.symbol, completionHandler: { eodFundamentalsResults in
                
                do {
                    guard let eodFundamentalsResults = try eodFundamentalsResults() else { return }
                    
                    DispatchQueue.main.async {
                        
                        self.PELabel.text = eodFundamentalsResults.highlights.peRatio ?? "--"
                        self.marketCapLabel.text = (eodFundamentalsResults.highlights.marketCapitalization != nil) ? eodFundamentalsResults.highlights.marketCapitalization?.suffixNumber() : "--"
                        self.EPSLabel.text =  eodFundamentalsResults.highlights.epsEstimateCurrentYear ?? "--"
                        self.bookValueLabel.text = eodFundamentalsResults.highlights.bookValue ?? "--"
                        self.divYieldLabel.text =  eodFundamentalsResults.highlights.dividendYield ?? "--"
                        self.earningsDateLabel.text = eodFundamentalsResults.highlights.mostRecentQuarter ?? "--"
                        self.EBITDALabel.text = eodFundamentalsResults.highlights.EBITDA != nil ? String(eodFundamentalsResults.highlights.EBITDA!) : "--"
                        self.wallstreetTargetLabel.text = eodFundamentalsResults.highlights.wallStreetTargetPrice ?? "--"
                        
                        let fifyTwoWeekLow = eodFundamentalsResults.technicals.fiftyTwoWeekLow ?? ""
                        let fifyTwoWeekHigh = eodFundamentalsResults.technicals.fiftyTwoWeekHigh ?? ""
                        self.fiftyTwoWeekRange.text = fifyTwoWeekLow + " - " + fifyTwoWeekHigh
                        self.fiftyMALabel.text = eodFundamentalsResults.technicals.fiftyDayMA ?? ""
                        self.twoHundredMALabel.text = eodFundamentalsResults.technicals.twoHundredDayMA ?? ""
                        self.betaLabel.text = eodFundamentalsResults.technicals.beta ?? ""
                        self.shortRatioLabel.text = eodFundamentalsResults.technicals.shortRatio ?? ""
                        
                        self.sectorLabel.text = eodFundamentalsResults.general.sector ?? "--"
                        self.industryLabel.text = eodFundamentalsResults.general.industry ?? "--"
                        self.fulltimeEmployeesLabel.text = (eodFundamentalsResults.general.fullTimeEmployees != nil) ? String(eodFundamentalsResults.general.fullTimeEmployees!) : "--"
                        self.exchangeLabel.text = eodFundamentalsResults.general.exchange ?? "--"
                        self.summaryLabel.text = eodFundamentalsResults.general.description ?? "--"
                    }
                    
                } catch {
                    //TODO: handle error
                }
            })
        }
        companyFundamentalsQperation.queuePriority = .normal
        self.companyFundamentalsOperationQueue.addOperations([companyFundamentalsQperation], waitUntilFinished: false)
    }

    // MARK: Analysts Rating Bar Chart Stuff

    func setChart(_ dataPoints: [String], values: [Double]) {
        
        var dataEntries = [BarChartDataEntry]()
        
        for i in 0..<dataPoints.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Analysts Rating")
        chartDataSet.colors = [Constants.stockSwipeGreenColor, outperformGreen, UIColor.yellow, UIColor.orange , UIColor.red]
        chartDataSet.valueFont = UIFont(name: "HelveticaNeue", size: 15.0)!
        chartDataSet.valueFormatter = ChartYValueFormatter(values: values)
        
        // X-Axis formatting
        ratingBarChartView.xAxis.labelPosition = .bottom
        ratingBarChartView.xAxis.granularity = 1
        ratingBarChartView.xAxis.drawGridLinesEnabled = false
        ratingBarChartView.xAxis.labelFont = UIFont(name: "HelveticaNeue", size: 11.0)!
        ratingBarChartView.xAxis.labelTextColor = Constants.stockSwipeFontColor
        ratingBarChartView.xAxis.valueFormatter = ChartXAxisFormatter(entries: ratingsType)
        
        // Left-Axis formatting
        ratingBarChartView.leftAxis.enabled = false
        ratingBarChartView.leftAxis.drawGridLinesEnabled = false
        ratingBarChartView.leftAxis.axisMinimum = 0.0
        
        // Right-Axis formatting
        ratingBarChartView.rightAxis.enabled = false
        ratingBarChartView.rightAxis.drawGridLinesEnabled = false
        
        // Other formatting
        ratingBarChartView.chartDescription = nil
        ratingBarChartView.drawBordersEnabled = false
        ratingBarChartView.drawGridBackgroundEnabled = false
        ratingBarChartView.legend.enabled = false
        ratingBarChartView.isUserInteractionEnabled = false
        
        let chartData = BarChartData(dataSet: chartDataSet)
        
        ratingBarChartView.data = chartData
        ratingBarChartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5)
    }
    
    func setOverallAnalystRating(_ input: Double) {
        
        switch input {
            
        case input where input >= 1.0 && input <= 1.5:
            
            overallRating.text = "Buy"
            overallRating.textColor = Constants.stockSwipeGreenColor
            
        case input where input > 1.5 && input <= 2.5:
            
            overallRating.text = "Outperform"
            overallRating.textColor = outperformGreen
            
        case input where input > 2.5 && input <= 3.5:
            
            overallRating.text = "Hold"
            overallRating.textColor = UIColor.yellow
            
        case input where input > 3.5 && input <= 4.5:
            
            overallRating.text = "Underperform"
            overallRating.textColor = UIColor.orange
            
        case input where input > 4.5 && input <= 5.0:
            
            overallRating.text = "Sell"
            overallRating.textColor = UIColor.red
            
        default:
            
            break
        }
    }
}
