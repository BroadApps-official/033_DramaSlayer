import UIKit

final class EpisodeView: UIControl {
    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet {
            configureAppearance()
        }
    }

    private let titleLabel = UILabel()
    private let arrowImageView = UIImageView()
    let buttonContainer = UIView()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        drawSelf()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func drawSelf() {
        arrowImageView.image = R.image.home_episode_arrow()
        blurEffectView.do { make in
            make.layer.cornerRadius = 10
            make.layer.masksToBounds = true
            make.isUserInteractionEnabled = false
        }
    
        buttonContainer.do { make in
            make.backgroundColor = .clear
            make.layer.cornerRadius = 10
            make.isUserInteractionEnabled = false
        }

        titleLabel.do { make in
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.subheadlineRegular
            make.isUserInteractionEnabled = false
        }

        addSubview(blurEffectView)
        buttonContainer.addSubviews(titleLabel, arrowImageView)
        addSubviews(buttonContainer)
        
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        buttonContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(15.5)
            make.top.bottom.equalToSuperview().inset(13)
            make.height.equalTo(8)
            make.width.equalTo(15)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-8)
            make.top.bottom.equalToSuperview().inset(7)
        }
    }
    
    func configure(currentEpisode: Int, totalEpisode: Int) {
        titleLabel.text = "EP.\(currentEpisode) / EP.\(totalEpisode)"
    }

    private func configureAppearance() {
        alpha = isHighlighted ? 0.7 : 1
    }
}
