//
//  CardView.swift
//  StockSwipe
//
//  Created by Ace Green on 2/13/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit
import Charts

@IBDesignable
final class CardView: UIView, NibLoadable {
    
    @IBOutlet weak var companyNameAndSymbolLabel: UILabel!
    @IBOutlet weak var currentPriceLabel: UILabel!
    @IBOutlet weak var exchangeLabel: UILabel!
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var overlayLabel: UILabel!
    
    @IBOutlet weak var highlightOneImageView: UIImageView!
    @IBOutlet weak var highlightOneTitleLabel: UILabel!
    @IBOutlet weak var highlightOneSubtitleLabel: UILabel!
    
    @IBOutlet weak var highlightTwoImageView: UIImageView!
    @IBOutlet weak var highlightTwoTitleLabel: UILabel!
    @IBOutlet weak var highlightTwoSubtitleLabel: UILabel!
    
    @IBOutlet weak var highlightThreeImageView: UIImageView!
    @IBOutlet weak var highlightThreeTitleLabel: UILabel!
    @IBOutlet weak var highlightThreeSubtitleLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fromNib()
        setChartGeneralAppearance()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        fromNib()
        setChartGeneralAppearance()
    }
    
    func configure(with card: Card) {
        self.setInfo(with: card)
        self.setHighlights(with: card)
        self.makeChart(with: card)
    }
    
    private func setInfo(with card: Card) {
        if let companyName = card.companyName {
            self.companyNameAndSymbolLabel.text = companyName + " " + "(\(card.symbol!))"
        } else {
            self.companyNameAndSymbolLabel.text = card.symbol

        }
        
        if let currencySymbol = card.eodFundamentalsData?.general.currencySymbol, let adjustedCloseString = card.eodHistoricalData?.last?.adjustedClose {
            let adjustedCloseRounded = Double(adjustedCloseString).roundTo(2) 
            self.currentPriceLabel.text = currencySymbol + String(adjustedCloseRounded)
        } else {
            self.currentPriceLabel.text = "--"
        }
        self.exchangeLabel.text = card.exchange
        
        guard let userChoice = card.userChoice else { return }
        
        switch userChoice {
            
        case .SHORT:
            self.overlayLabel.layer.borderColor = UIColor.red.cgColor
            self.overlayLabel.text = "\(Constants.UserChoices.SHORT.rawValue)"
            self.overlayLabel.textColor = UIColor.red
            self.overlayLabel.transform = CGAffineTransform.identity.rotated(by: 15.toRadians())
            self.overlayLabel.isHidden = false
        case .LONG:
            self.overlayLabel.layer.borderColor = Constants.SSColors.greenDark.cgColor
            self.overlayLabel.text = "\(Constants.UserChoices.LONG.rawValue)"
            self.overlayLabel.textColor = Constants.SSColors.greenDark
            self.overlayLabel.transform = CGAffineTransform.identity.rotated(by: -15.toRadians())
            self.overlayLabel.isHidden = false
        case .SKIP:
            self.overlayLabel.isHidden = true
        }
        
        self.overlayLabel.layer.borderWidth = 3.0
        self.overlayLabel.layer.cornerRadius = 7.5
    }
    
    private func makeChart(with card: Card) {
        
        guard let eodData = card.eodHistoricalData else { return }
        
        var xValues = [String]()
        var yValues = [Double]()
        for (key, value) in eodData.enumerated() {
            if let adjustedClose = value.adjustedClose {
                xValues.append(String(key))
                yValues.append(adjustedClose)
            }
        }
        
        setChart(xValues, values: yValues)
    }
    
    private func setHighlights(with card: Card) {
        
        guard let eodFundamentalsData = card.eodFundamentalsData else { return }
        
        self.highlightOneTitleLabel.text = "PE"
        self.highlightOneSubtitleLabel.text = String(Double(eodFundamentalsData.highlights?.peRatio ?? "--")?.roundTo(2) ?? 0)
        
        self.highlightTwoTitleLabel.text = "EPS"
        self.highlightTwoSubtitleLabel.text =  String(Double(eodFundamentalsData.highlights?.eps ?? "--")?.roundTo(2) ?? 0)
        
        self.highlightThreeTitleLabel.text = "Short Ratio"
        self.highlightThreeSubtitleLabel.text = String(Double(eodFundamentalsData.technicals.shortRatio ?? "--")?.roundTo(2) ?? 0)
    }
    
    private func setChart(_ dataPoints: [String], values: [Double]) {
    
        var lineChartDataEntry = [ChartDataEntry]()
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: values[i])
            lineChartDataEntry.append(dataEntry)
        }
        
        let lineDataSet = LineChartDataSet(entries: lineChartDataEntry, label: nil)
        lineDataSet.drawValuesEnabled = false
        lineDataSet.axisDependency = .left
        lineDataSet.setColor(UIColor.white)
        lineDataSet.lineWidth = 3.0
        lineDataSet.circleRadius = 6.0
        lineDataSet.fillAlpha = 65 / 255.0
        lineDataSet.fillColor = UIColor.clear
        lineDataSet.highlightColor = UIColor.white
        lineDataSet.drawCircleHoleEnabled = true
        lineDataSet.setCircleColor(UIColor.white)
        lineDataSet.drawCirclesEnabled = false
        
        let chartDataSet = LineChartData()
        chartDataSet.addDataSet(lineDataSet)
        
        //            let marker: BalloonMarker = BalloonMarker(color: UIColor.white, font: UIFont.systemFont(ofSize: 12.0), insets: UIEdgeInsetsMake(8.0, 8.0, 20.0, 8.0))
        //            marker.minimumSize = CGSize(width: 40.0, height: 40.0)
        
        //            chartView.marker = marker
        
        chartView.data = chartDataSet
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 0)
    }
    
    func clear() {
        self.companyNameAndSymbolLabel.text = "Company Name"
        self.currentPriceLabel.text = "$0.00"
        self.exchangeLabel.text = "Exchange"
        self.chartView.clear()
        self.overlayLabel.text = ""
        self.overlayLabel.isHidden = true
        
        self.highlightOneSubtitleLabel.text = "--"
        self.highlightTwoSubtitleLabel.text = "--"
        self.highlightThreeSubtitleLabel.text = "--"
    }
    
    private func setChartGeneralAppearance() {
        chartView.noDataText = "No card data available"
        chartView.noDataFont = Constants.SSFonts.medium
        chartView.noDataTextColor = UIColor.white
        chartView.xAxis.enabled = false
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.leftAxis.enabled = false
        chartView.leftAxis.drawGridLinesEnabled = false
        chartView.rightAxis.enabled = false
        chartView.rightAxis.drawGridLinesEnabled = false
        chartView.drawBordersEnabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.isUserInteractionEnabled = false
        chartView.legend.enabled = false
    }
}
