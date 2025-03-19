import AVFoundation
import UIKit

final class SearchCell: UICollectionViewCell {
    static let identifier = "SearchCell"
    private var model: Video?

    private let imageView = UIImageView()
    private var titleLabel = UILabel()
    private var countLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        countLabel.do { make in
            make.font = UIFont.CustomFont.title3Semibold
            make.textAlignment = .left
            make.textColor = UIColor.textMain
        }

        imageView.do { make in
            make.layer.cornerRadius = 12
            make.masksToBounds = true
        }

        titleLabel.do { make in
            make.font = UIFont.CustomFont.footnoteSemibold
            make.textAlignment = .left
            make.textColor = .white
        }

        contentView.addSubview(countLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        countLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(26)
            make.width.equalTo(68)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(1)
            make.leading.equalTo(imageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(4)
            make.height.equalTo(18)
        }
    }

    func configure(with model: Video, index: Int) {
        countLabel.text = "\(index + 1)"
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
