import SnapKit
import UIKit

final class DiscoverViewController: UIViewController {
    private var videosDictionary: [Int: Video] = [:]
    private var firstEpisodes: [Episode] = []
    private var selectedEpisode: Episode?
    private let selectButton = MainButton()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()

        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: view.frame.width, height: view.frame.height)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(DiscoverCell.self, forCellWithReuseIdentifier: DiscoverCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
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

        drawself()

        Task {
            await fetchFirstEpisodes()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = .portrait
        }

        Task {
            await checkForUpdatedVideos()
        }

        for indexPath in collectionView.indexPathsForVisibleItems {
            if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverCell {
                if !cell.isVideoPlaying {
                    cell.startPlayingVideo()
                }
            }
        }
    }

    private func fetchFirstEpisodes() async {
        do {
            let videoData = try await NetworkService.shared.fetchVideos()
            let videos = videoData.videos

            for video in videos {
                videosDictionary[video.id] = video
            }

            var newEpisodes: [Episode] = []

            for (index, video) in videos.enumerated() {
                if firstEpisodes.contains(where: { $0.videoId == video.id }) {
                    continue
                }

                do {
                    let episodes = try await NetworkService.shared.fetchVideoEpisodes(videoId: video.id)

                    if let firstEpisode = episodes.first {
                        newEpisodes.append(firstEpisode)
                        DispatchQueue.main.async {
                            self.firstEpisodes.append(firstEpisode)
                            let indexPath = IndexPath(row: self.firstEpisodes.count - 1, section: 0)
                            self.collectionView.insertItems(at: [indexPath])
                            self.updateActivityIndicatorVisibility()

                            if self.firstEpisodes.count == 1, let videoTitle = self.videosDictionary[firstEpisode.videoId]?.title {
                                self.navigationItem.title = videoTitle
                            }
                        }
                    }
                } catch {
                    print("Load episodes error \(video.id): \(error)")
                    updateActivityIndicatorVisibility()
                }
            }
        } catch {
            print("Getting video error: \(error)")
            updateActivityIndicatorVisibility()
        }
    }

    private func checkForUpdatedVideos() async {
        do {
            let videoData = try await NetworkService.shared.fetchVideos()
            let videos = videoData.videos

            for video in videos {
                if let existingVideo = videosDictionary[video.id] {
                    if existingVideo.isFavourite != video.isFavourite {
                        videosDictionary[video.id]?.isFavourite = video.isFavourite

                        if let index = firstEpisodes.firstIndex(where: { $0.videoId == video.id }) {
                            let indexPath = IndexPath(row: index, section: 0)
                            if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverCell {
                                cell.updateFavouriteStatus(isFavourite: video.isFavourite)
                            }
                        }
                    }
                } else {
                    videosDictionary[video.id] = video
                }
            }
        } catch {
            print("Update video error: \(error)")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topSafeArea = view.safeAreaInsets.top
        collectionView.contentInset = UIEdgeInsets(top: -topSafeArea, left: 0, bottom: 0, right: 0)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for indexPath in collectionView.indexPathsForVisibleItems {
            if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverCell {
                cell.resetVideo()
            }
        }
    }

    private func drawself() {
        activityIndicator.color = UIColor.colorsSecondary
        updateActivityIndicatorVisibility()

        selectButton.do { make in
            make.continueMode()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSelectButton))
            make.addGestureRecognizer(tapGesture)
        }

        view.addSubviews(collectionView, selectButton, activityIndicator)

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        selectButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-39)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(34)
            make.width.equalTo(171)
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func updateActivityIndicatorVisibility() {
        if firstEpisodes.isEmpty {
            activityIndicator.startAnimating()
            navigationController?.navigationBar.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            navigationController?.navigationBar.isHidden = false
        }
    }
    
    @objc private func didTapSelectButton() {
        guard let selectedEpisode = selectedEpisode,
              let selectedVideo = videosDictionary[selectedEpisode.videoId] else {
            print("No selected Video")
            return
        }

        for index in 0..<firstEpisodes.count {
            let indexPath = IndexPath(item: index, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverCell {
                cell.resetVideo()
            } else {
                let episode = firstEpisodes[index]
                if let videoUrl = episode.videoUrl,
                   let player = DiscoverCell.cachedPlayers[videoUrl] {
                    player.pause()
                    player.seek(to: .zero)
                }
            }
        }

        let playerVC = PlayerViewController(video: selectedVideo)
        playerVC.delegate = self
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension DiscoverViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverCell.identifier, for: indexPath) as? DiscoverCell else {
            return UICollectionViewCell()
        }
        let episode = firstEpisodes[indexPath.item]
        let video = videosDictionary[episode.videoId]
        cell.delegate = self
        cell.configure(with: episode, video: video)
        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return firstEpisodes.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleCells = collectionView.indexPathsForVisibleItems
            .sorted { top, bottom -> Bool in
                top.section < bottom.section || top.row < bottom.row
            }

        for indexPath in visibleCells {
            guard let cell = collectionView.cellForItem(at: indexPath) as? DiscoverCell else { continue }
            let cellRect = collectionView.layoutAttributesForItem(at: indexPath)?.frame
            let isCompletelyVisible = collectionView.bounds.contains(cellRect ?? CGRect.zero)

            if isCompletelyVisible {
                let episode = firstEpisodes[indexPath.item]
                selectedEpisode = episode

                if let video = videosDictionary[episode.videoId] {
                    navigationItem.title = video.title
                } else {
                    navigationItem.title = "Show"
                }

                if !cell.isPlaying {
                    for visibleIndexPath in visibleCells where visibleIndexPath != indexPath {
                        if let previousCell = collectionView.cellForItem(at: visibleIndexPath) as? DiscoverCell {
                            previousCell.resetVideo()
                        }
                    }
                    cell.startPlayingVideo()
                }
            } else {
                if collectionView.bounds.intersects(cellRect ?? CGRect.zero) == false {
                    cell.resetVideo()
                }
            }
        }
    }
}

// MARK: - PlayerDelegate
extension DiscoverViewController: PlayerDelegate {
    func updateVideoModel(videoId: Int) {
        let visibleCells = collectionView.indexPathsForVisibleItems
            .sorted { top, bottom -> Bool in
                top.section < bottom.section || top.row < bottom.row
            }

        for indexPath in visibleCells {
            if let cell = collectionView.cellForItem(at: indexPath) as? DiscoverCell {
                let episode = firstEpisodes[indexPath.item]

                if episode.videoId == videoId {
                    cell.startPlayingVideo()
                }
            }
        }
    }
}

// MARK: - DiscoverCellDelegate
extension DiscoverViewController: DiscoverCellDelegate {
    func shareVideo(url: String, from button: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.overrideUserInterfaceStyle = .dark

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }

        present(activityViewController, animated: true)
    }
}
