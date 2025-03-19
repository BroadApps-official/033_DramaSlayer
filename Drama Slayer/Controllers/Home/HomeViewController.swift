import ApphudSDK
import AVFoundation
import MobileCoreServices
import SnapKit
import UIKit
import UniformTypeIdentifiers

final class HomeViewController: UIViewController {
    private let purchaseManager = PurchaseManager()
    private let imageView = UIImageView()
    private let shadowImageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var groupedCategories: [(category: Category, videos: [Video])] = []
    private var videos: [Video] = []
    private var selectedVideo: Video?
    private var firstModel: Video?
    private var blurEffectView: UIVisualEffectView?

    private let playButton = MainButton()
    private let firstVideoLabel = UILabel()

    private lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewLayout = createCompositionalLayout()

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(SerialCell.self, forCellWithReuseIdentifier: SerialCell.identifier)
        collectionView.register(HeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: HeaderView.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()

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

        drawSelf()
        scrollView.delegate = self

        let searchButton = UIBarButtonItem(
            image: R.image.home_search_icon(),
            style: .plain,
            target: self,
            action: #selector(didTapSearchButton)
        )
        searchButton.tintColor = .white
        navigationItem.rightBarButtonItem = searchButton

        Task {
            do {
                let videoData = try await NetworkService.shared.fetchVideos()
                videos = videoData.videos
                print(videoData.categories)
                print(videoData.videos)

                groupVideosByCategory(videos: videoData.videos, categories: videoData.categories)
                collectionView.reloadData()
                updateActivityIndicatorVisibility()

                if let firstVideo = videoData.videos.first {
                    self.firstModel = firstVideo
                    self.firstVideoLabel.text = firstVideo.title
                    loadImage(from: firstVideo.cover)
                }
            } catch {
                updateActivityIndicatorVisibility()
            }
            calculateCollectionViewHeight()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = .portrait
        }

        Task {
            do {
                let videoData = try await NetworkService.shared.fetchVideos()
                let updatedVideos = videoData.videos
                for updatedVideo in updatedVideos {
                    if let existingVideo = self.videos.first(where: { $0.id == updatedVideo.id }) {
                        if existingVideo.isFavourite != updatedVideo.isFavourite {
                            updateVideoModel(videoId: updatedVideo.id)
                        }
                    }
                }

                for updatedVideo in updatedVideos {
                    if let index = self.videos.firstIndex(where: { $0.id == updatedVideo.id }) {
                        self.videos[index] = updatedVideo
                    } else {
                        self.videos.append(updatedVideo)
                    }
                }

                if let firstVideo = updatedVideos.first {
                    self.firstModel = firstVideo
                    loadImage(from: firstVideo.cover)
                }

            } catch {
                print("Fetch video error: \(error)")
            }
        }
    }

    private func drawSelf() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.scrollIndicatorInsets = .zero
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        shadowImageView.image = R.image.home_shadow_image()
        activityIndicator.color = UIColor.colorsSecondary
        updateActivityIndicatorVisibility()

        imageView.do { make in
            if UIDevice.isIphoneBelowX {
                make.contentMode = .scaleToFill
            } else {
//                make.contentMode = .scaleAspectFill
                make.contentMode = .scaleToFill
            }
        }

