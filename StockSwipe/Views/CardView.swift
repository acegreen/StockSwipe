//
//  CardView.swift
//  StockSwipe
//
//  Created by Ace Green on 2/13/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import UIKit
import Charts

@IBDesignable final class CardView: UIView, NibLoadable {
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var exchangeLabel: UILabel!
    
    @IBOutlet weak var chartView: LineChartView!
    
    @IBOutlet weak var highlightOneImageView: UIImageView!
    @IBOutlet weak var highlightOneTitleLabel: UILabel!
    @IBOutlet weak var highlightOneSubtitleLabel: UILabel!
    
    @IBOutlet weak var highlightTwoImageView: UIImageView!
    @IBOutlet weak var highlightTwoTitleLabel: UILabel!
    @IBOutlet weak var highlightTwoSubtitleLabel: UILabel!
    
    @IBOutlet weak var highlightThreeImageView: UIImageView!
    @IBOutlet weak var highlightThreeTitleLabel: UILabel!
    @IBOutlet weak var highlightThreeSubtitleLabel: UILabel!
    
    var card: Card! {
        didSet {
            self.setCardInfo()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        fromNib()
    }
    
    private func setCardInfo() {
        self.setInfo()
        self.setHighlights()
        self.makeChart()
    }
    
    private func setInfo() {
        self.symbolLabel.text = card.symbol
        self.companyNameLabel.text = card.companyName
        self.exchangeLabel.text = card.exchange
    }
    
    private func makeChart() {
        
        guard let eodData = card.eodHistoricalData else { return }
        
        var xValues = [String]()
        var yValues = [Double]()
        for (key, value) in eodData.enumerated() {
            
            if let adjustedClose = value.adjustedCloseValue {
                xValues.append(String(key))
                yValues.append(adjustedClose)
            }
        }
        
        setChart(xValues, values: yValues)
    }
    
    private func setHighlights() {
        
        guard let eodFundamentalsData = self.card.eodFundamentalsData else { return }
        
        self.highlightOneTitleLabel.text = "PE"
        self.highlightOneSubtitleLabel.text = eodFundamentalsData.highlights.peRatio != nil ? String(Double(eodFundamentalsData.highlights.peRatio!)!.roundTo(2)) : "--"
        
        self.highlightTwoTitleLabel.text = "EPS"
        self.highlightTwoSubtitleLabel.text = eodFundamentalsData.highlights.eps != nil ? String(Double(eodFundamentalsData.highlights.eps!)!.roundTo(2)) : "--"
        
        self.highlightThreeTitleLabel.text = "Short Ratio"
        self.highlightThreeSubtitleLabel.text = eodFundamentalsData.technicals.shortRatio != nil ? String(Double(eodFundamentalsData.technicals.shortRatio!)!.roundTo(2)) : "--"
    }
    
    private func setChart(_ dataPoints: [String], values: [Double]) {
    
        var lineChartDataEntry = [ChartDataEntry]()
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: values[i])
            lineChartDataEntry.append(dataEntry)
        }
        
        let lineDataSet = LineChartDataSet(values: lineChartDataEntry, label: nil)
        lineDataSet.drawValuesEnabled = false
        lineDataSet.axisDependency = .left
        lineDataSet.setColor(UIColor.white)
        lineDataSet.setCircleColor(UIColor.white)
        lineDataSet.lineWidth = 3.0
        
        lineDataSet.drawCirclesEnabled = false
        lineDataSet.circleRadius = 6.0
        lineDataSet.fillAlpha = 65 / 255.0
        lineDataSet.fillColor = UIColor.clear
        lineDataSet.highlightColor = UIColor.white
        lineDataSet.drawCircleHoleEnabled = true
        
        let chartDataSet = LineChartData()
        chartDataSet.addDataSet(lineDataSet)
        
        //            let marker: BalloonMarker = BalloonMarker(color: UIColor.white, font: UIFont.systemFont(ofSize: 12.0), insets: UIEdgeInsetsMake(8.0, 8.0, 20.0, 8.0))
        //            marker.minimumSize = CGSize(width: 40.0, height: 40.0)
        
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
        //            chartView.marker = marker
        
        chartView.data = chartDataSet
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 0)
    }
}
