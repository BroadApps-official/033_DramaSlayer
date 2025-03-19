import AVFoundation
import UIKit

final class SerialCell: UICollectionViewCell {
    static let identifier = "SerialCell"
    private var model: Video?

    private let imageView = UIImageView()
    private var episodeLabel = UILabel()
    private var titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        imageView.do { make in
            make.layer.cornerRadius = 12
            make.masksToBounds = true
        }

        episodeLabel.do { make in
            make.font = UIFont.CustomFont.caption2Regular
            make.textAlignment = .left
            make.textColor = UIColor.textSecondary
        }

        titleLabel.do { make in
            make.font = UIFont.CustomFont.footnoteSemibold
            make.textAlignment = .left
            make.textColor = .white
        }

        contentView.addSubview(imageView)
        contentView.addSubview(episodeLabel)
        contentView.addSubview(titleLabel)

        imageView.snp.makeConstraints { make in
            make.top.trailing.leading.equalToSuperview()
        }

        episodeLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(13)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(episodeLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(18)
        }
    }

    func configure(with model: Video) {
        episodeLabel.text = "EP.\(model.totalEpisodes)"
        titleLabel.text = model.title
        loadImage(from: model.cover)
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
}
