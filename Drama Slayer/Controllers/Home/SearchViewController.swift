import UIKit

final class SearchViewController: UIViewController {
    private let videos: [Video]
    private var selectedVideo: Video?
    private var filteredVideos: [Video] = []
    private let flameImageView = UIImageView()
    private let topLabel = UILabel()
    private let noSearchView = NoSearchView()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 24

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(SearchCell.self, forCellWithReuseIdentifier: SearchCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private lazy var actionProgress: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.hidesWhenStopped = true
        return spinner
    }()

    init(models: [Video]) {
        videos = models
        filteredVideos = models
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

        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = L.search()
        searchBar.barTintColor = UIColor(hex: "#7676803D").withAlphaComponent(0.24)

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white

            let placeholderColor = UIColor(hex: "#EBEBF599").withAlphaComponent(0.6)
            textField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [.foregroundColor: placeholderColor])

            textField.tintColor = UIColor.colorsSecondary

            if let leftView = textField.leftView as? UIImageView {
                leftView.tintColor = UIColor(hex: "#EBEBF599").withAlphaComponent(0.6)
            }
            textField.keyboardAppearance = .dark

            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
            toolbar.setItems([doneButton], animated: false)

            textField.inputAccessoryView = toolbar
            textField.delegate = self
        }

        navigationItem.titleView = searchBar

        let backBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backBarButtonItem

        drawSelf()
        updateNoSearchViewVisibility()

        collectionView.reloadData()
        collectionView.delegate = self
        collectionView.dataSource = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
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

    @objc private func dismissKeyboard() {
        if let searchBar = navigationItem.titleView as? UISearchBar {
            searchBar.resignFirstResponder()
        }
    }

    private func drawSelf() {
        flameImageView.image = R.image.home_flame_icon()
        noSearchView.isHidden = true

        topLabel.do { make in
            make.text = L.topLabel()
            make.font = UIFont.CustomFont.bodySemibold
            make.textColor = UIColor.colorsSecondary
            make.textAlignment = .left
        }

        view.addSubviews(flameImageView, topLabel, collectionView, actionProgress, noSearchView)

        flameImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(22)
            make.width.equalTo(17)
        }

        topLabel.snp.makeConstraints { make in
            make.centerY.equalTo(flameImageView.snp.centerY)
            make.leading.equalTo(flameImageView.snp.trailing).offset(6)
            make.trailing.equalToSuperview().inset(16)
        }

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(flameImageView.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }

        actionProgress.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        noSearchView.snp.makeConstraints { make in
            make.top.equalTo(flameImageView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
    }

    private func updateNoSearchViewVisibility() {
        noSearchView.isHidden = !filteredVideos.isEmpty
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredVideos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchCell.identifier, for: indexPath) as? SearchCell else {
            return UICollectionViewCell()
        }
        let video = filteredVideos[indexPath.item]
        cell.configure(with: video, index: indexPath.row)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismissKeyboard()

        let selectedVideo = filteredVideos[indexPath.item]
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
        let width = (collectionView.frame.width)
        return CGSize(width: width, height: 85)
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredVideos = videos
        } else {
            filteredVideos = videos.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
        collectionView.reloadData()
        updateNoSearchViewVisibility()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filteredVideos = videos
        collectionView.reloadData()
        updateNoSearchViewVisibility()
    }
}

// MARK: - UITextFieldDelegate
extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
