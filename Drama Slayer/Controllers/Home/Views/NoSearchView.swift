import SnapKit
import UIKit

final class NoSearchView: UIControl {
    private let image = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        drawSelf()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func drawSelf() {
        backgroundColor = .clear
        image.image = R.image.home_no_search_icon()

        titleLabel.do { make in
            make.text = L.noRelated()
            make.font = UIFont.CustomFont.bodyRegular
            make.textAlignment = .center
            make.textColor = UIColor.textTertiary
            make.numberOfLines = 0
        }
        
        addSubviews(image, titleLabel)
    }

    private func setupConstraints() {
        image.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(107)
            make.width.equalTo(143)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(image.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(22)
        }
    }
}
