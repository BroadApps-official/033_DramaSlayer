import UIKit

final class EpisodeCell: UICollectionViewCell {
    static let identifier = "EpisodeCell"
    private let episodeLabel = UILabel()
    private let premiumImageView = UIImageView()

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.contentView.alpha = self.isHighlighted ? 0.7 : 1.0
                self.contentView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        contentView.layer.cornerRadius = 8

        drawSelf()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawSelf() {
        premiumImageView.image = R.image.main_episode_cell_premium()?.withRenderingMode(.alwaysTemplate)
        premiumImageView.tintColor = UIColor.colorsSecondary
        premiumImageView.isUserInteractionEnabled = false

        episodeLabel.do { make in
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.subheadlineSemibold
            make.textAlignment = .center
            make.isUserInteractionEnabled = false
        }

        contentView.addSubviews(episodeLabel, premiumImageView)
        episodeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        premiumImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(13)
            make.width.equalTo(16)
        }
    }

    func configure(with episode: Episode) {
        if episode.isFree {
            episodeLabel.isHidden = false
            premiumImageView.isHidden = true
        } else {
            episodeLabel.isHidden = true
            premiumImageView.isHidden = false
        }
        episodeLabel.text = "\(episode.episode)"
    }
}
