import SnapKit
import UIKit

final class TabBarController: UITabBarController {
    static let shared = TabBarController()

    // MARK: - View Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()

        let homeVC = UINavigationController(
            rootViewController: HomeViewController()
        )
        let discoverVC = UINavigationController(
            rootViewController: DiscoverViewController()
        )
        let myListVC = UINavigationController(
            rootViewController: MyListViewController()
        )

        homeVC.tabBarItem = UITabBarItem(
            title: L.home(),
            image: UIImage(systemName: "house"),
            tag: 0
        )

        discoverVC.tabBarItem = UITabBarItem(
            title: L.discover(),
            image: UIImage(systemName: "play.rectangle"),
            tag: 1
        )

        myListVC.tabBarItem = UITabBarItem(
            title: L.myList(),
            image: UIImage(systemName: "tray.full"),
            tag: 2
        )

        let viewControllers = [homeVC, discoverVC, myListVC]
        self.viewControllers = viewControllers

        addSeparatorLine()
        updateTabBar()
    }

    func updateTabBar() {
        tabBar.backgroundColor = UIColor.bgMain
        tabBar.tintColor = UIColor.colorsSecondary
        tabBar.unselectedItemTintColor = UIColor(hex: "#999999")
        tabBar.itemPositioning = .centered
    }

    private func addSeparatorLine() {
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.bgSecond
        tabBar.addSubview(separatorLine)

        separatorLine.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.trailing.equalTo(tabBar)
            make.top.equalTo(tabBar.snp.top)
        }
    }
}
