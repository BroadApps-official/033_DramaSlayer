import UIKit

protocol EpisodeSelectionDelegate: AnyObject {
    func episodeSelected(episode: Episode)
}

final class EpisodeSelectionViewController: UIViewController {
    private var video: Video
    private var episodes: [Episode]
    private var currentEpisode: Episode?
    private let backButton = UIButton()
    private let titleLabel = UILabel()
    private let purchaseManager = PurchaseManager()
    weak var delegate: EpisodeSelectionDelegate?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5.75
        layout.minimumLineSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(EpisodeCell.self, forCellWithReuseIdentifier: EpisodeCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    init(video: Video, episodes: [Episode]) {
        self.video = video
        self.episodes = episodes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.bgMain

        drawSelf()
    }

    private func drawSelf() {
        backButton.do { make in
            make.setImage(R.image.home_episode_back(), for: .normal)
            make.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        }

        titleLabel.do { make in
            make.text = video.title
            make.font = UIFont.CustomFont.title3Semibold
            make.textColor = UIColor.textMain
            make.textAlignment = .left
        }

        view.addSubviews(backButton, titleLabel, collectionView)

        backButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(14)
            make.size.equalTo(30)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    @objc func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Collection View Delegate & Data Source
extension EpisodeSelectionViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EpisodeCell.identifier, for: indexPath) as! EpisodeCell
        let episode = episodes[indexPath.item]
        cell.configure(with: episode)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 5.75
        let itemsPerRow: CGFloat = 5
        let itemWidth = (collectionView.bounds.width - (spacing * (5 - 1))) / 5
        return CGSize(width: itemWidth, height: 40)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedEpisode = episodes[indexPath.item]

        if selectedEpisode.isFree {
            currentEpisode = selectedEpisode
            dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                delegate?.episodeSelected(episode: selectedEpisode)
            }
        } else {
            if purchaseManager.hasUnlockedPro {
                currentEpisode = selectedEpisode
                dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    delegate?.episodeSelected(episode: selectedEpisode)
                }
            } else {
                let subscriptionVC = SubscriptionViewController(isFromOnboarding: false)
                subscriptionVC.modalPresentationStyle = .fullScreen
                present(subscriptionVC, animated: true, completion: nil)
            }
        }
    }
}
