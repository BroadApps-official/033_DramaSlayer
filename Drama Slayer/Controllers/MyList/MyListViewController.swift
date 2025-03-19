import SnapKit
import UIKit

final class MyListViewController: UIViewController {
    private let purchaseManager = PurchaseManager()

    private var videos: [Video] = []
    private var selectedVideo: Video?
    private let noTvSeriesView = NoTvSeriesView()
    private let listSelectorView = ListSelectorView()
    private var selectedIndex: Int = 0

    private var isSelecting = false
    private var selectedIndexes: Set<IndexPath> = []
    private var selectedModels: [Video] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 32

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ListCell.self, forCellWithReuseIdentifier: ListCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsMultipleSelection = true
        return collectionView
    }()

    init() {
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
        navigationItem.title = L.myList()
        setupRightBarButtonFirst()

        drawSelf()

        collectionView.reloadData()
        collectionView.delegate = self
        collectionView.dataSource = self

        listSelectorView.delegate = self
        noTvSeriesView.delegate = self

        fetchData()
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

                if selectedIndex == 0 {
                    let updatedFavourites = updatedVideos.filter { $0.isFavourite }
                    updateCollectionView(with: updatedFavourites)
                } else if selectedIndex == 1 {
                    if let savedVideoIds = UserDefaults.standard.array(forKey: "savedVideoIds") as? [Int], !savedVideoIds.isEmpty {
                        let updatedSavedVideos = updatedVideos.filter { savedVideoIds.contains($0.id) }
                        updateCollectionView(with: updatedSavedVideos)
                    } else {
                        updateCollectionView(with: [])
                    }
                }
            } catch {
                print("Error fetchVideos: \(error)")
            }
        }
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }

    private func setupRightBarButtonFirst() {
        let deleteButtonImage = R.image.list_delete_icon()?.withRenderingMode(.alwaysOriginal)
        let deleteButton = UIBarButtonItem(image: deleteButtonImage, style: .plain, target: self, action: #selector(selectTapped))
        navigationItem.rightBarButtonItem = deleteButton
    }

    private func setupRightBarButtonSecond() {
        let deleteButton = UIBarButtonItem(title: L.delete(), style: .plain, target: self, action: #selector(deleteButtonTapped))
        deleteButton.tintColor = UIColor.colorsSecondary
        navigationItem.rightBarButtonItem = deleteButton

        updateDeleteButtonState(deleteButton)
    }

    @objc private func selectTapped() {
        isSelecting.toggle()
        listSelectorView.isUserInteractionEnabled = false

        if isSelecting {
            navigationItem.title = L.select()
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
            cancelButton.tintColor = .white
            navigationItem.leftBarButtonItem = cancelButton

            setupRightBarButtonSecond()
            collectionView.allowsMultipleSelection = isSelecting
        }
        collectionView.reloadData()
    }

    @objc private func cancelButtonTapped() {
        isSelecting = false
        listSelectorView.isUserInteractionEnabled = true
        navigationItem.title = L.myList()
        selectedModels.removeAll()

        for index in 0..<videos.count {
            videos[index].isSelected = false
        }

        setupRightBarButtonFirst()
        navigationItem.leftBarButtonItem = nil

        collectionView.allowsMultipleSelection = isSelecting
        collectionView.reloadData()
    }

    @objc func deleteButtonTapped() {
        let alertController = UIAlertController(
            title: L.deleteTV(),
            message: L.deleteTVSublabel(),
            preferredStyle: .actionSheet
        )

        let cancelAction = UIAlertAction(title: L.cancel(), style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)

        let deleteAction = UIAlertAction(title: L.delete(), style: .destructive) { _ in
            self.deleteSelectedShows()
        }
        alertController.addAction(deleteAction)
        alertController.overrideUserInterfaceStyle = .dark

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            popoverController.permittedArrowDirections = []
        }
        present(alertController, animated: true, completion: nil)
    }

    private func deleteSelectedShows() {
        for selectedVideo in selectedModels {
            if selectedIndex == 0 {
                Task {
                    do {
                        try await NetworkService.shared.addToFavourites(videoId: selectedVideo.id)

                        if let videoIndex = videos.firstIndex(where: { $0.id == selectedVideo.id }) {
                            videos.remove(at: videoIndex)
                            collectionView.deleteItems(at: [IndexPath(item: videoIndex, section: 0)])
                        } else {
                            print("Video with ID \(selectedVideo.id) not found.")
                        }
                    } catch {
                        print("Adding to favorites error: \(error)")
                    }
                }
            } else if selectedIndex == 1 {
                if var savedVideoIds = UserDefaults.standard.array(forKey: "savedVideoIds") as? [Int] {
                    if let savedIndex = savedVideoIds.firstIndex(of: selectedVideo.id) {
                        savedVideoIds.remove(at: savedIndex)
                        UserDefaults.standard.set(savedVideoIds, forKey: "savedVideoIds")

                        if let videoIndex = videos.firstIndex(where: { $0.id == selectedVideo.id }) {
                            videos.remove(at: videoIndex)
                            collectionView.deleteItems(at: [IndexPath(item: videoIndex, section: 0)])
                        } else {
                            print("Video with ID \(selectedVideo.id) not found.")
                        }
                    } else {
                        print("Video with ID \(selectedVideo.id) not found.")
                    }
                } else {
                    print("Getting saving ID error.")
                }
            }
        }

        cancelButtonTapped()
    }

    private func drawSelf() {
        view.addSubviews(listSelectorView, collectionView, noTvSeriesView)

        listSelectorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(54)
        }

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(listSelectorView.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }

        noTvSeriesView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(112)
            make.centerX.equalToSuperview()
            make.height.equalTo(180)
            make.width.equalTo(226)
        }
    }

    private func updateCollectionView(with updatedVideos: [Video]) {
        let oldVideos = videos
        videos = updatedVideos

        var indexPathsToDelete: [IndexPath] = []
        var indexPathsToInsert: [IndexPath] = []
        var indexPathsToReload: [IndexPath] = []

        let oldVideosSet = Set(oldVideos.map { $0.id })
        let newVideosSet = Set(updatedVideos.map { $0.id })

        for (index, video) in oldVideos.enumerated() where !newVideosSet.contains(video.id) {
            indexPathsToDelete.append(IndexPath(item: index, section: 0))
        }

        for (index, video) in updatedVideos.enumerated() where !oldVideosSet.contains(video.id) {
            indexPathsToInsert.append(IndexPath(item: index, section: 0))
        }

        for (index, video) in updatedVideos.enumerated() where oldVideosSet.contains(video.id) {
            if let oldIndex = oldVideos.firstIndex(where: { $0.id == video.id }), oldVideos[oldIndex].id != video.id {
                indexPathsToReload.append(IndexPath(item: index, section: 0))
            }
        }

        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: indexPathsToDelete)
            collectionView.insertItems(at: indexPathsToInsert)
            collectionView.reloadItems(at: indexPathsToReload)
        }, completion: nil)

        updateViewForEmptyState()
    }

    private func updateVideosBasedOnSelectedIndex() {
        if selectedIndex == 0 {
            let updatedVideos = videos.filter { $0.isFavourite }
            videos = updatedVideos
        } else if selectedIndex == 1 {
            if let savedVideoIds = UserDefaults.standard.array(forKey: "savedVideoIds") as? [Int], !savedVideoIds.isEmpty {
                let updatedVideos = videos.filter { savedVideoIds.contains($0.id) }
                videos = updatedVideos
            } else {
                videos = []
            }
        }

        updateViewForEmptyState()
        collectionView.reloadData()
    }

    private func updateViewForEmptyState() {
        if videos.isEmpty {
            navigationItem.rightBarButtonItem = nil
            noTvSeriesView.isHidden = false
            collectionView.isHidden = true
        } else {
            setupRightBarButtonFirst()
            noTvSeriesView.isHidden = true
            collectionView.isHidden = false
        }
    }

    private func updateDeleteButtonState(_ deleteButton: UIBarButtonItem) {
        if selectedModels.isEmpty {
            deleteButton.isEnabled = false
            deleteButton.customView?.alpha = 0.5
        } else {
            deleteButton.isEnabled = true
            deleteButton.customView?.alpha = 1.0
        }
    }

    private func fetchData() {
        Task {
            do {
                let videoData = try await NetworkService.shared.fetchVideos()
                videos = videoData.videos
                updateVideosBasedOnSelectedIndex()
            } catch {
                print("Error fetchVideos: \(error)")
            }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension MyListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ListCell.identifier, for: indexPath) as? ListCell else {
            return UICollectionViewCell()
        }
        let video = videos[indexPath.item]

        cell.configure(with: video)
        cell.updateSelectionIndicator(isSelecting: isSelecting)
        cell.select(isSelected: video.isSelected ?? false)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard isSelecting else { return }
        var selectedVideo = videos[indexPath.item]

        if selectedVideo.isSelected == true {
            selectedVideo.isSelected = false
            if let index = videos.firstIndex(where: { $0.id == selectedVideo.id }) {
                videos[index].isSelected = false
            }

            if let cell = collectionView.cellForItem(at: indexPath) as? ListCell {
                cell.select(isSelected: false)
            }

            collectionView.reloadItems(at: [indexPath])
        } else {
            selectedVideo.isSelected = true
            if let index = videos.firstIndex(where: { $0.id == selectedVideo.id }) {
                videos[index].isSelected = true
            }

            if let cell = collectionView.cellForItem(at: indexPath) as? ListCell {
                cell.select(isSelected: true) // Выбираем
            }

            collectionView.reloadItems(at: [indexPath])
        }

        selectedModels = videos.filter { $0.isSelected == true }
        if let deleteButton = navigationItem.rightBarButtonItem {
            updateDeleteButtonState(deleteButton)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width / 2) - 8
        return CGSize(width: width, height: 287)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isSelecting {
            selectedIndexes.remove(indexPath)
        }
    }
}

// MARK: - SelectorDelegate
extension MyListViewController: ListSelectorDelegate {
    func didSelect(at index: Int) {
        selectedIndex = index
        fetchData()
    }
}

// MARK: - NoTvSeriesViewDelegate
extension MyListViewController: NoTvSeriesViewDelegate {
    func addButtonTapped() {
        tabBarController?.selectedIndex = 0
    }
}
