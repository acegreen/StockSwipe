//
//  CardDetailFirstPageViewController.swift
//  StockSwipe
//
//  Created by Ace Green on 2/12/19.
//  Copyright © 2019 StockSwipe. All rights reserved.
//

import Foundation

class CardDetailFirstPageViewController: UIViewController {
    
    @IBOutlet var summaryTextview: UITextView!
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
    @IBOutlet var exchangeLabel: UILabel!
    @IBOutlet var fulltimeEmployeesLabel: UILabel!
    
    var card: Card! {
        didSet {
            if self.view != nil {
                self.loadInfo()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // adjust summaryTextview so it starts at the top
        self.summaryTextview.setContentOffset(CGPoint.zero, animated: false)
    }
    
    func loadInfo() {
        guard let eodFundamentalsData = card.eodFundamentalsData else { return }
        
        self.PELabel.text = eodFundamentalsData.highlights?.peRatio ?? "--"
        self.marketCapLabel.text = (eodFundamentalsData.highlights?.marketCapitalization != nil) ? eodFundamentalsData.highlights?.marketCapitalization?.suffixNumber() : "--"
        self.EPSLabel.text = eodFundamentalsData.highlights?.eps ?? "--"
        self.bookValueLabel.text = eodFundamentalsData.highlights?.bookValue ?? "--"

        if let dividendYield = eodFundamentalsData.highlights?.dividendYield, let dividendDouble = Double(dividendYield) {
            self.divYieldLabel.text = String(dividendDouble * 100) + "%"
        }

        self.earningsDateLabel.text = eodFundamentalsData.highlights?.mostRecentQuarter ?? "--"
        self.EBITDALabel.text = eodFundamentalsData.highlights?.EBITDA != nil ? String(eodFundamentalsData.highlights?.EBITDA?.suffixNumber() ?? "0") : "--"
        self.wallstreetTargetLabel.text = eodFundamentalsData.highlights?.wallStreetTargetPrice ?? "--"
        
        let fifyTwoWeekLow = String(eodFundamentalsData.technicals.fiftyTwoWeekLow ?? 0)
        let fifyTwoWeekHigh = String(eodFundamentalsData.technicals.fiftyTwoWeekHigh ?? 0)
        self.fiftyTwoWeekRange.text = fifyTwoWeekLow + " - " + fifyTwoWeekHigh
        self.fiftyMALabel.text = eodFundamentalsData.technicals.fiftyDayMA ?? "--"
        self.twoHundredMALabel.text = eodFundamentalsData.technicals.twoHundredDayMA ?? "--"
        self.betaLabel.text = eodFundamentalsData.technicals.beta ?? "--"
        self.shortRatioLabel.text = eodFundamentalsData.technicals.shortRatio ?? "--"
        
        self.sectorLabel.text = eodFundamentalsData.general.sector ?? "--"
        self.industryLabel.text = eodFundamentalsData.general.industry ?? "--"
        self.fulltimeEmployeesLabel.text = (eodFundamentalsData.general.fullTimeEmployees != nil) ? String(eodFundamentalsData.general.fullTimeEmployees!) : "--"
        self.exchangeLabel.text = eodFundamentalsData.general.exchange ?? "--"
        self.summaryTextview.text = eodFundamentalsData.general.description ?? "--"
    }
}
