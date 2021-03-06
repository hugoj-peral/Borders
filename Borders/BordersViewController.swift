//
//  BordersViewController.swift
//  Borders
//
//  Created by Guillermo Gonzalez on 24/01/16.
//  Copyright © 2016 Guillermo Gonzalez. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class BordersViewController: UITableViewController {

    // MARK: - Properties
    
    private let viewModel: BordersViewModelType
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(viewModel: BordersViewModelType) {
        self.viewModel = viewModel
        
        super.init(style: .Plain)
    }
    
    convenience init(countryName: String) {
        self.init(viewModel: BordersClientWithoutRxViewModel(countryName: countryName))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupBindings()
    }
    
    // MARK: - Private
    
    private func setupView() {
        tableView.register(BorderCell)
        tableView.rowHeight = BorderCell.rowHeight
    }
    
    private func setupBindings() {
        title = viewModel.countryName
        tableView.dataSource = nil
        
        viewModel.borders
            .bindTo(tableView.rx_itemsWithCellFactory) { tableView, index, border in
                let cell: BorderCell = tableView.dequeueReusableCell()
                cell.border = border
                
                return cell
            }
            .addDisposableTo(disposeBag)
    }
}
