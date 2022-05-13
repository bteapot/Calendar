//
//  ViewController.swift
//  Example
//
//  Created by Денис Либит on 27.04.2022.
//

import UIKit
import Calendar
import CalendarEventKit


final class ViewController: UITableViewController {
    
    // MARK: - Инициализация
    
    init() {
        // инициализируемся
        super.init(style: .grouped)
        
        // свойства
        self.title = "Примеры"
        
        // навбар
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError()}
    
    private let data: [Section] = [
        Section(title: "Стандартные", items: [
            Item(title: "Из коробки", action: { host in
                let calendar = CalendarVC(
                    title: "Из коробки",
                    navigation: .auto,
                    dataSource: CalendarVC.DataSource.EventKit(.all()),
                    style: .default.copy {
                        $0.navbar.translucent = true
                    },
                    selection: .custom({ controller, event, view, done in
                        NSLog("tapped: \(event)")
                        done()
                    })
                )
                host.navigationController?.pushViewController(calendar, animated: true)
            }),
        ]),
    ]
    
    // MARK: - Жизненный цикл
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    // MARK: - Источник данных
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item: Item =
            self.data[indexPath.section].items[indexPath.row]
        
        let cell: UITableViewCell =
            tableView.dequeueReusableCell(withIdentifier: "cell") ?? {
                let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
                cell.accessoryType = .disclosureIndicator
                return cell
            }()
        
        cell.textLabel?.text = item.title
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.data[section].title
    }
    
    // MARK: - Делегат
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item: Item =
            self.data[indexPath.section].items[indexPath.row]
        item.action(self)
    }
}

private extension ViewController {
    struct Section {
        let title: String
        let items: [Item]
    }
    
    struct Item {
        let title: String
        let action: (UIViewController) -> Void
    }
}
