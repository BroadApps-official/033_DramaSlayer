import ApphudSDK
import AVFoundation
import MobileCoreServices
import SnapKit
import StoreKit
import UIKit
import UniformTypeIdentifiers

final class OpenCategoryViewController: UIViewController {
    private let purchaseManager = PurchaseManager()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private var videos: [Video] = []
    private var selectedVideo: Video?
    private var categoryLabel: String

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 32

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(SerialCell.self, forCellWithReuseIdentifier: SerialCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    init(models: [Video], categoryTitle: String) {
        videos = models
        categoryLabel = categoryTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        tabBarController?.tabBar.isTranslucent = true
        tabBarController?.tabBar.backgroundImage = UIImage()
        tabBarController?.tabBar.shadowImage = UIImage()

        view.backgroundColor = UIColor.bgMain

        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.setTitleColor(.white, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem

        drawSelf()

        collectionView.reloadData()
        collectionView.delegate = self
        collectionView.dataSource = self

        navigationItem.title = categoryLabel
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = .portrait
        }
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }

    private func drawSelf() {
        activityIndicator.color = UIColor.colorsSecondary
        updateActivityIndicatorVisibility()

        view.addSubviews(collectionView, activityIndicator)

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.bottom.equalToSuperview()
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func updateActivityIndicatorVisibility() {
        if videos.isEmpty {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension OpenCategoryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SerialCell.identifier, for: indexPath) as? SerialCell else {
            return UICollectionViewCell()
        }
        let video = videos[indexPath.item]
        cell.configure(with: video)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedVideo = videos[indexPath.item]
        self.selectedVideo = selectedVideo

        if let cell = collectionView.cellForItem(at: indexPath) as? SerialCell {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    cell.transform = CGAffineTransform.identity
                }
            }
        }

        let playerVC = PlayerViewController(video: selectedVideo)
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width / 2) - 8
        return CGSize(width: width, height: 287)
    }
}
