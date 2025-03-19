import UIKit

final class MainButton: UIControl {
    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet {
            configureAppearance()
        }
    }

    private let titleLabel = UILabel()
    let buttonContainer = UIView()

    private let stackView = UIStackView()
    private let arrowImageView = UIImageView()
    private let addImageView = UIImageView()
    private let playImageView = UIImageView()

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
        arrowImageView.image = R.image.dis_arrow_icon()
        addImageView.image = R.image.list_add_icon()
        playImageView.image = R.image.home_play_button()

        buttonContainer.do { make in
            make.backgroundColor = UIColor.colorsSecondary
            make.layer.cornerRadius = 14
            make.isUserInteractionEnabled = false
        }

        titleLabel.do { make in
            make.text = L.continue()
            make.textColor = UIColor.text
            make.font = UIFont.CustomFont.bodySemibold
            make.isUserInteractionEnabled = false
        }

        stackView.do { make in
            make.axis = .horizontal
            make.alignment = .center
            make.spacing = 8
            make.distribution = .fillProportionally
            make.isUserInteractionEnabled = false
        }

        buttonContainer.addSubview(titleLabel)
        addSubviews(buttonContainer)

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        buttonContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configureAppearance() {
        alpha = isHighlighted ? 0.7 : 1
    }

    func setTitle(to title: String) {
        titleLabel.text = title
    }

    func setTextColor(_ color: UIColor) {
        titleLabel.textColor = color
    }

    func setBackgroundColor(_ color: UIColor) {
        buttonContainer.backgroundColor = color
    }

    func continueMode() {
        titleLabel.removeFromSuperview()
        titleLabel.do { make in
            make.text = L.continueWatching()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.subheadlineRegular
            make.isUserInteractionEnabled = false
        }

        stackView.addArrangedSubviews([titleLabel, arrowImageView])
        addSubviews(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func addMode() {
        titleLabel.removeFromSuperview()
        titleLabel.do { make in
            make.text = L.addSeries()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.bodyRegular
            make.isUserInteractionEnabled = false
        }

        stackView.addArrangedSubviews([titleLabel, addImageView])
        addSubviews(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func homePlay() {
        titleLabel.removeFromSuperview()
        titleLabel.do { make in
            make.text = L.watching()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.bodyRegular
            make.isUserInteractionEnabled = false
        }

        stackView.addArrangedSubviews([playImageView, titleLabel])
        addSubviews(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