        playButton.do { make in
            make.homePlay()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playButtonTapped))
            make.addGestureRecognizer(tapGesture)
        }

        firstVideoLabel.do { make in
            make.font = UIFont.CustomFont.subheadlineSemibold
            make.textColor = UIColor.textMain
            make.textAlignment = .natural
        }

        view.addSubviews(scrollView, activityIndicator)
        scrollView.addSubviews(contentView)

        contentView.addSubview(imageView)
        contentView.addSubview(shadowImageView)
        contentView.addSubview(playButton)
        contentView.addSubview(firstVideoLabel)
        contentView.addSubview(collectionView)

        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            if UIDevice.isIphoneBelowX {
                make.height.equalTo(UIScreen.main.bounds.height * (400.0 / 844.0))
                make.bottom.equalTo(shadowImageView.snp.bottom)
            } else {
                make.height.equalTo(UIScreen.main.bounds.height * (497.0 / 844.0))
            }
        }

        shadowImageView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(-280)
            make.height.equalTo(UIScreen.main.bounds.height * (337.0 / 844.0))
        }

        playButton.snp.makeConstraints { make in
            make.bottom.equalTo(imageView.snp.bottom).offset(-20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(49)
        }

        firstVideoLabel.snp.makeConstraints { make in
            make.bottom.equalTo(playButton.snp.top).offset(-16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func calculateCollectionViewHeight() -> CGFloat {
        let itemHeight: CGFloat = 203
        let headerHeight: CGFloat = 76
        let sectionSpacing: CGFloat = 8
        let totalSections = groupedCategories.count

        if totalSections == 0 {
            return 0
        }

        let sectionsHeight = CGFloat(totalSections) * itemHeight
        let headersHeight = CGFloat(totalSections) * headerHeight
        let spacingHeight = CGFloat(totalSections - 1) * sectionSpacing

        let totalHeight = sectionsHeight + headersHeight + spacingHeight

        collectionView.snp.remakeConstraints { make in
            make.top.equalTo(imageView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(totalHeight)
        }

        collectionView.layoutIfNeeded()
        return totalHeight
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(126), heightDimension: .absolute(203))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(126 * 3), heightDimension: .absolute(203))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(4)

            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(76))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )

            section.boundarySupplementaryItems = [header]
            section.interGroupSpacing = 8
            return section
        }
    }

    func groupVideosByCategory(videos: [Video], categories: [Category]) {
        var grouped = [(category: Category, videos: [Video])]()
        for category in categories {
            let filteredVideos = videos.filter { video in
                video.categoryId == category.id
            }
            grouped.append((category: category, videos: filteredVideos))
        }
        groupedCategories = grouped
    }

    private func updateActivityIndicatorVisibility() {
        if videos.isEmpty {
            activityIndicator.startAnimating()
            navigationController?.navigationBar.isHidden = true
            playButton.isHidden = true
            firstVideoLabel.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            navigationController?.navigationBar.isHidden = false
            playButton.isHidden = false
            firstVideoLabel.isHidden = false
        }
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        if let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            imageView.image = image
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data), let response = response else { return }
            let cachedResponse = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: url))

            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }.resume()
    }

    @objc private func didTapSearchButton() {
        let searchVC = SearchViewController(models: videos)
        let navigationController = UINavigationController(rootViewController: searchVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }

    @objc func playButtonTapped() {
        guard let firstModel = firstModel else { return }
        let playerVC = PlayerViewController(video: firstModel)
        playerVC.delegate = self
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groupedCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupedCategories[section].videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SerialCell.identifier, for: indexPath) as? SerialCell else {
            return UICollectionViewCell()
        }
        let video = groupedCategories[indexPath.section].videos[indexPath.item]
        cell.configure(with: video)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderView.identifier, for: indexPath) as? HeaderView else {
            return UICollectionReusableView()
        }

        let categoryTitle = groupedCategories[indexPath.section].category.title
        header.configure(with: categoryTitle, sectionIndex: indexPath.section)
        header.delegate = self

        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedVideo = groupedCategories[indexPath.section].videos[indexPath.item]
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
        playerVC.delegate = self
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 126, height: 203)
    }
}

// MARK: - HeaderViewDelegate
extension HomeViewController: HeaderViewDelegate {
    func didTapHeaderButton(sectionIndex: Int) {
        let selectedCategory = groupedCategories[sectionIndex]
        let openCategoryVC = OpenCategoryViewController(models: selectedCategory.videos, categoryTitle: selectedCategory.category.title)
        let navigationController = UINavigationController(rootViewController: openCategoryVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate
extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let maxOffset: CGFloat = 150
        let alpha = min(max(offset / maxOffset, 0), 1)

        let appearance = UINavigationBarAppearance()
        let color = UIColor.bgMain.withAlphaComponent(alpha)
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = color
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            self.navigationController?.navigationBar.compactAppearance = appearance
        }
    }
}

// MARK: - PlayerDelegate
extension HomeViewController: PlayerDelegate {
    func updateVideoModel(videoId: Int) {
        Task {
            do {
                let updatedVideo = try await NetworkService.shared.fetchSpecificVideo(videoId: videoId)
                if let videoIndex = videos.firstIndex(where: { $0.id == videoId }) {
                    videos[videoIndex] = updatedVideo
                }

                var indexPathToUpdate: IndexPath?

                for (sectionIndex, categoryTuple) in groupedCategories.enumerated() {
                    if let itemIndex = categoryTuple.videos.firstIndex(where: { $0.id == videoId }) {
                        groupedCategories[sectionIndex].videos[itemIndex] = updatedVideo
                        indexPathToUpdate = IndexPath(item: itemIndex, section: sectionIndex)
                        break
                    }
                }

                if let indexPath = indexPathToUpdate {
                    DispatchQueue.main.async {
                        self.collectionView.reloadItems(at: [indexPath])
                    }
                }

            } catch {
                print("Fetch episode error: \(error)")
            }
        }
    }
}
