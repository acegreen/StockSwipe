//
//  ChoosePersonView.swift
//  SwiftLikedOrNope
//
// Copyright (c) 2014 to present, Richard Burdish @rjburdish
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit
import MDCSwipeToChoose
import Charts

@IBDesignable
class SwipeCardView: MDCSwipeToChooseView {
    
    // Our custom view from the XIB file
    var customView: UIView!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var exchangeLabel: UILabel!
    
    @IBOutlet weak var chartView: LineChartView!
    
    @IBOutlet var highlightOneImageView: UIImageView!
    @IBOutlet var highlightOneTitleLabel: UILabel!
    @IBOutlet var highlightOneSubtitleLabel: UILabel!
    
    @IBOutlet var highlightTwoImageView: UIImageView!
    @IBOutlet var highlightTwoTitleLabel: UILabel!
    @IBOutlet var highlightTwoSubtitleLabel: UILabel!
    
    @IBOutlet var highlightThreeImageView: UIImageView!
    @IBOutlet var highlightThreeTitleLabel: UILabel!
    @IBOutlet var highlightThreeSubtitleLabel: UILabel!
    
    var card: Card!
    var disabledHighlightedAnimation = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadViewFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
    }
    
    init(frame: CGRect, card: Card, options: MDCSwipeToChooseViewOptions?) {
        super.init(frame: frame, options: options)
        self.card = card
        
        loadViewFromNib()
        self.setCardInfo()
        
        self.addCenterMotionEffectsXY(withOffset: motionOffset)
    }
    
    func loadViewFromNib() {
        let name = String(describing: type(of: self))
        let nib = UINib(nibName: name, bundle: .main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        self.customView = view
        self.addSubview(self.customView)
        self.sendSubviewToBack(self.customView)
        self.customView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.customView.topAnchor.constraint(equalTo: self.topAnchor),
            self.customView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.customView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.customView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ])
        
        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [UIView.AutoresizingMask.flexibleHeight, UIView.AutoresizingMask.flexibleWidth]
    }
    
    func setCardInfo() {
        self.setInfo()
        self.makeChart()
        self.setHighlights()
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

        if let _ = values.find ({ $0 > 1 }) {

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
            //            lineDataSet.circleRadius = 6.0
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

        } else {
            chartView.isHidden = true
        }
    }
    
    func resetTransform() {
        transform = .identity
    }
    
    // Make it appears very responsive to touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animate(isHighlighted: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animate(isHighlighted: false)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animate(isHighlighted: false)
    }
    
    private func animate(isHighlighted: Bool, completion: ((Bool) -> Void)? = nil) {
        
        guard !disabledHighlightedAnimation else { return }
        
        let animationOptions: UIView.AnimationOptions = Constants.isEnabledAllowsUserInteractionWhileHighlightingCard
            ? [.allowUserInteraction] : []
        if isHighlighted {
            self.cornerRadius = 15
            UIView.animate(withDuration: 1,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 0,
                           options: animationOptions, animations: {
                            self.transform = .init(scaleX: Constants.cardHighlightedFactor, y: Constants.cardHighlightedFactor)
            }, completion: completion)
        } else {
            UIView.animate(withDuration: 1,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 0,
                           options: animationOptions, animations: {
                            self.transform = .identity
            }, completion: completion)
        }
    }
}
